from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import ScoringRequest, DistributeRequest
from box.auth import get_current_admin

router = APIRouter(prefix="/scoring", tags=["Scoring"])


def calculate_score(predicted, actual):
    error = abs(predicted - actual)
    percentage_error = (error / actual) * 100
    score = max(0, 100 - percentage_error)
    return round(score, 2)


@router.post("/run")
def run_scoring(data: ScoringRequest, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    contest = db.query(models.Contest).filter(models.Contest.id == data.contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")

    predictions = db.query(models.Prediction).filter(
        models.Prediction.contest_id == data.contest_id
    ).all()
    if not predictions:
        raise HTTPException(status_code=400, detail="No predictions found")

    db.query(models.Leaderboard).filter(
        models.Leaderboard.contest_id == data.contest_id
    ).delete()

    leaderboard = []
    for p in predictions:
        score = calculate_score(p.predicted_value, data.actual_value)
        leaderboard.append({
            "user_id": p.user_id,
            "predicted_value": p.predicted_value,
            "actual_value": data.actual_value,
            "score": score
        })

    leaderboard = sorted(leaderboard, key=lambda x: x["score"], reverse=True)

    for i, entry in enumerate(leaderboard):
        db_entry = models.Leaderboard(
            contest_id=data.contest_id,
            user_id=entry["user_id"],
            predicted_value=entry["predicted_value"],
            actual_value=data.actual_value,
            score=entry["score"],
            rank=i + 1
        )
        db.add(db_entry)

    db.commit()
    return {"message": "Leaderboard generated", "total_entries": len(leaderboard)}


@router.post("/distribute")
def distribute(data: DistributeRequest, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    contest = db.query(models.Contest).filter(models.Contest.id == data.contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")

    if contest.is_distributed:
        raise HTTPException(status_code=400, detail="Prizes already distributed")

    leaderboard = db.query(models.Leaderboard).filter(
        models.Leaderboard.contest_id == data.contest_id
    ).order_by(models.Leaderboard.rank).all()
    if not leaderboard:
        raise HTTPException(status_code=400, detail="Run scoring first")

    participants = db.query(models.Participant).filter(
        models.Participant.contest_id == data.contest_id
    ).all()

    total_pool = sum(p.amount for p in participants)
    winner_count = min(data.top_n, len(leaderboard))
    weights = list(range(winner_count, 0, -1))
    total_weight = sum(weights)

    for i in range(winner_count):
        winner = leaderboard[i]
        prize_amount = round(total_pool * weights[i] / total_weight, 2)
        transaction = models.WalletTransaction(
            user_id=winner.user_id,
            amount=prize_amount,
            type="reward",
            reference_id=data.contest_id
        )
        db.add(transaction)

    contest.is_distributed = True
    db.commit()
    return {"message": f"Prizes distributed to top {winner_count}", "total_pool": total_pool}


@router.get("/leaderboard/{contest_id}")
def get_leaderboard(contest_id: int, db: Session = Depends(get_db)):
    return db.query(models.Leaderboard).filter(
        models.Leaderboard.contest_id == contest_id
    ).order_by(models.Leaderboard.rank).all()
