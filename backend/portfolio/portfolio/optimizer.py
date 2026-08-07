# backend/portfolio/optimizer.py
import numpy as np
from scipy.optimize import minimize
from typing import Tuple, List, Optional
from .schemas import PortfolioStats


RISK_FREE_RATE = 0.065   # India 10Y approximate
MAX_SINGLE_WEIGHT = 0.40  # no single stock > 40%


def _portfolio_stats(weights: np.ndarray, mu: np.ndarray, Sigma: np.ndarray) -> Tuple[float, float, float]:
    """Returns (expected_return, volatility, sharpe)."""
    ret = float(weights @ mu)
    vol = float(np.sqrt(weights @ Sigma @ weights))
    sharpe = (ret - RISK_FREE_RATE) / vol if vol > 0 else 0.0
    return ret, vol, sharpe


def _neg_sharpe(weights: np.ndarray, mu: np.ndarray, Sigma: np.ndarray) -> float:
    _, _, sharpe = _portfolio_stats(weights, mu, Sigma)
    return -sharpe


def maximise_sharpe(
    mu: np.ndarray,
    Sigma: np.ndarray,
    current_weights: np.ndarray,
    turnover_limit: float = 0.3,
) -> Tuple[np.ndarray, PortfolioStats]:
    """
    Maximise Sharpe ratio subject to:
      - weights sum to 1
      - long-only (weights >= 0)
      - max single weight 40%
      - L1 turnover constraint: ||w_new - w_curr||_1 <= turnover_limit
    """
    n = len(mu)
    w0 = current_weights.copy()

    constraints = [
        {"type": "eq", "fun": lambda w: np.sum(w) - 1.0},
        {
            "type": "ineq",
            "fun": lambda w: turnover_limit - np.sum(np.abs(w - w0)),
        },
    ]

    bounds = [(0.0, MAX_SINGLE_WEIGHT)] * n

    result = minimize(
        _neg_sharpe,
        w0,
        args=(mu, Sigma),
        method="SLSQP",
        bounds=bounds,
        constraints=constraints,
        options={"ftol": 1e-9, "maxiter": 1000},
    )

    if not result.success:
        # Fallback: relax turnover constraint and retry
        constraints_relaxed = [{"type": "eq", "fun": lambda w: np.sum(w) - 1.0}]
        result = minimize(
            _neg_sharpe,
            w0,
            args=(mu, Sigma),
            method="SLSQP",
            bounds=bounds,
            constraints=constraints_relaxed,
            options={"ftol": 1e-9, "maxiter": 1000},
        )

    opt_w = np.clip(result.x, 0.0, MAX_SINGLE_WEIGHT)
    opt_w = opt_w / opt_w.sum()

    ret, vol, sharpe = _portfolio_stats(opt_w, mu, Sigma)
    stats = PortfolioStats(
        expected_annual_return=round(ret, 4),
        annual_volatility=round(vol, 4),
        sharpe_ratio=round(sharpe, 4),
    )
    return opt_w, stats


def current_portfolio_stats(
    weights: np.ndarray, mu: np.ndarray, Sigma: np.ndarray
) -> PortfolioStats:
    ret, vol, sharpe = _portfolio_stats(weights, mu, Sigma)
    return PortfolioStats(
        expected_annual_return=round(ret, 4),
        annual_volatility=round(vol, 4),
        sharpe_ratio=round(sharpe, 4),
    )


def compute_efficient_frontier(
    mu: np.ndarray, Sigma: np.ndarray, n_points: int = 40
) -> List[dict]:
    """
    Returns list of {volatility, return} dicts tracing the efficient frontier.
    Uses target-return sweep via constrained minimisation.
    """
    n = len(mu)
    bounds = [(0.0, MAX_SINGLE_WEIGHT)] * n
    target_returns = np.linspace(mu.min(), mu.max(), n_points)
    frontier = []

    for target in target_returns:
        constraints = [
            {"type": "eq", "fun": lambda w: np.sum(w) - 1.0},
            {"type": "eq", "fun": lambda w, t=target: w @ mu - t},
        ]
        w0 = np.ones(n) / n
        result = minimize(
            lambda w: float(np.sqrt(w @ Sigma @ w)),
            w0,
            method="SLSQP",
            bounds=bounds,
            constraints=constraints,
            options={"ftol": 1e-9, "maxiter": 500},
        )
        if result.success:
            vol = float(np.sqrt(result.x @ Sigma @ result.x))
            frontier.append({"volatility": round(vol, 4), "return": round(float(target), 4)})

    return frontier
