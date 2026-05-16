import requests

BASE_URL = "http://localhost:5149"

def test_recommendations():
    try:
        # Test for user ID 1
        print("Fetching recommendations for User 1...")
        res = requests.get(f"{BASE_URL}/api/Recommendations/1")
        print(f"Status Code: {res.status_code}")
        if res.status_code == 200:
            data = res.json()
            recs = data.get('recommendations', [])
            print(f"Found {len(recs)} recommendations.")
            if recs:
                print(f"First rec: {recs[0]['restaurant']['name']}")
        else:
            print(f"Response: {res.text}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    test_recommendations()
