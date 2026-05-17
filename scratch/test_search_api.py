import requests

try:
    url = "http://localhost:5149/api/Search?q=bun"
    print(f"🔍 Calling {url}...")
    res = requests.get(url, timeout=5)
    print(f"Status Code: {res.statusCode if hasattr(res, 'statusCode') else res.status_code}")
    print(f"Response: {res.text[:1000]}")
except Exception as e:
    print(f"❌ Error: {e}")
