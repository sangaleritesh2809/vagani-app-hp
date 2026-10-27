import os
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    PROJECT_NAME: str = "Vargani Pro API"
    API_V1_STR: str = "/api/v1"
    SUPABASE_URL: Optional[str] = ""
    SUPABASE_KEY: Optional[str] = ""
    HOST: str = "127.0.0.1"
    PORT: int = 8000
    ENVIRONMENT: str = "development"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
