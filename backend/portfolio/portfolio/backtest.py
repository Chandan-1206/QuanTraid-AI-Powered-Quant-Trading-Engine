# backend/portfolio/backtest.py
"""
Simple 6-month historical simulation.
Compares current portfolio weights vs optimised weights
using actual past price data from yfinance.
"""
import numpy as np
import pandas as pd
from typing import List
from .schemas import BacktestResult

RISK_FREE_RATE = 0.065
TRADING_DAYS = 252


def simulate_portfolio_return(
    weights: np.ndarray, returns: pd.DataFrame
) -> float:
    """
    Compute total return of a static-weight portfolio over the returns period.
    Assumes daily rebalancing (log returns).
    """
    portfolio_returns = returns.values @ weights
    total_return = float(np.exp(np.sum(portfolio_returns)) - 1)
    return round(total_return, 4)


def simulate_sharpe(weights: np.ndarray, returns: pd.DataFrame) -> float:
    """Annualised Sharpe of a static-weight portfolio over returns period."""
    portfolio_returns = returns.values @ weights
    mean_daily = np.mean(portfolio_returns)
    std_daily = np.std(portfolio_returns)
    if std_daily == 0:
        return 0.0
    sharpe = (mean_daily * TRADING_DAYS - RISK_FREE_RATE) / (std_daily * np.sqrt(TRADING_DAYS))
    return round(float(sharpe), 4)


def run_backtest(
    current_weights: np.ndarray,
    optimised_weights: np.ndarray,
    returns: pd.DataFrame,
    period_months: int = 6,
) -> BacktestResult:
    """
    Slices the last `period_months` of returns data and simulates both portfolios.
    """
    trading_days_period = int(period_months * 21)  # ~21 trading days per month
    recent_returns = returns.iloc[-trading_days_period:]

    if len(recent_returns) < 20:
        # Not enough data — return neutral result
        return BacktestResult(
            period=f"{period_months} months",
            current_portfolio_return=0.0,
            optimised_portfolio_return=0.0,
            current_sharpe=0.0,
            optimised_sharpe=0.0,
        )

    curr_return = simulate_portfolio_return(current_weights, recent_returns)
    opt_return = simulate_portfolio_return(optimised_weights, recent_returns)
    curr_sharpe = simulate_sharpe(current_weights, recent_returns)
    opt_sharpe = simulate_sharpe(optimised_weights, recent_returns)

    return BacktestResult(
        period=f"{period_months} months",
        current_portfolio_return=curr_return,
        optimised_portfolio_return=opt_return,
        current_sharpe=curr_sharpe,
        optimised_sharpe=opt_sharpe,
    )
