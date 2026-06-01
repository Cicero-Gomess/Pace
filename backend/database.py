from sqlalchemy.orm import declarative_base
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

BASE_DIR = os.path.dirname(__file__)
load_dotenv(os.path.join(BASE_DIR, ".env"))

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    DATABASE_URL = f"sqlite:///{os.path.join(BASE_DIR, 'banco.db')}"

Base = declarative_base()

if DATABASE_URL.startswith("sqlite:///"):
    db = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    db = create_engine(DATABASE_URL)
 