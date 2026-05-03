from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import PredictionCreate
from datetime import datetime, timezone
from box.auth import get_current_user

router = APIRouter(prefix="/predictions", tags=["Predictions"])


@router.post("/")
def create_prediction(prediction: PredictionCreate, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    contest = db.query(models.Contest).filter(models.Contest.id == prediction.contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")

    if contest.deadline and datetime.now(timezone.utc) > contest.deadline:
        raise HTTPException(status_code=400, detail="Prediction deadline passed")

    participant = db.query(models.Participant).filter(
        models.Participant.user_id == user_id,
        models.Participant.contest_id == prediction.contest_id
    ).first()
    if not participant:
        raise HTTPException(status_code=403, detail="User not joined this contest")

    existing = db.query(models.Prediction).filter(
        models.Prediction.user_id == user_id,
        models.Prediction.contest_id == prediction.contest_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Already predicted")

    db_prediction = models.Prediction(
        user_id=user_id,
        contest_id=prediction.contest_id,
        predicted_value=prediction.predicted_value
    )
    db.add(db_prediction)
    db.commit()
    db.refresh(db_prediction)
    return db_prediction


@router.get("/")
def get_predictions(db: Session = Depends(get_db)):
    return db.query(models.Prediction).all()


@router.get("/contest/{contest_id}")
def get_predictions_by_contest(contest_id: int, db: Session = Depends(get_db)):
    return db.query(models.Prediction).filter(
        models.Prediction.contest_id == contest_id
    ).all()
