from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from auth import auth_router
from comments import comments_router
from post import post_router
from profile import profile_router

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:5500",
        "http://localhost:5500",
        "http://localhost:50098",
        "http://127.0.0.1:50098"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(post_router)
app.include_router(comments_router)
app.include_router(profile_router)
