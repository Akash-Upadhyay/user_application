from fastapi import FastAPI, Depends, HTTPException, status, Header
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from jose import JWTError, jwt
from pydantic import BaseModel
from datetime import datetime
import os
import time
import logging
import requests
from typing import Optional, List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
DATABASE_URL = os.getenv("DATABASE_URL", "mysql+pymysql://user:password@localhost:3306/microservices")
JWT_SECRET = os.getenv("JWT_SECRET", "your_jwt_secret")
AUTH_SERVICE_URL = os.getenv("AUTH_SERVICE_URL", "http://localhost:3001")
MAX_RETRIES = 10
RETRY_DELAY = 5  # seconds

# Database setup with retry logic
def get_db_connection():
    retries = 0
    while retries < MAX_RETRIES:
        try:
            logger.info(f"Attempting to connect to database (attempt {retries + 1}/{MAX_RETRIES})")
            engine = create_engine(DATABASE_URL)
            # Test the connection
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            logger.info("Database connection successful")
            return engine
        except Exception as e:
            retries += 1
            logger.error(f"Database connection failed: {str(e)}")
            if retries < MAX_RETRIES:
                logger.info(f"Retrying in {RETRY_DELAY} seconds...")
                time.sleep(RETRY_DELAY)
            else:
                logger.error("Max retries reached, unable to connect to database")
                raise

# Get database engine with retry
engine = get_db_connection()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Models
class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, unique=True, index=True)
    name = Column(String(255))
    bio = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

# Schemas
class UserProfileBase(BaseModel):
    name: str
    bio: Optional[str] = None

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileUpdate(UserProfileBase):
    pass

class UserProfileOut(UserProfileBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True

# Create tables
Base.metadata.create_all(bind=engine)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Authentication middleware
async def get_current_user(authorization: str = Header(None)):
    logger.info(f"Received authorization header: {authorization}")
    
    if not authorization or not authorization.startswith("Bearer "):
        logger.error("Missing or invalid Authorization header format")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    token = authorization.replace("Bearer ", "")
    logger.info(f"Extracted token: {token[:10]}...")
    
    try:
        # Verify token with Auth Service
        logger.info(f"Sending token verification request to {AUTH_SERVICE_URL}/verify")
        response = requests.post(f"{AUTH_SERVICE_URL}/verify", json={"token": token})
        logger.info(f"Auth service response status: {response.status_code}")
        
        if response.status_code != 200:
            logger.error(f"Auth service returned non-200 status: {response.status_code}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
            
        result = response.json()
        logger.info(f"Auth service response: {result}")
        
        if not result.get("valid", False):
            logger.error("Token validation failed")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user = result.get("user")
        logger.info(f"Authenticated user: {user}")
        return user
    except requests.RequestException as e:
        logger.error(f"Request to auth service failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Authentication service unavailable",
        )

# FastAPI app
app = FastAPI(title="User Service")

@app.get("/")
def read_root():
    return {"message": "User Service Running"}

@app.post("/profiles", response_model=UserProfileOut, status_code=status.HTTP_201_CREATED)
async def create_profile(
    profile: UserProfileCreate, 
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    logger.info(f"Creating profile for user: {current_user}")
    # Check if profile already exists
    db_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user["id"]).first()
    if db_profile:
        logger.warning(f"Profile already exists for user {current_user['id']}")
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Profile already exists for this user"
        )
    
    # Create new profile
    db_profile = UserProfile(
        user_id=current_user["id"],
        name=profile.name,
        bio=profile.bio
    )
    db.add(db_profile)
    db.commit()
    db.refresh(db_profile)
    logger.info(f"Profile created: {db_profile.id}")
    return db_profile

@app.get("/profiles/me", response_model=UserProfileOut)
async def get_own_profile(
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    logger.info(f"Getting profile for user: {current_user}")
    db_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user["id"]).first()
    if not db_profile:
        logger.warning(f"Profile not found for user {current_user['id']}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    return db_profile

@app.put("/profiles/me", response_model=UserProfileOut)
async def update_own_profile(
    profile: UserProfileUpdate,
    current_user: dict = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    logger.info(f"Updating profile for user: {current_user}")
    db_profile = db.query(UserProfile).filter(UserProfile.user_id == current_user["id"]).first()
    if not db_profile:
        logger.warning(f"Profile not found for user {current_user['id']}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    
    # Update profile
    db_profile.name = profile.name
    db_profile.bio = profile.bio
    db.commit()
    db.refresh(db_profile)
    logger.info(f"Profile updated: {db_profile.id}")
    return db_profile

@app.get("/profiles/{profile_id}", response_model=UserProfileOut)
async def get_profile_by_id(
    profile_id: int,
    db: Session = Depends(get_db)
):
    logger.info(f"Getting profile by id: {profile_id}")
    db_profile = db.query(UserProfile).filter(UserProfile.id == profile_id).first()
    if not db_profile:
        logger.warning(f"Profile {profile_id} not found")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Profile not found"
        )
    return db_profile 