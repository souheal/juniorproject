# AI Event Recommendation System

**An intelligent event recommendation engine using content-based and collaborative filtering techniques.**

---

## 🎯 Overview

This system provides **AI-powered personalized event recommendations** for the Eventy platform. It learns user preferences from interaction history and recommends relevant upcoming events based on latent feature patterns.

### Key Features

- ✅ **Content-Based Filtering**: Uses event feature vectors (c_1...c_100, c_other) to find similar events
- ✅ **Collaborative Filtering**: Optional LightFM model for implicit feedback learning
- ✅ **Hybrid Approach**: Combines both methods for robust recommendations
- ✅ **Cold Start Handling**: Supports new users via custom interest vectors or global profiles
- ✅ **Production Ready**: FastAPI server with RESTful endpoints
- ✅ **Location Agnostic**: Ignores US location data, focuses purely on interest patterns

---

## 📁 Project Structure

```
ai_recommendation/
├── recommendation.ipynb      # Jupyter notebook for exploration & training
├── train_recommender.py      # Standalone training script
├── recommender.py            # Production inference module
├── api.py                    # FastAPI server
├── requirements.txt          # Python dependencies
├── README.md                 # This file
└── models/                   # Trained model artifacts (generated)
    ├── scaler.joblib
    ├── event_matrix.csv
    ├── user_profiles.csv
    ├── global_profile.npy
    ├── metadata.json
    └── cf_model.joblib       # Optional CF model
```

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
# Create virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install packages
pip install -r requirements.txt
```

### 2. Prepare Dataset

Place your `Dataset.csv` in the project root with the following columns:

**Required:**
- `event_id` (int)
- `user_id` (int)
- `start_time` (datetime)
- `c_1, c_2, ..., c_100, c_other` (numeric features)

**Ignored (if present):**
- `city, state, zip, country, lat, lng` (location columns)

### 3. Train Models

**Option A: Using Jupyter Notebook (Recommended for exploration)**

```bash
jupyter notebook recommendation.ipynb
```

Run all cells to:
- Load and explore data
- Train content-based and collaborative filtering models
- Evaluate performance
- Save models to `models/` directory

**Option B: Using CLI Script**

```bash
python train_recommender.py --data Dataset.csv --output models/
```

### 4. Run API Server

```bash
python api.py

# Or with uvicorn directly:
uvicorn api:app --host 0.0.0.0 --port 8000 --reload
```

Server will be available at: `http://localhost:8000`

API docs (Swagger): `http://localhost:8000/docs`

---

## 📡 API Endpoints

### 1. Get Recommendations

**Endpoint:** `POST /recommend`

**Request:**
```json
{
  "user_id": 123,
  "top_k": 10,
  "upcoming_only": true,
  "exclude_event_ids": [45, 67],
  "content_weight": 0.7,
  "cf_weight": 0.3
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "event_id": 789,
      "start_time": "2025-01-15T18:00:00",
      "score": 0.8543
    },
    ...
  ],
  "message": "Generated 10 recommendations"
}
```

### 2. Cold Start (New User)

**Request:**
```json
{
  "interest_vector": [1.2, -0.5, 0.8, ...],  // 101 values
  "top_k": 10
}
```

### 3. Similar Events

**Endpoint:** `POST /recommend/similar`

**Request:**
```json
{
  "event_id": 456,
  "top_k": 5,
  "upcoming_only": true
}
```

### 4. Trending Events

**Endpoint:** `GET /recommend/trending?top_k=20&upcoming_only=true`

### 5. Update User Profile

**Endpoint:** `POST /user/profile/update`

**Request:**
```json
{
  "user_id": 123,
  "event_ids": [10, 20, 30],
  "save": true
}
```

---

## 🧠 How It Works

### 1. Data Preprocessing

```
Raw Dataset
    ↓
Drop location columns (city, state, zip, country, lat, lng)
    ↓
Auto-detect feature columns (c_1...c_100, c_other)
    ↓
Handle missing values (fill with 0)
    ↓
Normalize features (StandardScaler)
    ↓
Create event feature matrix
```

### 2. User Profile Construction

```
For each user:
    Collect all events they interacted with
    ↓
    Extract feature vectors for those events
    ↓
    Compute mean vector → User Profile
```

**Cold Start:** If user has no history, use:
- Custom interest vector (provided by user)
- OR global average profile

### 3. Content-Based Recommendation

```
Given: User Profile Vector U

For each candidate event E:
    Compute cosine_similarity(U, E)
    ↓
Sort by similarity (descending)
    ↓
Filter upcoming events
    ↓
Exclude already attended events
    ↓
Return Top-K
```

### 4. Collaborative Filtering (Optional)

Uses **LightFM** with WARP loss:

```
Build sparse interaction matrix (users × events)
    ↓
Train LightFM model (implicit feedback)
    ↓
Predict scores for user-event pairs
    ↓
Combine with content scores (hybrid)
```

**Hybrid Score:**
```
final_score = 0.7 * content_score + 0.3 * cf_score
```

---

## 📊 Evaluation Metrics

The system is evaluated using:

- **Precision@K**: Fraction of recommended events that user interacted with
- **Recall@K**: Fraction of user's true events that were recommended

**Temporal Split:**
- Train: 80% oldest interactions
- Test: 20% newest interactions

---

## 🔧 Python Usage Examples

### Example 1: Basic Recommendation

```python
from recommender import EventRecommender

# Load trained models
recommender = EventRecommender(model_dir='models/')

# Get recommendations for user
recommendations = recommender.recommend(
    user_id=123,
    top_k=10,
    upcoming_only=True
)

for rec in recommendations:
    print(f"Event {rec['event_id']}: Score {rec['score']:.4f}")
```

### Example 2: Cold Start

```python
import numpy as np

# Create custom interest vector
interest = np.zeros(101)  # 101 features (c_1...c_100 + c_other)
interest[:10] = 2.0       # High interest in first 10 features
interest[10:20] = -1.0    # Low interest in next 10

recommendations = recommender.recommend(
    user_id=None,
    interest_vector=interest.tolist(),
    top_k=10
)
```

### Example 3: Update User Profile

```python
# User attended new events
recommender.update_user_profile(
    user_id=123,
    event_ids=[45, 67, 89],
    save=True
)
```

### Example 4: Similar Events

```python
# Find events similar to event 456
similar = recommender.recommend_similar_events(
    event_id=456,
    top_k=5
)
```

---

## 🔗 Integration with Flutter App

### Step 1: Start API Server

```bash
python api.py
```

### Step 2: Call from Flutter (Dart)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<dynamic>> getRecommendations(int userId) async {
  final response = await http.post(
    Uri.parse('http://YOUR_SERVER:8000/recommend'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'user_id': userId,
      'top_k': 10,
      'upcoming_only': true,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['data'];
  } else {
    throw Exception('Failed to load recommendations');
  }
}
```

---

## 📈 Model Performance

Expected performance (depends on dataset quality):

- **Precision@10**: 0.15 - 0.35
- **Recall@10**: 0.08 - 0.25

**Note:** These metrics are typical for implicit feedback recommendation systems. Higher values indicate better learning of user preferences.

---

## 🛠️ Customization

### Adjust Hybrid Weights

In `api.py` or when calling `recommend()`:

```python
recommendations = recommender.recommend(
    user_id=123,
    content_weight=0.8,  # Increase content-based influence
    cf_weight=0.2        # Decrease collaborative filtering influence
)
```

### Retrain Models

After collecting more interaction data:

```bash
python train_recommender.py --data NewDataset.csv --output models/
```

Then restart API server to load new models.

---

## 📋 System Requirements

- **Python**: 3.9+
- **RAM**: 4GB minimum (depends on dataset size)
- **Storage**: 500MB for models (varies with dataset)
- **OS**: Windows, Linux, macOS

---

## 🐛 Troubleshooting

### Issue: "LightFM not available"

**Solution:**
```bash
pip install lightfm
```

If installation fails, the system will use content-based filtering only (still works well).

### Issue: "Insufficient data for evaluation"

**Cause:** Not enough users with multiple interactions.

**Solution:** Ensure dataset has users with ≥3 interactions for meaningful evaluation.

### Issue: API returns empty recommendations

**Cause:** No upcoming events in dataset.

**Solution:** Set `upcoming_only=False` in request, or use past reference time for testing.

---

## 📚 References

- **Content-Based Filtering**: Cosine similarity on feature vectors
- **Collaborative Filtering**: [LightFM](https://github.com/lyst/lightfm) (WARP loss)
- **Hybrid Recommenders**: Weighted score combination
- **Cold Start**: Global profile and custom interest vectors

---

## 📝 License

This recommendation system is part of the Eventy graduation project.

---

## 👥 Support

For questions or issues, contact the development team or open an issue in the project repository.

---

**Built with ❤️ for the Eventy platform**
