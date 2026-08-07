import pandas as pd
import numpy as np

def run_model_1b(df: pd.DataFrame):
    """
    Rebuilds Model 1B (QuanTraid) logic using lightweight technical heuristics.
    Returns:
    {
        "trend": "BULLISH / BEARISH / NEUTRAL",
        "risk_level": "LOW / MEDIUM / HIGH",
        "momentum_score": float (0 to 1),
        "volatility_score": float (0 to 1),
        "strength": "STRONG / MODERATE / WEAK"
    }
    """
    if df.empty or len(df) < 14:
        return {
            "trend": "NEUTRAL",
            "risk_level": "MEDIUM",
            "momentum_score": 0.5,
            "volatility_score": 0.5,
            "strength": "WEAK"
        }

    # Extract closing prices
    closes = df['Close']
    
    # 1. Volatility (Standard Deviation over last 14 days)
    returns = closes.pct_change().dropna()
    recent_returns = returns.tail(14)
    daily_vol = recent_returns.std()
    annualized_vol = daily_vol * np.sqrt(252)
    
    # Normalize volatility (roughly 0 to 1 scale for Indian market)
    vol_score = min(max(annualized_vol / 0.5, 0.0), 1.0)
    
    if vol_score < 0.2:
        risk_level = "LOW"
    elif vol_score < 0.5:
        risk_level = "MEDIUM"
    else:
        risk_level = "HIGH"

    # 2. Momentum (RSI - 14 days)
    delta = closes.diff()
    gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
    loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
    rs = gain / loss
    rsi = 100 - (100 / (1 + rs))
    current_rsi = rsi.iloc[-1]
    
    # Momentum Score (0 to 1 based on RSI)
    # Typically RSI > 60 is bullish momentum, RSI < 40 is bearish
    if np.isnan(current_rsi):
        momentum_score = 0.5
    else:
        momentum_score = current_rsi / 100.0

    # 3. Trend Validation (Moving Averages 20 vs 50)
    if len(df) >= 50:
        ma20 = closes.rolling(window=20).mean().iloc[-1]
        ma50 = closes.rolling(window=50).mean().iloc[-1]
        current_price = closes.iloc[-1]
        
        if current_price > ma20 and ma20 > ma50:
            trend = "BULLISH"
        elif current_price < ma20 and ma20 < ma50:
            trend = "BEARISH"
        else:
            trend = "NEUTRAL"
    else:
        # Fallback if less than 50 days of data
        price_change = (closes.iloc[-1] - closes.iloc[0]) / closes.iloc[0]
        if price_change > 0.05:
            trend = "BULLISH"
        elif price_change < -0.05:
            trend = "BEARISH"
        else:
            trend = "NEUTRAL"

    # 4. Strength calculation
    # High momentum + clear trend = STRONG
    if trend != "NEUTRAL" and (momentum_score > 0.65 or momentum_score < 0.35):
        strength = "STRONG"
    elif trend != "NEUTRAL":
        strength = "MODERATE"
    else:
        strength = "WEAK"

    return {
        "trend": trend,
        "risk_level": risk_level,
        "momentum_score": round(momentum_score, 2),
        "volatility_score": round(vol_score, 2),
        "strength": strength
    }
