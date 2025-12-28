"""
AI Event Recommendation System - Training Script

This script trains the content-based and collaborative filtering models
for event recommendations based on user interaction history.

Usage:
    python train_recommender.py --data Dataset.csv --output models/

Requirements:
    - pandas, numpy, scikit-learn, joblib, lightfm (optional)
"""

import pandas as pd
import numpy as np
import argparse
import json
import os
import warnings
from datetime import datetime
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from scipy.sparse import csr_matrix
import joblib

warnings.filterwarnings('ignore')

# Random seed for reproducibility
RANDOM_SEED = 42
np.random.seed(RANDOM_SEED)


class EventRecommendationTrainer:
    """
    Trains event recommendation models using content-based filtering
    and optional collaborative filtering.
    """

    def __init__(self, data_path, output_dir='models'):
        """
        Initialize trainer.

        Args:
            data_path: Path to Dataset.csv
            output_dir: Directory to save trained models
        """
        self.data_path = data_path
        self.output_dir = output_dir
        self.df = None
        self.events_df = None
        self.user_profiles = None
        self.global_profile = None
        self.scaler = None
        self.feature_cols = []

        # Collaborative filtering components
        self.cf_model = None
        self.user_id_map = None
        self.event_id_map = None
        self.idx_to_user = None
        self.idx_to_event = None

        os.makedirs(output_dir, exist_ok=True)

    def load_data(self):
        """Load and preprocess the dataset."""
        print("=" * 60)
        print("LOADING DATASET")
        print("=" * 60)

        self.df = pd.read_csv(self.data_path)
        print(f"✓ Loaded {len(self.df):,} interactions")
        print(f"✓ Shape: {self.df.shape}")

        # Drop location columns (US data, not relevant for Syria)
        location_cols = ['city', 'state', 'zip', 'country', 'lat', 'lng']
        existing_location_cols = [col for col in location_cols if col in self.df.columns]

        if existing_location_cols:
            self.df = self.df.drop(columns=existing_location_cols)
            print(f"✓ Dropped location columns: {existing_location_cols}")

        # Auto-detect feature columns
        self.feature_cols = [col for col in self.df.columns if col.startswith('c_')]
        self.feature_cols = sorted(self.feature_cols, key=lambda x: (len(x), x))

        print(f"✓ Detected {len(self.feature_cols)} feature columns")

        # Handle missing values
        self.df[self.feature_cols] = self.df[self.feature_cols].fillna(0)

        # Parse timestamps
        self.df['start_time'] = pd.to_datetime(self.df['start_time'], errors='coerce')
        self.df = self.df.dropna(subset=['start_time'])

        print(f"✓ Dataset cleaned: {len(self.df):,} interactions")
        print(f"  • Unique events: {self.df['event_id'].nunique():,}")
        print(f"  • Unique users: {self.df['user_id'].nunique():,}")

    def build_event_features(self):
        """Build event feature matrix."""
        print("\n" + "=" * 60)
        print("BUILDING EVENT FEATURES")
        print("=" * 60)

        # Create unique event feature matrix
        event_features = self.df.groupby('event_id')[self.feature_cols].first().reset_index()
        event_times = self.df.groupby('event_id')['start_time'].first().reset_index()

        self.events_df = event_features.merge(event_times, on='event_id')

        # Normalize features
        self.scaler = StandardScaler()
        self.events_df[self.feature_cols] = self.scaler.fit_transform(
            self.events_df[self.feature_cols]
        )

        print(f"✓ Event feature matrix created: {self.events_df.shape}")
        print(f"✓ Features normalized (mean≈0, std≈1)")

    def build_user_profiles(self):
        """Build user preference profiles."""
        print("\n" + "=" * 60)
        print("BUILDING USER PROFILES")
        print("=" * 60)

        # Merge interaction data with event features
        user_event_features = self.df[['user_id', 'event_id']].merge(
            self.events_df[['event_id'] + self.feature_cols],
            on='event_id',
            how='left'
        )

        # Compute user profile as mean of their event features
        self.user_profiles = user_event_features.groupby('user_id')[self.feature_cols].mean().reset_index()

        # Compute global average profile (for cold start)
        self.global_profile = self.events_df[self.feature_cols].mean().values

        print(f"✓ User profiles created: {len(self.user_profiles):,} users")
        print(f"✓ Global profile computed (dimension: {len(self.global_profile)})")

    def train_collaborative_filtering(self):
        """Train optional collaborative filtering model using LightFM."""
        try:
            from lightfm import LightFM
            from lightfm.evaluation import precision_at_k
        except ImportError:
            print("\n⚠ LightFM not available - skipping collaborative filtering")
            print("  Install with: pip install lightfm")
            return

        print("\n" + "=" * 60)
        print("TRAINING COLLABORATIVE FILTERING")
        print("=" * 60)

        # Build interaction matrix
        self.user_id_map = {uid: idx for idx, uid in enumerate(self.df['user_id'].unique())}
        self.event_id_map = {eid: idx for idx, eid in enumerate(self.events_df['event_id'].unique())}

        self.idx_to_user = {idx: uid for uid, idx in self.user_id_map.items()}
        self.idx_to_event = {idx: eid for eid, idx in self.event_id_map.items()}

        # Map interactions
        user_indices = self.df['user_id'].map(self.user_id_map)
        event_indices = self.df['event_id'].map(self.event_id_map)

        # Build sparse matrix
        n_users = len(self.user_id_map)
        n_events = len(self.event_id_map)

        interaction_matrix = csr_matrix(
            (np.ones(len(self.df)), (user_indices, event_indices)),
            shape=(n_users, n_events)
        )

        print(f"✓ Interaction matrix: {interaction_matrix.shape}")
        print(f"  Density: {interaction_matrix.nnz / (n_users * n_events):.4%}")

        # Train LightFM model
        self.cf_model = LightFM(
            loss='warp',
            no_components=50,
            learning_rate=0.05,
            random_state=RANDOM_SEED
        )

        print("\nTraining LightFM (WARP loss)...")
        for epoch in range(10):
            self.cf_model.fit_partial(interaction_matrix, epochs=1)
            if (epoch + 1) % 2 == 0:
                train_precision = precision_at_k(self.cf_model, interaction_matrix, k=10).mean()
                print(f"  Epoch {epoch+1}: Precision@10 = {train_precision:.4f}")

        print("✓ Collaborative filtering model trained")

    def evaluate(self):
        """Evaluate model performance."""
        print("\n" + "=" * 60)
        print("EVALUATION")
        print("=" * 60)

        # Only keep users with at least 3 interactions
        user_counts = self.df['user_id'].value_counts()
        valid_users = user_counts[user_counts >= 3].index

        df_eval = self.df[self.df['user_id'].isin(valid_users)]

        # Temporal split
        df_eval = df_eval.sort_values('start_time')
        split_idx = int(len(df_eval) * 0.8)

        train_df = df_eval.iloc[:split_idx]
        test_df = df_eval.iloc[split_idx:]

        print(f"✓ Train set: {len(train_df):,} interactions")
        print(f"✓ Test set: {len(test_df):,} interactions")

        # Rebuild user profiles from training data
        train_user_event_features = train_df[['user_id', 'event_id']].merge(
            self.events_df[['event_id'] + self.feature_cols],
            on='event_id',
            how='left'
        )
        train_user_profiles = train_user_event_features.groupby('user_id')[self.feature_cols].mean().reset_index()

        # Evaluate on sample users
        from sklearn.metrics.pairwise import cosine_similarity

        test_users = test_df['user_id'].unique()
        eval_users = [u for u in test_users if u in train_user_profiles['user_id'].values][:100]

        precisions = []
        recalls = []

        print(f"\nEvaluating on {len(eval_users)} users...")

        for user_id in eval_users:
            # Ground truth
            true_events = set(test_df[test_df['user_id'] == user_id]['event_id'].values)
            if len(true_events) == 0:
                continue

            # Get user vector
            user_data = train_user_profiles[train_user_profiles['user_id'] == user_id]
            if len(user_data) == 0:
                continue

            user_vector = user_data[self.feature_cols].values[0]

            # Compute similarities
            event_matrix = self.events_df[self.feature_cols].values
            similarities = cosine_similarity([user_vector], event_matrix)[0]

            # Get top-10
            top_indices = np.argsort(-similarities)[:10]
            recommended_events = set(self.events_df.iloc[top_indices]['event_id'].values)

            # Calculate metrics
            hits = len(recommended_events & true_events)
            precision = hits / 10
            recall = hits / len(true_events)

            precisions.append(precision)
            recalls.append(recall)

        if precisions:
            avg_precision = np.mean(precisions)
            avg_recall = np.mean(recalls)

            print(f"\n✓ Precision@10: {avg_precision:.4f}")
            print(f"✓ Recall@10: {avg_recall:.4f}")
        else:
            print("\n⚠ Insufficient data for evaluation")

    def save_models(self):
        """Save all trained models and artifacts."""
        print("\n" + "=" * 60)
        print("SAVING MODELS")
        print("=" * 60)

        # Save scaler
        joblib.dump(self.scaler, f'{self.output_dir}/scaler.joblib')
        print(f"✓ {self.output_dir}/scaler.joblib")

        # Save event feature matrix
        self.events_df.to_csv(f'{self.output_dir}/event_matrix.csv', index=False)
        print(f"✓ {self.output_dir}/event_matrix.csv")

        # Save user profiles
        self.user_profiles.to_csv(f'{self.output_dir}/user_profiles.csv', index=False)
        print(f"✓ {self.output_dir}/user_profiles.csv")

        # Save global profile
        np.save(f'{self.output_dir}/global_profile.npy', self.global_profile)
        print(f"✓ {self.output_dir}/global_profile.npy")

        # Save metadata
        metadata = {
            'feature_columns': self.feature_cols,
            'n_features': len(self.feature_cols),
            'n_events': len(self.events_df),
            'n_users': len(self.user_profiles),
            'n_interactions': len(self.df),
            'model_version': '1.0',
            'created_at': datetime.now().isoformat(),
            'random_seed': RANDOM_SEED
        }

        with open(f'{self.output_dir}/metadata.json', 'w') as f:
            json.dump(metadata, f, indent=2)
        print(f"✓ {self.output_dir}/metadata.json")

        # Save CF model if available
        if self.cf_model is not None:
            joblib.dump({
                'model': self.cf_model,
                'user_id_map': self.user_id_map,
                'event_id_map': self.event_id_map,
                'idx_to_user': self.idx_to_user,
                'idx_to_event': self.idx_to_event
            }, f'{self.output_dir}/cf_model.joblib')
            print(f"✓ {self.output_dir}/cf_model.joblib")

        print("\n✅ All models saved successfully!")

    def train(self):
        """Run full training pipeline."""
        self.load_data()
        self.build_event_features()
        self.build_user_profiles()
        self.train_collaborative_filtering()
        self.evaluate()
        self.save_models()

        print("\n" + "=" * 60)
        print("TRAINING COMPLETE")
        print("=" * 60)
        print(f"Models saved to: {self.output_dir}/")
        print("\nNext steps:")
        print("  1. Use recommender.py for inference")
        print("  2. Deploy with api.py (FastAPI)")
        print("  3. Integrate with your Flutter app")


def main():
    parser = argparse.ArgumentParser(description='Train event recommendation models')
    parser.add_argument('--data', type=str, default='Dataset.csv',
                        help='Path to dataset CSV file')
    parser.add_argument('--output', type=str, default='ai_recommendation/models',
                        help='Output directory for models')

    args = parser.parse_args()

    trainer = EventRecommendationTrainer(args.data, args.output)
    trainer.train()


if __name__ == '__main__':
    main()
