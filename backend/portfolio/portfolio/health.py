# backend/portfolio/health.py
import numpy as np
import pandas as pd
from typing import List, Dict

from .schemas import HealthReport

# Sector map for predefined universe — extend as needed
SECTOR_MAP: Dict[str, str] = {
    "TCS": "IT", "INFY": "IT", "WIPRO": "IT", "HCLTECH": "IT", "TECHM": "IT",
    "LTIM": "IT", "PERSISTENT": "IT", "MPHASIS": "IT",
    "RELIANCE": "Energy", "ONGC": "Energy", "BPCL": "Energy", "IOC": "Energy",
    "POWERGRID": "Energy", "NTPC": "Energy", "TATAPOWER": "Energy",
    "HDFCBANK": "Banking", "ICICIBANK": "Banking", "SBIN": "Banking",
    "KOTAKBANK": "Banking", "AXISBANK": "Banking", "INDUSINDBK": "Banking",
    "FEDERALBNK": "Banking", "BANDHANBNK": "Banking",
    "SUNPHARMA": "Pharma", "DRREDDY": "Pharma", "CIPLA": "Pharma",
    "DIVISLAB": "Pharma", "AUROPHARMA": "Pharma", "LUPIN": "Pharma",
    "TATASTEEL": "Metals", "HINDALCO": "Metals", "JSWSTEEL": "Metals",
    "COALINDIA": "Metals", "VEDL": "Metals",
    "MARUTI": "Auto", "TATAMOTORS": "Auto", "M&M": "Auto",
    "BAJAJ-AUTO": "Auto", "HEROMOTOCO": "Auto", "EICHERMOT": "Auto",
    "HINDUNILVR": "FMCG", "ITC": "FMCG", "NESTLEIND": "FMCG",
    "BRITANNIA": "FMCG", "DABUR": "FMCG", "GODREJCP": "FMCG",
    "TITAN": "Consumer", "ASIANPAINT": "Consumer", "PIDILITIND": "Consumer",
    "HAVELLS": "Consumer",
    "LT": "Infra", "ULTRACEMCO": "Infra", "ADANIPORTS": "Infra",
    "GRASIM": "Infra", "SIEMENS": "Infra",
    "BAJFINANCE": "NBFC", "BAJAJFINSV": "NBFC", "CHOLAFIN": "NBFC",
    "MUTHOOTFIN": "NBFC",
}


def get_sector(symbol: str) -> str:
    return SECTOR_MAP.get(symbol.upper(), "Other")


def compute_hhi(weights: np.ndarray) -> float:
    """Herfindahl-Hirschman Index — 0 (perfect diversification) to 1 (single stock)."""
    return float(np.sum(weights ** 2))


def sector_breakdown(symbols: List[str], weights: np.ndarray) -> Dict[str, float]:
    """Returns sector → total weight mapping."""
    breakdown: Dict[str, float] = {}
    for sym, w in zip(symbols, weights):
        sec = get_sector(sym)
        breakdown[sec] = breakdown.get(sec, 0.0) + float(w)
    return {k: round(v, 4) for k, v in sorted(breakdown.items(), key=lambda x: -x[1])}


def top_sector_concentration(breakdown: Dict[str, float]) -> str:
    """Human-readable description of the heaviest sector."""
    if not breakdown:
        return "unknown"
    top_sec, top_w = max(breakdown.items(), key=lambda x: x[1])
    pct = round(top_w * 100, 1)
    level = "high" if top_w > 0.5 else "moderate" if top_w > 0.35 else "low"
    return f"{level} — {pct}% in {top_sec}"


def compute_correlation_risk(returns: pd.DataFrame, weights: np.ndarray) -> str:
    """Average pairwise correlation weighted by position sizes."""
    if returns.shape[1] < 2:
        return "n/a — single stock"
    corr = returns.corr().values
    n = len(weights)
    weighted_corr = 0.0
    total_w = 0.0
    for i in range(n):
        for j in range(i + 1, n):
            pair_w = weights[i] * weights[j]
            weighted_corr += pair_w * corr[i][j]
            total_w += pair_w
    avg = weighted_corr / total_w if total_w > 0 else 0.0
    if avg > 0.7:
        return "high"
    elif avg > 0.45:
        return "moderate"
    return "low"


def diversification_score(hhi: float, corr_risk: str, n_sectors: int) -> float:
    """
    Simple composite score 0–1, higher = more diversified.
    Components: HHI penalty + correlation penalty + sector variety bonus.
    """
    hhi_score = 1.0 - hhi                          # 0 (concentrated) → 1 (spread)
    corr_penalty = {"low": 0.0, "moderate": 0.15, "high": 0.30, "n/a — single stock": 0.30}
    sector_bonus = min(n_sectors / 8.0, 1.0) * 0.2  # up to 0.2 bonus for 8+ sectors
    score = hhi_score - corr_penalty.get(corr_risk, 0.0) + sector_bonus
    return round(max(0.0, min(1.0, score)), 3)


def analyse_health(
    symbols: List[str],
    weights: np.ndarray,
    returns: pd.DataFrame,
) -> HealthReport:
    hhi = compute_hhi(weights)
    breakdown = sector_breakdown(symbols, weights)
    concentration = top_sector_concentration(breakdown)
    corr_risk = compute_correlation_risk(returns, weights)
    n_sectors = len([k for k in breakdown if k != "Other"])
    div_score = diversification_score(hhi, corr_risk, n_sectors)

    return HealthReport(
        diversification_score=div_score,
        sector_concentration=concentration,
        hhi=round(hhi, 4),
        correlation_risk=corr_risk,
        sector_breakdown=breakdown,
    )
