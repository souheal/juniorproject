"""
Test script for Event Recommendation API

This script tests all API endpoints to ensure they work correctly.

Usage:
    1. Start the API server: python api.py
    2. Run this test: python test_api.py
"""

import requests
import json
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:8000"


def print_section(title):
    """Print a formatted section header."""
    print("\n" + "=" * 60)
    print(title)
    print("=" * 60)


def test_root():
    """Test root endpoint."""
    print_section("Testing: GET /")

    response = requests.get(f"{BASE_URL}/")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

    return response.status_code == 200


def test_stats():
    """Test stats endpoint."""
    print_section("Testing: GET /stats")

    response = requests.get(f"{BASE_URL}/stats")
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

    return response.status_code == 200


def test_recommend():
    """Test recommendation endpoint."""
    print_section("Testing: POST /recommend (with user_id)")

    # Test with user_id
    payload = {
        "user_id": 1,
        "top_k": 5,
        "upcoming_only": False  # Set to False for testing with historical data
    }

    response = requests.post(f"{BASE_URL}/recommend", json=payload)
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Success: {data.get('success')}")
    print(f"Message: {data.get('message')}")

    if data.get('data'):
        print(f"\nRecommendations:")
        for i, rec in enumerate(data['data'], 1):
            print(f"  {i}. Event {rec['event_id']} - Score: {rec['score']:.4f}")

    return response.status_code == 200


def test_recommend_cold_start():
    """Test recommendation with custom interest vector."""
    print_section("Testing: POST /recommend (cold start)")

    # Create a simple interest vector (adjust length based on your feature count)
    interest_vector = [0.5] * 101  # 101 features
    interest_vector[:10] = [1.5] * 10  # High interest in first 10 features

    payload = {
        "interest_vector": interest_vector,
        "top_k": 5,
        "upcoming_only": False
    }

    response = requests.post(f"{BASE_URL}/recommend", json=payload)
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Success: {data.get('success')}")

    if data.get('data'):
        print(f"\nCold Start Recommendations:")
        for i, rec in enumerate(data['data'], 1):
            print(f"  {i}. Event {rec['event_id']} - Score: {rec['score']:.4f}")

    return response.status_code == 200


def test_trending():
    """Test trending events endpoint."""
    print_section("Testing: GET /recommend/trending")

    response = requests.get(f"{BASE_URL}/recommend/trending?top_k=5&upcoming_only=false")
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Success: {data.get('success')}")

    if data.get('data'):
        print(f"\nTrending Events:")
        for i, event in enumerate(data['data'], 1):
            print(f"  {i}. Event {event['event_id']} - Score: {event['score']:.4f}")

    return response.status_code == 200


def test_similar_events():
    """Test similar events endpoint."""
    print_section("Testing: POST /recommend/similar")

    # Use first event from stats to ensure it exists
    payload = {
        "event_id": 1,  # Adjust based on your data
        "top_k": 5,
        "upcoming_only": False
    }

    response = requests.post(f"{BASE_URL}/recommend/similar", json=payload)
    print(f"Status: {response.status_code}")
    data = response.json()
    print(f"Success: {data.get('success')}")

    if data.get('data'):
        print(f"\nSimilar Events:")
        for i, rec in enumerate(data['data'], 1):
            print(f"  {i}. Event {rec['event_id']} - Score: {rec['score']:.4f}")

    return response.status_code == 200


def test_update_profile():
    """Test user profile update endpoint."""
    print_section("Testing: POST /user/profile/update")

    payload = {
        "user_id": 99999,  # Use a test user ID
        "event_ids": [1, 2, 3],
        "save": False  # Don't save for testing
    }

    response = requests.post(f"{BASE_URL}/user/profile/update", json=payload)
    print(f"Status: {response.status_code}")
    print(json.dumps(response.json(), indent=2))

    return response.status_code == 200


def run_all_tests():
    """Run all API tests."""
    print("\n" + "#" * 60)
    print("#  EVENT RECOMMENDATION API - TEST SUITE")
    print("#" * 60)

    tests = [
        ("Root Endpoint", test_root),
        ("Stats Endpoint", test_stats),
        ("Recommend (User ID)", test_recommend),
        ("Recommend (Cold Start)", test_recommend_cold_start),
        ("Trending Events", test_trending),
        ("Similar Events", test_similar_events),
        ("Update Profile", test_update_profile),
    ]

    results = {}

    for name, test_func in tests:
        try:
            results[name] = test_func()
        except requests.exceptions.ConnectionError:
            print(f"\n❌ Connection Error: Is the API server running?")
            print("   Start with: python api.py")
            return
        except Exception as e:
            print(f"\n❌ Error in {name}: {str(e)}")
            results[name] = False

    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)

    for name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {name}")

    total = len(results)
    passed = sum(results.values())
    print(f"\nTotal: {passed}/{total} tests passed")

    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")


if __name__ == "__main__":
    run_all_tests()
