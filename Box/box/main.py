from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from box.database import Base, engine
from box import movies, contests, predictions, scoring, wallet, auth, deposits, withdrawals

Base.metadata.create_all(bind=engine)
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(movies.router)
app.include_router(contests.router)
app.include_router(predictions.router)
app.include_router(scoring.router)
app.include_router(wallet.router)
app.include_router(deposits.router)
app.include_router(withdrawals.router)


@app.get("/")
def root():
    return {"message": "API is running"}
