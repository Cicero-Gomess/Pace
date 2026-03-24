from fastapi import FastAPI

app = FastAPI()

from auth import auth_router

#app.include_router(user.router, prefix="/users", tags=["users"])
#app.include_router(post.router)
app.include_router(auth_router)

