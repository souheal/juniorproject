# AI Recommendation System - Setup Guide

This guide walks you through setting up and using the AI Event Recommendation System.

---

## 📋 Prerequisites

1. **Python 3.9 or higher**
   - Check: `python --version`
   - Download: https://www.python.org/downloads/

2. **pip (Python package manager)**
   - Usually comes with Python
   - Check: `pip --version`

3. **Dataset.csv**
   - Your event interaction dataset
   - Must have columns: event_id, user_id, start_time, c_1...c_100, c_other

---

## 🚀 Step-by-Step Setup

### Step 1: Navigate to AI Directory

```bash
cd C:\Users\Owner\juniorproject\Ai
```

### Step 2: Create Virtual Environment (Recommended)

```bash
# Create virtual environment
python -m venv venv

# Activate it
# On Windows:
venv\Scripts\activate

# On Linux/Mac:
source venv/bin/activate
```

You should see `(venv)` in your command prompt.

### Step 3: Install Dependencies

```bash
cd ai_recommendation
pip install -r requirements.txt
```

**This will install:**
- numpy, pandas, scipy (data processing)
- scikit-learn (machine learning)
- lightfm (collaborative filtering)
- fastapi, uvicorn (API server)
- jupyter (for notebooks)
- matplotlib, seaborn (visualization)

**Installation time:** 5-10 minutes depending on your internet speed.

### Step 4: Place Your Dataset

Put `Dataset.csv` in the `Ai/` folder (one level up from ai_recommendation):

```
Ai/
├── Dataset.csv                  ← Your dataset here
├── ai_recommendation/
│   ├── recommendation.ipynb
│   ├── train_recommender.py
│   └── ...
```

---

## 🎓 Training Models

You have two options:

### Option A: Jupyter Notebook (Interactive, Recommended for Learning)

1. **Start Jupyter:**
   ```bash
   cd ..  # Go back to Ai/ folder
   jupyter notebook
   ```  

2. **Open notebook:**
   - Browser will open automatically
   - Click: `recommendation.ipynb`

3. **Run cells:**
   - Click "Cell" → "Run All"
   - OR press `Shift+Enter` on each cell
   - Watch the training progress

4. **Models will be saved to:**
   ```
   ai_recommendation/models/
   ```

### Option B: Command Line (Fast, Automated)

```bash
cd ai_recommendation
python train_recommender.py --data ../Dataset.csv --output models/
```

**Expected output:**
```
============================================================
LOADING DATASET
============================================================
✓ Loaded 50,000 interactions
✓ Shape: (50000, 105)
✓ Dropped location columns: ['city', 'state', 'zip', 'country', 'lat', 'lng']
...
✓ Event feature matrix created: (5000, 102)
✓ User profiles created: 2,500 users
...
✓ Precision@10: 0.2543
✓ Recall@10: 0.1234
...
✅ All models saved successfully!
```

**Training time:** 2-10 minutes depending on dataset size.

---

## 🖥️ Running the API Server

### Step 1: Start Server

```bash
cd ai_recommendation
python api.py
```

**Expected output:**
```
✓ Recommendation engine loaded successfully
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 2: Test Server

Open browser and go to:
- **API Docs:** http://localhost:8000/docs
- **Root:** http://localhost:8000/

You should see a JSON response with API info.

### Step 3: Run Test Suite (Optional)

Open a NEW terminal (keep server running):

```bash
cd ai_recommendation
python test_api.py
```

This will test all endpoints and show results.

---

## 🧪 Testing Recommendations

### Test 1: Using API Docs (Easiest)

1. Go to: http://localhost:8000/docs
2. Click on `POST /recommend`
3. Click "Try it out"
4. Enter request body:
   ```json
   {
     "user_id": 1,
     "top_k": 10,
     "upcoming_only": false
   }
   ```
5. Click "Execute"
6. See recommendations in response!

### Test 2: Using Python

```python
from recommender import EventRecommender

# Load recommender
rec = EventRecommender('models/')

# Get recommendations
recs = rec.recommend(user_id=1, top_k=10, upcoming_only=False)

# Print results
for i, r in enumerate(recs, 1):
    print(f"{i}. Event {r['event_id']} - Score: {r['score']:.4f}")
```

### Test 3: Using cURL

```bash
curl -X POST "http://localhost:8000/recommend" \
  -H "Content-Type: application/json" \
  -d '{"user_id": 1, "top_k": 10, "upcoming_only": false}'
```

---

## 🔌 Integration with Flutter App

### Step 1: Get Your Server IP

If running locally:
- `http://localhost:8000`

If running on a server:
- `http://YOUR_SERVER_IP:8000`

### Step 2: Add HTTP Package to Flutter

In `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
```

Run: `flutter pub get`

### Step 3: Create Recommendation Service

```dart
// lib/services/recommendation_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecommendationService {
  static const String baseUrl = 'http://YOUR_SERVER_IP:8000';

  static Future<List<Map<String, dynamic>>> getRecommendations({
    required int userId,
    int topK = 10,
    bool upcomingOnly = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recommend'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'top_k': topK,
        'upcoming_only': upcomingOnly,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to load recommendations');
    }
  }

  static Future<List<Map<String, dynamic>>> getTrendingEvents({
    int topK = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/recommend/trending?top_k=$topK&upcoming_only=true'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    } else {
      throw Exception('Failed to load trending events');
    }
  }
}
```

### Step 4: Use in Flutter

```dart
// In your widget
List<Map<String, dynamic>> recommendations = [];

Future<void> loadRecommendations() async {
  try {
    final recs = await RecommendationService.getRecommendations(
      userId: currentUserId,
      topK: 10,
    );

    setState(() {
      recommendations = recs;
    });
  } catch (e) {
    print('Error loading recommendations: $e');
  }
}

@override
void initState() {
  super.initState();
  loadRecommendations();
}
```

---

## 📊 Verifying Model Quality

After training, check these metrics:

### Good Performance Indicators:

✅ **Precision@10 > 0.15**
- At least 1-2 relevant events in top 10

✅ **Recall@10 > 0.08**
- Captures 8% or more of user's true interests

✅ **No errors during training**
- All files saved successfully

### If Performance is Low:

1. **More data needed:**
   - Ensure users have ≥3 interactions
   - Collect more interaction history

2. **Check feature quality:**
   - Verify c_1...c_100 values are numeric
   - Ensure features are not all zeros

3. **Adjust hyperparameters:**
   - In `train_recommender.py`, modify:
     - `no_components` (CF embedding size)
     - `learning_rate` (CF training speed)
     - Weights in hybrid scoring

---

## 🐛 Common Issues & Solutions

### Issue: "ModuleNotFoundError: No module named 'lightfm'"

**Solution:**
```bash
pip install lightfm
```

If fails on Windows, try:
```bash
pip install lightfm --no-binary lightfm
```

Or skip CF and use content-based only (still works great).

---

### Issue: "File not found: Dataset.csv"

**Solution:**
- Ensure `Dataset.csv` is in the correct location
- Use absolute path: `python train_recommender.py --data "C:/path/to/Dataset.csv"`

---

### Issue: "Port 8000 already in use"

**Solution:**
```bash
# Use different port
uvicorn api:app --host 0.0.0.0 --port 8001

# Or kill existing process
# Windows: netstat -ano | findstr :8000
# Linux: lsof -i :8000
```

---

### Issue: API returns empty recommendations

**Cause:** No upcoming events (all events in past)

**Solution:**
- Set `upcoming_only: false` in request
- Or add future events to dataset

---

### Issue: "Insufficient data for evaluation"

**Cause:** Not enough users with multiple interactions

**Solution:**
- Ensure dataset has users with ≥3 events
- Training will still work, just can't compute full metrics

---

## 🎯 Next Steps

1. ✅ **Integrate with Flutter app** (see section above)
2. ✅ **Deploy API to cloud server** (AWS, Heroku, DigitalOcean)
3. ✅ **Schedule model retraining** (weekly/monthly with new data)
4. ✅ **Monitor performance** (track click-through rates)
5. ✅ **Add business rules** (e.g., boost events in Syria)

---

## 📚 Additional Resources

- **FastAPI Docs:** https://fastapi.tiangolo.com/
- **LightFM Docs:** https://making.lyst.com/lightfm/docs/home.html
- **scikit-learn:** https://scikit-learn.org/

---

## 💡 Tips for Best Results

1. **More data = better recommendations**
   - Aim for 1000+ users, 5000+ events, 50,000+ interactions

2. **Regular retraining**
   - Retrain weekly/monthly as new interactions come in

3. **Monitor user feedback**
   - Track which recommendations users click
   - Use this to fine-tune weights

4. **Hybrid approach works best**
   - Content-based catches patterns
   - CF captures user similarity
   - Combination is most robust

---

**Good luck with your graduation project! 🎓🚀**
