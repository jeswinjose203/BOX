from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import DepositRequest
from box.auth import get_current_user, get_current_admin

router = APIRouter(prefix="/deposits", tags=["Deposits"])


@router.post("/request")
def request_deposit(data: DepositRequest, user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    existing = db.query(models.Deposit).filter(models.Deposit.utr == data.utr).first()
    if existing:
        raise HTTPException(status_code=400, detail="UTR already used")

    deposit = models.Deposit(
        user_id=user_id,
        amount=data.amount,
        utr=data.utr,
        status="PENDING"
    )
    db.add(deposit)
    db.commit()
    db.refresh(deposit)
    return {"message": "Deposit request submitted", "status": "PENDING"}


@router.post("/approve/{deposit_id}")
def approve_deposit(deposit_id: int, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    deposit = db.query(models.Deposit).filter(models.Deposit.id == deposit_id).first()
    if not deposit:
        raise HTTPException(status_code=404, detail="Deposit not found")
    if deposit.status != "PENDING":
        raise HTTPException(status_code=400, detail="Already processed")

    existing_txn = db.query(models.WalletTransaction).filter(
        models.WalletTransaction.type == "deposit",
        models.WalletTransaction.reference_id == deposit.id
    ).first()
    if existing_txn:
        raise HTTPException(status_code=400, detail="Transaction already exists")

    transaction = models.WalletTransaction(
        user_id=deposit.user_id,
        amount=deposit.amount,
        type="deposit",
        reference_id=deposit.id
    )
    db.add(transaction)
    deposit.status = "APPROVED"
    db.commit()
    return {"message": "Deposit approved and wallet credited via ledger"}


@router.post("/reject/{deposit_id}")
def reject_deposit(deposit_id: int, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    deposit = db.query(models.Deposit).filter(models.Deposit.id == deposit_id).first()
    if not deposit:
        raise HTTPException(status_code=404, detail="Not found")
    if deposit.status != "PENDING":
        raise HTTPException(status_code=400, detail="Already processed")

    deposit.status = "REJECTED"
    db.commit()
    return {"message": "Deposit rejected"}


@router.get("/")
def get_deposits(admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    return db.query(models.Deposit).all()


@router.get("/mine")
def get_my_deposits(user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(models.Deposit).filter(
        models.Deposit.user_id == user_id
    ).all()
