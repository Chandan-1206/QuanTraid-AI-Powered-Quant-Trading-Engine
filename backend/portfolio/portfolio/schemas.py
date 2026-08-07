# backend/portfolio/schemas.py
from pydantic import BaseModel, Field
from typing import Optional, List, Dict
from datetime import datetime


class HoldingInput(BaseModel):
    symbol: str
    quantity: float
    buy_price: Optional[float] = None


class HoldingsSaveRequest(BaseModel):
    holdings: List[HoldingInput]


class AnalyseRequest(BaseModel):
    # If None, loads from Firestore
    holdings: Optional[List[HoldingInput]] = None


class OptimiseRequest(BaseModel):
    # If None, loads from Firestore
    holdings: Optional[List[HoldingInput]] = None
    mode: str = "A"                     # A = no new capital, B = new capital available
    new_capital_inr: Optional[float] = None
    risk_profile: str = "moderate"      # conservative | moderate | aggressive
    turnover_limit: float = 0.3         # max 30% L1 weight change allowed


class WeightDetail(BaseModel):
    symbol: str
    current_weight: float
    optimised_weight: float
    action: str                         # increase | reduce | hold


class PortfolioStats(BaseModel):
    expected_annual_return: float
    annual_volatility: float
    sharpe_ratio: float


class HealthReport(BaseModel):
    diversification_score: float
    sector_concentration: str
    hhi: float
    correlation_risk: str
    sector_breakdown: Dict[str, float]


class RebalancingItem(BaseModel):
    symbol: str
    change_pct: float
    change_inr: Optional[float] = None


class SectorSuggestion(BaseModel):
    sector: str
    reason: str
    top_picks: List[str]


class BacktestResult(BaseModel):
    period: str
    current_portfolio_return: float
    optimised_portfolio_return: float
    current_sharpe: float
    optimised_sharpe: float


class OptimisationResult(BaseModel):
    ticker_count: int
    portfolio_value_inr: Optional[float]
    health: HealthReport
    current: PortfolioStats
    optimised: PortfolioStats
    weights: List[WeightDetail]
    rebalancing: List[RebalancingItem]
    sector_suggestions: List[SectorSuggestion]
    backtest: BacktestResult
    sentiment_modifiers_applied: Dict[str, float]
    as_of: str
