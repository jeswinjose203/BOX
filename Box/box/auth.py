from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import SignupRequest
from jose import jwt
from datetime import datetime, timedelta
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
import logging
import bcrypt

logger = logging.getLogger(__name__)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
router = APIRouter(prefix="/auth", tags=["Auth"])

SECRET_KEY = "your_secret_key"
ALGORITHM = "HS256"

def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload["user_id"]
    except:
        raise HTTPException(status_code=401, detail="Invalid token")


def get_current_admin(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload["user_id"]
    except:
        raise HTTPException(status_code=401, detail="Invalid token")
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Admin access required")
    return user_id


def hash_password(password: str):
    # bcrypt accepts max 72 bytes; truncate bytes (not characters) to avoid runtime errors.
    password_bytes = password.encode("utf-8")[:72]
    return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain, hashed):
    try:
        plain_bytes = plain.encode("utf-8")[:72]
        return bcrypt.checkpw(plain_bytes, hashed.encode("utf-8"))
    except ValueError:
        # Invalid hash format or unsupported value -> treat as auth failure, not 500.
        return False


def create_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(hours=24)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


@router.post("/signup")
def signup(data: SignupRequest, db: Session = Depends(get_db)):
    try:
        logger.info(f"Signup request for user: {data.username}")
        existing = db.query(models.User).filter(models.User.username == data.username).first()
        if existing:
            logger.warning(f"User already exists: {data.username}")
            raise HTTPException(status_code=400, detail="User already exists")

        hashed = hash_password(data.password)
        user = models.User(
            username=data.username,
            password=hashed
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        logger.info(f"User created successfully: {data.username} (id={user.id})")
        return {"message": "User created", "user_id": user.id}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Signup error: {type(e).__name__}: {e}", exc_info=True)
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Signup failed: {str(e)}")


@router.post("/login")
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    try:
        logger.info(f"Login request for user: {form_data.username}")
        user = db.query(models.User).filter(
            models.User.username == form_data.username
        ).first()

        if not user or not verify_password(form_data.password, user.password):
            logger.warning(f"Login failed for user: {form_data.username}")
            raise HTTPException(status_code=401, detail="Invalid credentials")

        token = create_token({"user_id": user.id})
        logger.info(f"Login successful for user: {form_data.username}")
        return {"access_token": token, "token_type": "bearer"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login error: {type(e).__name__}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Login failed: {str(e)}")


@router.get("/me")
def get_me(user_id: int = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        user = db.query(models.User).filter(models.User.id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        return {"id": user.id, "username": user.username, "is_admin": user.is_admin}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"GetMe error: {type(e).__name__}: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to get user: {str(e)}")
