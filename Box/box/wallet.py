from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.auth import get_current_user

router = APIRouter(prefix="/wallet", tags=["Wallet"])


@router.get("/balance")
def get_balance(user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    transactions = db.query(models.WalletTransaction).filter(
        models.WalletTransaction.user_id == user_id
    ).all()
    balance = sum(t.amount for t in transactions)
    return {"user_id": user_id, "balance": balance}
