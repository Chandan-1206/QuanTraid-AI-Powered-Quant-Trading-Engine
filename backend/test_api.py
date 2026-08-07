import requests
import json

def test_predict():
    try:
        r = requests.post("http://127.0.0.1:8000/predict", json={"stock": "TCS.NS", "duration": "3months"})
        print("PREDICT STATUS:", r.status_code)
        if r.status_code != 200:
            print(r.text)
    except Exception as e:
        print("PREDICT ERROR:", e)

def test_analyze():
    try:
        payload = {
            "mode": "new_investment",
            "portfolio": [{"stock": "TCS", "amount": 50000}, {"stock": "RELIANCE", "amount": 50000}],
            "budget": 0.0
        }
        r = requests.post("http://127.0.0.1:8000/portfolio/analyze", json=payload)
        print("ANALYZE STATUS:", r.status_code)
        if r.status_code != 200:
            print(r.text)
    except Exception as e:
        print("ANALYZE ERROR:", e)

test_predict()
test_analyze()
