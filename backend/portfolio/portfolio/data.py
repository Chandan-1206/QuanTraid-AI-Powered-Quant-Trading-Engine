# backend/portfolio/data.py
import yfinance as yf
import pandas as pd
import numpy as np
from typing import List, Tuple, Dict


TRADING_DAYS = 252


def _nse(symbol: str) -> str:
    """Append .NS suffix for NSE tickers if not already present."""
    s = symbol.upper().strip()
    return s if s.endswith(".NS") else f"{s}.NS"


def fetch_price_history(symbols: List[str], period: str = "2y") -> pd.DataFrame:
    """
    Fetch adjusted close prices for given NSE symbols.
    Returns DataFrame with symbol (without .NS) as column names.
    Drops any symbol that returns no data.
    """
    tickers = [_nse(s) for s in symbols]
    raw = yf.download(tickers, period=period, auto_adjust=True, progress=False)

    if isinstance(raw.columns, pd.MultiIndex):
        prices = raw["Close"]
    else:
        prices = raw[["Close"]]
        prices.columns = tickers

    prices.columns = [c.replace(".NS", "") for c in prices.columns]
    prices = prices.dropna(axis=1, how="all")
    prices = prices.ffill().dropna()
    return prices


def compute_log_returns(prices: pd.DataFrame) -> pd.DataFrame:
    """Daily log returns."""
    return np.log(prices / prices.shift(1)).dropna()


def annualise_stats(returns: pd.DataFrame) -> Tuple[np.ndarray, np.ndarray, List[str]]:
    """
    Returns:
        mu    — annualised mean return vector (n,)
        Sigma — annualised covariance matrix (n x n)
        cols  — list of symbol names matching vector order
    """
    mu = returns.mean().values * TRADING_DAYS
    Sigma = returns.cov().values * TRADING_DAYS
    cols = list(returns.columns)
    return mu, Sigma, cols


def current_weights(holdings, prices: pd.DataFrame) -> Tuple[np.ndarray, float]:
    """
    Compute market-value weights from holdings.
    holdings: list of HoldingInput objects
    Returns weight vector aligned to prices.columns and total portfolio value.
    """
    symbols = list(prices.columns)
    last_prices: Dict[str, float] = prices.iloc[-1].to_dict()

    values = np.zeros(len(symbols))
    for h in holdings:
        sym = h.symbol.upper()
        if sym in last_prices:
            values[symbols.index(sym)] = h.quantity * last_prices[sym]

    total = values.sum()
    if total == 0:
        raise ValueError("Portfolio value is zero — check symbols and quantities.")
    return values / total, total


def validate_symbols(symbols: List[str]) -> List[str]:
    """
    Returns list of symbols that failed to download any data.
    """
    prices = fetch_price_history(symbols, period="1mo")
    valid = set(prices.columns)
    return [s for s in symbols if s.upper() not in valid]
