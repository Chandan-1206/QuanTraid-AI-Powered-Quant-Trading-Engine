from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Dict, Optional
import pandas as pd
import yfinance as yf
import numpy as np
import math

def clean_nan(obj):
    if isinstance(obj, float) and math.isnan(obj):
        return None
    elif isinstance(obj, dict):
        return {k: clean_nan(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [clean_nan(x) for x in obj]
    return obj

from .analyzer import PortfolioAnalyzer
from .risk_model import calculate_expected_returns, calculate_volatility, calculate_covariance_matrix
from .allocation import optimize_allocation
from .recommender import suggest_improvements

router = APIRouter(prefix="/portfolio", tags=["portfolio"])

class PortfolioItem(BaseModel):
    stock: str
    amount: float

class AnalyzeRequest(BaseModel):
    mode: str
    portfolio: List[PortfolioItem]
    budget: Optional[float] = 0.0

@router.post("/analyze")
def analyze_portfolio(req: AnalyzeRequest):
    if not req.portfolio:
        raise HTTPException(status_code=400, detail="Portfolio cannot be empty")
        
    portfolio_dict = [{"stock": item.stock, "amount": item.amount} for item in req.portfolio]
    analyzer = PortfolioAnalyzer(portfolio_dict, req.budget)
    analyzer_data = analyzer.analyze()
    status = analyzer_data["status"]
    
    symbols = [item.stock + ".NS" for item in req.portfolio]
    try:
        df = yf.download(symbols, period="6mo", interval="1d", progress=False)
        if df.empty:
            raise HTTPException(status_code=404, detail="No data found for given stocks")
            
        if isinstance(df.columns, pd.MultiIndex):
            df = df.xs('Close', level=0, axis=1) # Get Close prices only
        elif len(symbols) == 1:
            df = pd.DataFrame({symbols[0]: df['Close']})
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
    df.columns = [str(col).replace(".NS", "") for col in df.columns]
    
    expected_returns = calculate_expected_returns(df)
    volatility = calculate_volatility(df)
    cov_matrix = calculate_covariance_matrix(df)
    
    # Map current weights to match columns in df just in case
    # analyzer_data["weights"] contains e.g. {"TCS": 0.5}
    weight_array = []
    for col in expected_returns.index:
        weight_array.append(analyzer_data["weights"].get(col, 0.0))
    current_weights_series = pd.Series(weight_array, index=expected_returns.index)
    
    portfolio_return = np.sum(expected_returns * current_weights_series)
    portfolio_risk = np.sqrt(np.dot(current_weights_series.T, np.dot(cov_matrix, current_weights_series)))
    portfolio_sharpe = (portfolio_return - 0.05) / (portfolio_risk + 1e-6)
    
    risk_level_str = "HIGH" if portfolio_risk > 0.25 else ("MEDIUM" if portfolio_risk > 0.15 else "LOW")
    
    optimized_weights = optimize_allocation(expected_returns, cov_matrix)
    
    suggested_sectors, ranked_stocks = suggest_improvements(status, analyzer_data, analyzer, portfolio_risk)
    
    from .backtest_engine import backtest
    # mock backtest for demo using first stock
    first_stock = list(df.columns)[0]
    recent_prices = df[first_stock].tail(30).values
    mock_predictions = recent_prices * (1 + np.random.normal(0, 0.01, size=len(recent_prices)))
    bt_result = backtest(list(mock_predictions), list(recent_prices))
    
    response_data = {
        "portfolio_status": status,
        "risk_level": risk_level_str,
        "portfolio_return": round(portfolio_return, 4),
        "portfolio_risk": round(portfolio_risk, 4),
        "sharpe_ratio": round(portfolio_sharpe, 4),
        "optimized_weights": optimized_weights,
        "suggested_sectors": suggested_sectors,
        "ranked_stocks": ranked_stocks,
        "backtest_metrics": bt_result
    }
    return clean_nan(response_data)
