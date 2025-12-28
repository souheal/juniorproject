"""
AI Event Recommendation System - Inference Module

This module provides a clean interface for generating event recommendations
in production environments.

Usage:
    from recommender import EventRecommender

    recommender = EventRecommender(model_dir='models/')
    recommendations = recommender.recommend(user_id=123, top_k=10)
"""

import pandas as pd
import numpy as np
import joblib
import json
from datetime import datetime
from pathlib import Path
from sklearn.metrics.pairwise import cosine_similarity
from typing import List, Dict, Optional, Union


class EventRecommender:
    """
    Event recommendation engine for production inference.

    Supports:
    - Content-based filtering (primary)
    - Collaborative filtering (optional)
    - Hybrid scoring
    - Cold start handling
    """

    def __init__(self, model_dir: str = 'models'):
        """
        Load trained models and artifacts.

        Args:
            model_dir: Directory containing saved models
        """
        self.model_dir = Path(model_dir)

        # Load metadata
        with open(self.model_dir / 'metadata.json', 'r') as f:
            self.metadata = json.load(f)

        self.feature_cols = self.metadata['feature_columns']

        # Load models and data
        self.scaler = joblib.load(self.model_dir / 'scaler.joblib')
        self.events_df = pd.read_csv(self.model_dir / 'event_matrix.csv')
        self.user_profiles = pd.read_csv(self.model_dir / 'user_profiles.csv')
        self.global_profile = np.load(self.model_dir / 'global_profile.npy')

        # Parse event timestamps
        self.events_df['start_time'] = pd.to_datetime(self.events_df['start_time'])

        # Try loading CF model
        cf_model_path = self.model_dir / 'cf_model.joblib'
        if cf_model_path.exists():
            cf_data = joblib.load(cf_model_path)
            self.cf_model = cf_data['model']
            self.user_id_map = cf_data['user_id_map']
            self.event_id_map = cf_data['event_id_map']
            self.idx_to_user = cf_data['idx_to_user']
            self.idx_to_event = cf_data['idx_to_event']
        else:
            self.cf_model = None

        print(f"✓ EventRecommender initialized")
        print(f"  • Events: {len(self.events_df):,}")
        print(f"  • Users: {len(self.user_profiles):,}")
        print(f"  • Features: {len(self.feature_cols)}")
        print(f"  • CF available: {self.cf_model is not None}")

    def _get_user_profile(self, user_id: int) -> np.ndarray:
        """Get user preference vector."""
        user_data = self.user_profiles[self.user_profiles['user_id'] == user_id]

        if len(user_data) > 0:
            return user_data[self.feature_cols].values[0]
        else:
            # Cold start: use global average
            return self.global_profile

    def _content_based_scores(
        self,
        user_vector: np.ndarray,
        candidate_events: pd.DataFrame
    ) -> np.ndarray:
        """Compute content-based similarity scores."""
        event_matrix = candidate_events[self.feature_cols].values
        similarities = cosine_similarity([user_vector], event_matrix)[0]
        return similarities

    def _collaborative_scores(
        self,
        user_id: int,
        candidate_event_ids: List[int]
    ) -> Optional[np.ndarray]:
        """Compute collaborative filtering scores."""
        if self.cf_model is None or user_id not in self.user_id_map:
            return None

        user_idx = self.user_id_map[user_id]

        # Get event indices
        event_indices = []
        for eid in candidate_event_ids:
            if eid in self.event_id_map:
                event_indices.append(self.event_id_map[eid])

        if not event_indices:
            return None

        scores = self.cf_model.predict(user_idx, np.array(event_indices))
        return scores

    def recommend(
        self,
        user_id: Optional[int] = None,
        interest_vector: Optional[List[float]] = None,
        top_k: int = 10,
        upcoming_only: bool = True,
        current_time: Optional[datetime] = None,
        exclude_event_ids: Optional[List[int]] = None,
        content_weight: float = 0.7,
        cf_weight: float = 0.3
    ) -> List[Dict]:
        """
        Generate event recommendations.

        Args:
            user_id: User ID (if None, uses interest_vector or global profile)
            interest_vector: Custom interest vector (if user_id is None)
            top_k: Number of recommendations to return
            upcoming_only: Only recommend future events
            current_time: Reference time for "upcoming" filter
            exclude_event_ids: Event IDs to exclude from recommendations
            content_weight: Weight for content-based score (0-1)
            cf_weight: Weight for collaborative filtering score (0-1)

        Returns:
            List of recommendation dicts with keys:
                - event_id: int
                - start_time: str (ISO format)
                - score: float
        """
        # Determine user vector
        if user_id is not None:
            user_vector = self._get_user_profile(user_id)
        elif interest_vector is not None:
            user_vector = np.array(interest_vector)
        else:
            user_vector = self.global_profile

        # Filter candidate events
        candidates = self.events_df.copy()

        # Filter upcoming events
        if upcoming_only:
            if current_time is None:
                current_time = datetime.now()
            candidates = candidates[candidates['start_time'] > current_time]

        # Exclude specific events
        if exclude_event_ids:
            candidates = candidates[~candidates['event_id'].isin(exclude_event_ids)]

        if len(candidates) == 0:
            return []

        # Compute content-based scores
        content_scores = self._content_based_scores(user_vector, candidates)

        # Normalize scores
        content_scores_norm = (content_scores - content_scores.min()) / (
            content_scores.max() - content_scores.min() + 1e-8
        )

        # Add to dataframe
        candidates = candidates.copy()
        candidates['content_score'] = content_scores_norm

        # Try collaborative filtering
        if self.cf_model is not None and user_id is not None:
            cf_scores = self._collaborative_scores(
                user_id,
                candidates['event_id'].tolist()
            )

            if cf_scores is not None:
                # Normalize CF scores
                cf_scores_norm = (cf_scores - cf_scores.min()) / (
                    cf_scores.max() - cf_scores.min() + 1e-8
                )
                candidates['cf_score'] = cf_scores_norm

                # Hybrid score
                candidates['final_score'] = (
                    content_weight * candidates['content_score'] +
                    cf_weight * candidates['cf_score']
                )
            else:
                candidates['final_score'] = candidates['content_score']
        else:
            candidates['final_score'] = candidates['content_score']

        # Sort and get top-K
        candidates = candidates.sort_values('final_score', ascending=False).head(top_k)

        # Format results
        results = []
        for _, row in candidates.iterrows():
            results.append({
                'event_id': int(row['event_id']),
                'start_time': row['start_time'].isoformat(),
                'score': float(row['final_score'])
            })

        return results

    def recommend_similar_events(
        self,
        event_id: int,
        top_k: int = 10,
        upcoming_only: bool = True,
        current_time: Optional[datetime] = None
    ) -> List[Dict]:
        """
        Recommend events similar to a given event.

        Args:
            event_id: Reference event ID
            top_k: Number of recommendations
            upcoming_only: Only recommend future events
            current_time: Reference time for filtering

        Returns:
            List of similar event recommendations
        """
        # Get event vector
        event_data = self.events_df[self.events_df['event_id'] == event_id]

        if len(event_data) == 0:
            return []

        event_vector = event_data[self.feature_cols].values[0]

        # Use event vector as "interest"
        return self.recommend(
            user_id=None,
            interest_vector=event_vector.tolist(),
            top_k=top_k,
            upcoming_only=upcoming_only,
            current_time=current_time,
            exclude_event_ids=[event_id]
        )

    def update_user_profile(
        self,
        user_id: int,
        event_ids: List[int],
        save: bool = True
    ):
        """
        Update or create user profile based on new interactions.

        Args:
            user_id: User ID
            event_ids: List of event IDs user interacted with
            save: Whether to save updated profiles to disk
        """
        # Get event features
        events = self.events_df[self.events_df['event_id'].isin(event_ids)]

        if len(events) == 0:
            return

        # Compute mean profile
        new_profile = events[self.feature_cols].mean().values

        # Update or add user profile
        if user_id in self.user_profiles['user_id'].values:
            # Update existing profile
            self.user_profiles.loc[
                self.user_profiles['user_id'] == user_id,
                self.feature_cols
            ] = new_profile
        else:
            # Add new user
            new_row = pd.DataFrame({
                'user_id': [user_id],
                **{col: [val] for col, val in zip(self.feature_cols, new_profile)}
            })
            self.user_profiles = pd.concat([self.user_profiles, new_row], ignore_index=True)

        # Save if requested
        if save:
            self.user_profiles.to_csv(self.model_dir / 'user_profiles.csv', index=False)
            print(f"✓ Updated profile for user {user_id}")

    def get_trending_events(
        self,
        top_k: int = 10,
        upcoming_only: bool = True,
        current_time: Optional[datetime] = None
    ) -> List[Dict]:
        """
        Get trending events (highest average feature values).
        Useful for cold start or homepage.

        Args:
            top_k: Number of events to return
            upcoming_only: Only future events
            current_time: Reference time

        Returns:
            List of trending event dicts
        """
        candidates = self.events_df.copy()

        # Filter upcoming
        if upcoming_only:
            if current_time is None:
                current_time = datetime.now()
            candidates = candidates[candidates['start_time'] > current_time]

        if len(candidates) == 0:
            return []

        # Compute "trending score" as L2 norm of feature vector
        feature_matrix = candidates[self.feature_cols].values
        trending_scores = np.linalg.norm(feature_matrix, axis=1)

        candidates['score'] = trending_scores
        candidates = candidates.sort_values('score', ascending=False).head(top_k)

        results = []
        for _, row in candidates.iterrows():
            results.append({
                'event_id': int(row['event_id']),
                'start_time': row['start_time'].isoformat(),
                'score': float(row['score'])
            })

        return results


# Example usage
if __name__ == '__main__':
    # Initialize recommender
    recommender = EventRecommender('models/')

    # Example 1: Recommend for existing user
    print("\n" + "=" * 60)
    print("Example 1: Recommend for existing user")
    print("=" * 60)
    user_id = recommender.user_profiles['user_id'].iloc[0]
    recs = recommender.recommend(user_id=user_id, top_k=5)

    print(f"\nTop 5 recommendations for user {user_id}:")
    for i, rec in enumerate(recs, 1):
        print(f"  {i}. Event {rec['event_id']} (score: {rec['score']:.4f})")

    # Example 2: Cold start with custom interests
    print("\n" + "=" * 60)
    print("Example 2: Cold start recommendation")
    print("=" * 60)
    custom_interest = np.zeros(len(recommender.feature_cols))
    custom_interest[:10] = 1.5  # High interest in first 10 features

    recs = recommender.recommend(interest_vector=custom_interest.tolist(), top_k=5)

    print(f"\nTop 5 recommendations for custom interest:")
    for i, rec in enumerate(recs, 1):
        print(f"  {i}. Event {rec['event_id']} (score: {rec['score']:.4f})")

    # Example 3: Trending events
    print("\n" + "=" * 60)
    print("Example 3: Trending events")
    print("=" * 60)
    trending = recommender.get_trending_events(top_k=5, upcoming_only=False)

    print(f"\nTop 5 trending events:")
    for i, event in enumerate(trending, 1):
        print(f"  {i}. Event {event['event_id']} (score: {event['score']:.4f})")
