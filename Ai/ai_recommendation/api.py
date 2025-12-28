"""
AI Event Recommendation System - FastAPI Server

RESTful API for serving event recommendations to Flutter app and other clients.

Usage:
    uvicorn api:app --host 0.0.0.0 --port 8000 --reload

Endpoints:
    GET  /                      - API info
    POST /recommend             - Get recommendations for user
    POST /recommend/similar     - Get events similar to given event
    GET  /recommend/trending    - Get trending events
    POST /user/profile/update   - Update user profile
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import uvicorn

from recommender import EventRecommender


# Initialize FastAPI app
app = FastAPI(
    title="Event Recommendation API",
    description="AI-powered event recommendation system for Eventy platform",
    version="1.0.0"
)

# Enable CORS for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify your Flutter app's origin
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize recommender (load models once at startup)
try:
    recommender = EventRecommender(model_dir='models/')
    print("✓ Recommendation engine loaded successfully")
except Exception as e:
    print(f"⚠ Failed to load recommendation engine: {e}")
    recommender = None


# Request/Response models
class RecommendRequest(BaseModel):
    user_id: Optional[int] = Field(None, description="User ID (optional)")
    interest_vector: Optional[List[float]] = Field(None, description="Custom interest vector (optional)")
    top_k: int = Field(10, ge=1, le=100, description="Number of recommendations")
    upcoming_only: bool = Field(True, description="Only recommend upcoming events")
    exclude_event_ids: Optional[List[int]] = Field(None, description="Event IDs to exclude")
    content_weight: float = Field(0.7, ge=0, le=1, description="Weight for content-based score")
    cf_weight: float = Field(0.3, ge=0, le=1, description="Weight for collaborative filtering score")


class SimilarEventsRequest(BaseModel):
    event_id: int = Field(..., description="Reference event ID")
    top_k: int = Field(10, ge=1, le=100, description="Number of recommendations")
    upcoming_only: bool = Field(True, description="Only recommend upcoming events")


class UpdateProfileRequest(BaseModel):
    user_id: int = Field(..., description="User ID")
    event_ids: List[int] = Field(..., description="Event IDs user interacted with")
    save: bool = Field(True, description="Save updated profile to disk")


class RecommendationResponse(BaseModel):
    event_id: int
    start_time: str
    score: float


class APIResponse(BaseModel):
    success: bool
    data: Optional[List[RecommendationResponse]] = None
    message: Optional[str] = None


# Endpoints
@app.get("/")
async def root():
    """API info and health check."""
    return {
        "name": "Event Recommendation API",
        "version": "1.0.0",
        "status": "online" if recommender is not None else "error",
        "model_loaded": recommender is not None,
        "endpoints": {
            "recommend": "POST /recommend",
            "similar_events": "POST /recommend/similar",
            "trending": "GET /recommend/trending",
            "update_profile": "POST /user/profile/update"
        }
    }


@app.post("/recommend", response_model=APIResponse)
async def recommend_events(request: RecommendRequest):
    """
    Get personalized event recommendations.

    - Provide user_id for existing users
    - Provide interest_vector for new users (cold start)
    - If neither provided, uses global average profile
    """
    if recommender is None:
        raise HTTPException(status_code=500, detail="Recommendation engine not available")

    try:
        recommendations = recommender.recommend(
            user_id=request.user_id,
            interest_vector=request.interest_vector,
            top_k=request.top_k,
            upcoming_only=request.upcoming_only,
            exclude_event_ids=request.exclude_event_ids,
            content_weight=request.content_weight,
            cf_weight=request.cf_weight
        )

        return APIResponse(
            success=True,
            data=[RecommendationResponse(**rec) for rec in recommendations],
            message=f"Generated {len(recommendations)} recommendations"
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/recommend/similar", response_model=APIResponse)
async def recommend_similar_events(request: SimilarEventsRequest):
    """
    Get events similar to a given event.
    Useful for "You might also like" sections.
    """
    if recommender is None:
        raise HTTPException(status_code=500, detail="Recommendation engine not available")

    try:
        recommendations = recommender.recommend_similar_events(
            event_id=request.event_id,
            top_k=request.top_k,
            upcoming_only=request.upcoming_only
        )

        if not recommendations:
            return APIResponse(
                success=False,
                data=[],
                message=f"Event {request.event_id} not found"
            )

        return APIResponse(
            success=True,
            data=[RecommendationResponse(**rec) for rec in recommendations],
            message=f"Found {len(recommendations)} similar events"
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/recommend/trending", response_model=APIResponse)
async def get_trending_events(
    top_k: int = Query(10, ge=1, le=100, description="Number of events"),
    upcoming_only: bool = Query(True, description="Only upcoming events")
):
    """
    Get trending events.
    Useful for homepage, cold start, or "Popular Now" sections.
    """
    if recommender is None:
        raise HTTPException(status_code=500, detail="Recommendation engine not available")

    try:
        trending = recommender.get_trending_events(
            top_k=top_k,
            upcoming_only=upcoming_only
        )

        return APIResponse(
            success=True,
            data=[RecommendationResponse(**event) for event in trending],
            message=f"Retrieved {len(trending)} trending events"
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/user/profile/update")
async def update_user_profile(request: UpdateProfileRequest):
    """
    Update user profile based on new interactions.
    Call this when a user attends/interacts with events.
    """
    if recommender is None:
        raise HTTPException(status_code=500, detail="Recommendation engine not available")

    try:
        recommender.update_user_profile(
            user_id=request.user_id,
            event_ids=request.event_ids,
            save=request.save
        )

        return {
            "success": True,
            "message": f"Updated profile for user {request.user_id}"
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/stats")
async def get_stats():
    """Get system statistics."""
    if recommender is None:
        raise HTTPException(status_code=500, detail="Recommendation engine not available")

    return {
        "total_events": len(recommender.events_df),
        "total_users": len(recommender.user_profiles),
        "feature_dimensions": len(recommender.feature_cols),
        "cf_available": recommender.cf_model is not None,
        "model_version": recommender.metadata.get('model_version', 'unknown'),
        "created_at": recommender.metadata.get('created_at', 'unknown')
    }


# Run server
if __name__ == "__main__":
    uvicorn.run(
        "api:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
