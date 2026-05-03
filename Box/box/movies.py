from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from box.database import get_db
from box import models
from box.schemas import MovieCreate
from box.auth import get_current_admin

router = APIRouter(prefix="/movies", tags=["Movies"])


@router.post("/")
def create_movie(movie: MovieCreate, admin: int = Depends(get_current_admin), db: Session = Depends(get_db)):
    db_movie = models.Movie(**movie.model_dump())
    db.add(db_movie)
    db.commit()
    db.refresh(db_movie)
    return db_movie


@router.get("/")
def get_movies(db: Session = Depends(get_db)):
    return db.query(models.Movie).all()
