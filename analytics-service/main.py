from fastapi import FastAPI, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List, Dict, Optional
import logging
from datetime import datetime
import uuid

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FastAPI app
app = FastAPI(title="Analytics Service")

# In-memory data store for analytics events
# For a production app, this would use a database
analytics_events = []

# Models
class AnalyticsEvent(BaseModel):
    user_id: Optional[int] = None
    event_type: str
    event_data: Dict = {}
    timestamp: Optional[datetime] = None

class AnalyticsResponse(BaseModel):
    event_id: str
    status: str
    message: str

class EventSummary(BaseModel):
    event_type: str
    count: int

# API Endpoints
@app.get("/")
def read_root():
    return {"message": "Analytics Service Running"}

@app.post("/track", response_model=AnalyticsResponse)
async def track_event(event: AnalyticsEvent):
    """
    Track a user event such as:
    - page_view
    - button_click
    - profile_creation
    - login
    - logout
    - etc.
    """
    # Generate a unique ID for the event
    event_id = str(uuid.uuid4())
    
    # Set timestamp if not provided
    if not event.timestamp:
        event.timestamp = datetime.utcnow()
        
    # Store the event
    analytics_events.append({
        "id": event_id,
        **event.dict()
    })
    
    logger.info(f"Tracked event: {event.event_type} for user {event.user_id}")
    
    return {
        "event_id": event_id,
        "status": "success",
        "message": "Event tracked successfully"
    }

@app.get("/events", response_model=List[AnalyticsEvent])
async def get_events(event_type: Optional[str] = None, limit: int = 100):
    """Get most recent analytics events, optionally filtered by event_type"""
    filtered_events = analytics_events
    
    if event_type:
        filtered_events = [e for e in analytics_events if e["event_type"] == event_type]
        
    # Return most recent events first, limited to requested amount
    return sorted(filtered_events, key=lambda x: x["timestamp"], reverse=True)[:limit]

@app.get("/summary", response_model=List[EventSummary])
async def get_summary():
    """Get a summary count of events by type"""
    event_counts = {}
    
    for event in analytics_events:
        event_type = event["event_type"]
        if event_type in event_counts:
            event_counts[event_type] += 1
        else:
            event_counts[event_type] = 1
    
    return [{"event_type": k, "count": v} for k, v in event_counts.items()]

@app.delete("/events")
async def clear_events():
    """Clear all analytics events (for demo purposes)"""
    analytics_events.clear()
    return {"message": "All events cleared"}

# Add some demo events on startup
@app.on_event("startup")
async def startup_event():
    demo_events = [
        {"user_id": 1, "event_type": "login", "event_data": {"ip": "192.168.1.1"}},
        {"user_id": 2, "event_type": "page_view", "event_data": {"page": "home"}},
        {"user_id": 1, "event_type": "profile_update", "event_data": {"fields": ["name", "bio"]}},
        {"user_id": 3, "event_type": "login", "event_data": {"ip": "192.168.1.5"}},
        {"user_id": 2, "event_type": "logout", "event_data": {}}
    ]
    
    for event in demo_events:
        await track_event(AnalyticsEvent(**event))
        
    logger.info(f"Added {len(demo_events)} demo events") 