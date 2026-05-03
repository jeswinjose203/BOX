from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class MovieCreate(BaseModel):
    title: str
    release_date: str


class ContestCreate(BaseModel):
    movie_id: int
    entry_fee: float
    type: str
    deadline: Optional[datetime] = None


class ContestJoinRequest(BaseModel):
    amount: float
    predicted_value: Optional[float] = None


class PredictionCreate(BaseModel):
    contest_id: int
    predicted_value: float


class DepositRequest(BaseModel):
    amount: float
    utr: str


class WithdrawalRequest(BaseModel):
    amount: float
    upi_id: str


class SignupRequest(BaseModel):
    username: str
    password: str


class ScoringRequest(BaseModel):
    contest_id: int
    actual_value: float


class DistributeRequest(BaseModel):
    contest_id: int
    top_n: int
