from sqlalchemy.orm import declarative_base
from sqlalchemy import create_engine
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")
if not DATABASE_URL:
    raise RuntimeError(
        "DATABASE_URL não está definido. Crie um arquivo .env com DATABASE_URL=<sua_string_de_conexão> "
        "ou exporte a variável de ambiente antes de iniciar o servidor."
    )

Base = declarative_base()

db = create_engine(DATABASE_URL) 