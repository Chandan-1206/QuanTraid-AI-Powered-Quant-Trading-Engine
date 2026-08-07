from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import yfinance as yf
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import math

def clean_nan(obj):
    if isinstance(obj, float) and math.isnan(obj):
        return None
    elif isinstance(obj, dict):
        return {k: clean_nan(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [clean_nan(x) for x in obj]
    return obj

from model_1a import run_long_term_model, run_tft_short_term
from model_1b import run_model_1b
from portfolio.optimizer import router as portfolio_router

app = FastAPI(title="AI Investment Advisor Backend - Multi-Model Edition")

# Setup CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For flutter localhost access
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(portfolio_router)

class PredictionRequest(BaseModel):
    stock: str
    duration: str # e.g. "3months"

@app.post("/predict")
def predict_stock(req: PredictionRequest):
    stock_ticker = req.stock
    
    # 1. Fetch stock data using yfinance (6 months)
    try:
        df = yf.download(stock_ticker, period="6mo", interval="1d")
        if df.empty:
            raise HTTPException(status_code=404, detail=f"No data found for stock: {stock_ticker}")
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))
        
    # Flatten MultiIndex columns if returning from yfinance
    if isinstance(df.columns, pd.MultiIndex):
        df.columns = df.columns.get_level_values(0)

    # 2. Extract Closing Prices and Basic Formatting
    df = df.reset_index()
    df['Date'] = pd.to_datetime(df['Date']).dt.tz_localize(None)
    df.sort_values('Date', inplace=True)
    df.dropna(subset=['Close'], inplace=True)
    
    current_price = float(df['Close'].iloc[-1])
    
    # --- LONG TERM MODEL (Existing logic) ---
    out_long_term = run_long_term_model(stock_ticker, current_price, df)
    
    # --- SHORT TERM TFT MODEL (New logic) ---
    out_tft = run_tft_short_term(stock_ticker, current_price, df)
    if not out_tft:
        raise HTTPException(status_code=500, detail="TFT Model failed to generate predictions")
        
    # Extract Mondays from TFT predictions
    monday_predictions = []
    for p in out_tft["predictions"]:
        dt = datetime.strptime(p["date"], "%Y-%m-%d")
        if dt.weekday() == 0:  # Monday
            p["priority"] = True if p["confidence"] > 0.75 else False
            monday_predictions.append(p)
            
    # Sort monday predictions by score
    monday_predictions.sort(key=lambda x: x.get("score", 0), reverse=True)
    
    # Extract Top Opportunities
    # Sort all short term by score, take top 5
    sorted_short_term = sorted(out_tft["predictions"], key=lambda x: x.get("score", 0), reverse=True)
    top_opportunities = sorted_short_term[:5]
            
    # --- MODEL 1B (Heuristics, Risk, Trend) ---
    out_1b = run_model_1b(df)
    
    # --- FINAL DECISION ENGINE ---
    m1a_signal = out_tft['base_signal']
    m1a_conf = out_tft['confidence']
    trend = out_1b['trend']
    risk = out_1b['risk_level']
    
    final_signal = "HOLD"
    
    if m1a_signal == "BUY":
        if trend == "BULLISH" and risk == "LOW" and m1a_conf > 0.75:
            final_signal = "STRONG BUY"
        else:
            final_signal = "BUY"
            
    elif m1a_signal == "SELL":
        if trend == "BEARISH":
            final_signal = "STRONG SELL"
        else:
            final_signal = "SELL"
    else:
        final_signal = "HOLD"

    # --- AI EXPLANATION ENGINE ---
    explanation = f"Trend is {trend.lower()} with {risk.lower()} risk profile. "
    
    if m1a_signal == "BUY":
        explanation += "Short-term TFT model predicts a price increase. "
    elif m1a_signal == "SELL":
        explanation += "Short-term TFT model predicts a price decrease. "
    else:
        explanation += "Short-term TFT model sees limited price movement. "

    if final_signal == "STRONG BUY":
        explanation += "All indicators align positively, making this a strong buying opportunity."
    elif final_signal == "BUY":
        explanation += "A favorable setup, though some indicators lack conviction."
    elif final_signal == "STRONG SELL":
        explanation += "High risk of further downside confirmed by models. Consider exiting."
    elif final_signal == "SELL":
        explanation += "Consider booking profits or reducing exposure."
    else:
        explanation += "Current setup suggests waiting for a clearer signal."

    response_data = {
        "stock": stock_ticker,
        "current_price": round(current_price, 2),
        "final_signal": final_signal,
        "confidence": m1a_conf,
        "risk_level": risk,
        "trend": trend,
        "explanation": explanation,
        "short_term_predictions": out_tft["predictions"],
        "monday_predictions": monday_predictions,
        "top_opportunities": top_opportunities,
        "long_term_predictions": out_long_term,
        "model_1a": {
            "base_signal": m1a_signal
        },
        "model_1b": {
            "momentum_score": out_1b["momentum_score"],
            "volatility_score": out_1b["volatility_score"],
            "strength": out_1b["strength"]
        }
    }
    return clean_nan(response_data)

@app.get("/market-overview")
def get_market_overview():
    # Mocked for speed. In prod, fetch real data from top tickers.
    return {
        "sentiment": "Bullish",
        "market_trend_strength": 65.4,
        "top_gainer": {"stock": "TCS.NS", "change_percent": 3.4},
        "top_loser": {"stock": "RELIANCE.NS", "change_percent": -1.2},
        "active_signals": {"buy": 12, "sell": 4, "hold": 34}
    }
