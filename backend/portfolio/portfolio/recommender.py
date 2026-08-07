# backend/portfolio/recommender.py
"""
Detects sector gaps in optimised portfolio and suggests
top candidate stocks from the predefined NSE universe.
"""
from typing import List, Dict
from .health import SECTOR_MAP, get_sector
from .schemas import SectorSuggestion


# ~50-stock predefined Nifty 500 universe, grouped by sector
UNIVERSE: Dict[str, List[str]] = {
    "IT":       ["TCS", "INFY", "WIPRO", "HCLTECH", "TECHM", "LTIM", "PERSISTENT", "MPHASIS"],
    "Energy":   ["RELIANCE", "ONGC", "BPCL", "POWERGRID", "NTPC", "TATAPOWER"],
    "Banking":  ["HDFCBANK", "ICICIBANK", "SBIN", "KOTAKBANK", "AXISBANK", "INDUSINDBK"],
    "Pharma":   ["SUNPHARMA", "DRREDDY", "CIPLA", "DIVISLAB", "LUPIN"],
    "Metals":   ["TATASTEEL", "HINDALCO", "JSWSTEEL", "COALINDIA", "VEDL"],
    "Auto":     ["MARUTI", "TATAMOTORS", "M&M", "BAJAJ-AUTO", "EICHERMOT"],
    "FMCG":     ["HINDUNILVR", "ITC", "NESTLEIND", "BRITANNIA", "DABUR"],
    "Consumer": ["TITAN", "ASIANPAINT", "PIDILITIND", "HAVELLS"],
    "Infra":    ["LT", "ULTRACEMCO", "ADANIPORTS", "SIEMENS"],
    "NBFC":     ["BAJFINANCE", "BAJAJFINSV", "CHOLAFIN"],
}

# Minimum recommended sector weight threshold
SECTOR_WEIGHT_THRESHOLD = 0.08  # sectors below 8% weight are "underweight"


def get_current_sectors(symbols: List[str], weights) -> Dict[str, float]:
    """Returns sector → total weight in current portfolio."""
    breakdown: Dict[str, float] = {}
    for sym, w in zip(symbols, weights):
        sec = get_sector(sym)
        breakdown[sec] = breakdown.get(sec, 0.0) + float(w)
    return breakdown


def detect_missing_sectors(sector_weights: Dict[str, float]) -> List[str]:
    """Returns sectors completely absent or underweight in the portfolio."""
    covered = set(sector_weights.keys())
    all_sectors = set(UNIVERSE.keys())
    missing = all_sectors - covered
    underweight = {s for s, w in sector_weights.items() if w < SECTOR_WEIGHT_THRESHOLD}
    return list(missing | underweight)


def top_picks_for_sector(sector: str, exclude_symbols: List[str], n: int = 3) -> List[str]:
    """Returns top N stock suggestions for a sector, excluding already-held stocks."""
    candidates = UNIVERSE.get(sector, [])
    held = set(s.upper() for s in exclude_symbols)
    return [c for c in candidates if c not in held][:n]


def generate_suggestions(
    symbols: List[str],
    weights,
    sector_weights: Dict[str, float],
) -> List[SectorSuggestion]:
    """
    Generates sector gap suggestions with top stock picks.
    """
    gap_sectors = detect_missing_sectors(sector_weights)
    suggestions = []

    for sec in gap_sectors:
        current_w = sector_weights.get(sec, 0.0)
        if current_w == 0.0:
            reason = f"completely absent from your portfolio"
        else:
            reason = f"underweight at {round(current_w * 100, 1)}% (threshold {int(SECTOR_WEIGHT_THRESHOLD * 100)}%)"

        picks = top_picks_for_sector(sec, symbols)
        if picks:
            suggestions.append(SectorSuggestion(
                sector=sec,
                reason=reason,
                top_picks=picks,
            ))

    return suggestions
