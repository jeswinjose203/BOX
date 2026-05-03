from fastapi import APIRouter, Depends, HTTPException, Body
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import ContestCreate, ContestJoinRequest
from datetime import datetime, timezone
from box.auth import get_current_user, get_current_admin

router = APIRouter(prefix="/contests", tags=["Contests"])


def _to_utc_naive(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt
    return dt.astimezone(timezone.utc).replace(tzinfo=None)


@router.post("/")
def create_contest(contest: ContestCreate, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    movie = db.query(models.Movie).filter(models.Movie.id == contest.movie_id).first()
    if not movie:
        raise HTTPException(status_code=404, detail="Movie not found")

    db_contest = models.Contest(**contest.model_dump())
    db.add(db_contest)
    db.commit()
    db.refresh(db_contest)
    return db_contest


@router.get("/")
def get_contests(db: Session = Depends(get_db)):
    return db.query(models.Contest).all()


@router.get("/{contest_id}")
def get_contest(contest_id: int, db: Session = Depends(get_db)):
    contest = db.query(models.Contest).filter(models.Contest.id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")
    return contest


@router.post("/{contest_id}/join")
def join_contest(
    contest_id: int,
    payload: ContestJoinRequest = Body(...),
    user_id: int = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    amount = payload.amount
    predicted_value = payload.predicted_value

    contest = db.query(models.Contest).filter(models.Contest.id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")

    if contest.deadline and _to_utc_naive(datetime.now(timezone.utc)) > _to_utc_naive(contest.deadline):
        raise HTTPException(status_code=400, detail="Contest entry closed")

    if amount < contest.entry_fee:
        raise HTTPException(status_code=400, detail=f"Minimum amount is ₹{contest.entry_fee}")

    if predicted_value is not None and predicted_value < 0:
        raise HTTPException(status_code=400, detail="Predicted value must be non-negative")

    existing = db.query(models.Participant).filter(
        models.Participant.user_id == user_id,
        models.Participant.contest_id == contest_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already joined this contest")

    if predicted_value is not None:
        existing_prediction = db.query(models.Prediction).filter(
            models.Prediction.user_id == user_id,
            models.Prediction.contest_id == contest_id
        ).first()
        if existing_prediction:
            raise HTTPException(status_code=400, detail="Prediction already submitted for this contest")

    transactions = db.query(models.WalletTransaction).filter(
        models.WalletTransaction.user_id == user_id
    ).all()
    balance = sum(t.amount for t in transactions)

    if balance < amount:
        raise HTTPException(status_code=400, detail="Insufficient balance")

    try:
        transaction = models.WalletTransaction(
            user_id=user_id,
            amount=-amount,
            type="contest_fee",
            reference_id=contest_id
        )
        db.add(transaction)

        participant = models.Participant(user_id=user_id, contest_id=contest_id, amount=amount)
        db.add(participant)

        if predicted_value is not None:
            prediction = models.Prediction(
                user_id=user_id,
                contest_id=contest_id,
                predicted_value=predicted_value
            )
            db.add(prediction)
        db.commit()
    except Exception:
        db.rollback()
        raise HTTPException(status_code=500, detail="Something went wrong")

    return {
        "message": "Joined contest and submitted prediction successfully"
        if predicted_value is not None
        else "Joined contest successfully. Submit prediction next.",
        "amount_staked": amount,
        "remaining_balance": balance - amount
    }
