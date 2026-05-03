from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import WithdrawalRequest
from box.auth import get_current_user, get_current_admin

router = APIRouter(prefix="/withdrawals", tags=["Withdrawals"])


@router.post("/request")
def request_withdrawal(data: WithdrawalRequest, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    transactions = db.query(models.WalletTransaction).filter(
        models.WalletTransaction.user_id == user_id
    ).all()
    balance = sum(t.amount for t in transactions)

    if data.amount <= 0:
        raise HTTPException(status_code=400, detail="Invalid amount")
    if balance < data.amount:
        raise HTTPException(status_code=400, detail="Insufficient balance")

    withdrawal = models.Withdrawal(
        user_id=user_id,
        amount=data.amount,
        upi_id=data.upi_id,
        status="PENDING"
    )
    db.add(withdrawal)
    db.commit()
    db.refresh(withdrawal)
    return {"message": "Withdrawal request submitted", "status": "PENDING"}


@router.post("/approve/{withdrawal_id}")
def approve_withdrawal(withdrawal_id: int, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    withdrawal = db.query(models.Withdrawal).filter(models.Withdrawal.id == withdrawal_id).first()
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Withdrawal not found")
    if withdrawal.status != "PENDING":
        raise HTTPException(status_code=400, detail="Already processed")

    transactions = db.query(models.WalletTransaction).filter(
        models.WalletTransaction.user_id == withdrawal.user_id
    ).all()
    balance = sum(t.amount for t in transactions)

    if balance < withdrawal.amount:
        raise HTTPException(status_code=400, detail="User has insufficient balance")

    transaction = models.WalletTransaction(
        user_id=withdrawal.user_id,
        amount=-withdrawal.amount,
        type="withdrawal",
        reference_id=withdrawal.id
    )
    db.add(transaction)
    withdrawal.status = "APPROVED"
    db.commit()
    return {"message": "Withdrawal approved and balance deducted"}


@router.post("/reject/{withdrawal_id}")
def reject_withdrawal(withdrawal_id: int, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    withdrawal = db.query(models.Withdrawal).filter(models.Withdrawal.id == withdrawal_id).first()
    if not withdrawal:
        raise HTTPException(status_code=404, detail="Not found")
    if withdrawal.status != "PENDING":
        raise HTTPException(status_code=400, detail="Already processed")

    withdrawal.status = "REJECTED"
    db.commit()
    return {"message": "Withdrawal rejected"}


@router.get("/")
def get_withdrawals(admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    return db.query(models.Withdrawal).all()


@router.get("/mine")
def get_my_withdrawals(user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(models.Withdrawal).filter(
        models.Withdrawal.user_id == user_id
    ).all()
