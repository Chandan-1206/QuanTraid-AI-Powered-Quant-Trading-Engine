import pandas as pd
import yfinance as yf
from model_1a import run_tft_short_term
from model_1b import run_model_1b
from .analyzer import SECTOR_MAP
from .signal_engine import portfolio_adjusted_signal, generate_explanation
import numpy as np

def rank_stocks(sector: str, current_portfolio_symbols: list, analyzer, portfolio_risk: float = None):
    # Get 3-4 top stocks in this sector not in portfolio
    candidates = [s for s in SECTOR_MAP.get(sector, []) if s not in current_portfolio_symbols][:3]
    
    ranked = []
    for stock in candidates:
        try:
            ticker = stock + ".NS"
            df = yf.download(ticker, period="6mo", interval="1d", progress=False)
            if df.empty:
                continue
                
            if isinstance(df.columns, pd.MultiIndex):
                df.columns = df.columns.get_level_values(0)
            df = df.reset_index()
            df['Date'] = pd.to_datetime(df['Date']).dt.tz_localize(None)
            df.sort_values('Date', inplace=True)
            
            current_price = float(df['Close'].iloc[-1])
            
            out_tft = run_tft_short_term(ticker, current_price, df)
            out_1b = run_model_1b(df)
            
            if not out_tft: continue
            
            # Risk-Adjusted Scoring
            confidence = out_tft.get('confidence', 0.5)
            
            daily_returns = df['Close'].pct_change().dropna()
            expected_return = daily_returns.mean() * 252
            risk = daily_returns.std() * np.sqrt(252)
            
            # Predict Return: last short term prediction / current_price - 1
            predicted_price = out_tft['predictions'][-1].get('predicted_price', current_price) if out_tft.get('predictions') else current_price
            predicted_return = (predicted_price - current_price) / current_price
            
            strength_str = out_1b.get('strength', 'MODERATE')
            if strength_str == 'STRONG':
                trend_strength = 1.0
            elif strength_str == 'MODERATE':
                trend_strength = 0.5
            else:
                trend_strength = 0.0
            
            sharpe_ratio = (expected_return - 0.05) / (risk + 1e-6)
            
            score = (
                0.30 * confidence +
                0.30 * abs(predicted_return) +
                0.20 * trend_strength +
                0.20 * sharpe_ratio
            )
            
            base_signal = out_tft.get('base_signal', 'HOLD')
            trend = out_1b.get('trend', 'SIDEWAYS')
            
            # Signal Engine Integration
            adjusted_signal = portfolio_adjusted_signal(base_signal, stock, analyzer, portfolio_risk)
            explanation = generate_explanation(adjusted_signal, predicted_return, confidence, trend)
            
            ranked.append({
                "stock": stock,
                "score": score,
                "predicted_price": round(predicted_price, 2),
                "confidence": confidence,
                "signal": adjusted_signal,
                "explanation": explanation,
                "risk": risk
            })
        except Exception as e:
            print(f"Error ranking {stock}: {e}")
            continue
            
    # Sort by score descending
    ranked.sort(key=lambda x: x["score"], reverse=True)
    return ranked

def suggest_improvements(analyzer_status: str, analyzer_data: dict, analyzer, portfolio_risk: float = None):
    current_symbols = [s for s in analyzer_data.get("weights", {}).keys()]
    
    suggested_sectors = []
    
    if analyzer_status == "UNDER_DIVERSIFIED":
        # Find sectors not in portfolio
        covered_sectors = list(analyzer_data.get("sector_exposure", {}).keys())
        all_sectors = list(SECTOR_MAP.keys())
        missing = [s for s in all_sectors if s not in covered_sectors and s != "Other"]
        suggested_sectors = missing[:3]
        
    elif analyzer_status == "OVER_CONCENTRATED":
        # Find sectors not currently concentrated
        covered_sectors = list(analyzer_data.get("sector_exposure", {}).keys())
        all_sectors = list(SECTOR_MAP.keys())
        missing = [s for s in all_sectors if s not in covered_sectors and s != "Other"]
        suggested_sectors = missing[:2]

    ranked_stocks = {}
    for sector in suggested_sectors:
        ranked_stocks[sector] = rank_stocks(sector, current_symbols, analyzer, portfolio_risk)
        
    return suggested_sectors, ranked_stocks
