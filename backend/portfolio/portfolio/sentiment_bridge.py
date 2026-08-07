# backend/portfolio/sentiment_bridge.py
"""
Bridges Pillar 1b sentiment scores into the optimizer.
Replicates the same call chain as sentiment/routes.py GET /sentiment/ticker/{symbol}.
Falls back to 0.0 (neutral) for any symbol that fails — intentional by design.
"""
import numpy as np
from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

ALPHA = 0.05  # max 5% nudge on |mu| per unit sentiment score


def get_sentiment_scores(symbols: List[str]) -> Dict[str, float]:
    """
    Fetch sentiment scores for each symbol by running the full Pillar 1b pipeline.
    Replicates: context → fetch_all_news → fetch_institutional_signal → compute_final_score
    Returns {symbol: sentiment_score} in range [-1, 1].
    Falls back to 0.0 (neutral) on any error.
    """
    scores: Dict[str, float] = {}
    for symbol in symbols:
        try:
            from sentiment.context import build_context_web
            from sentiment.fetcher import fetch_all_news
            from sentiment.aggregator import fetch_institutional_signal, compute_final_score

            web = build_context_web(symbol)
            news = fetch_all_news(
                symbol=web["symbol"],
                company_name=web["company_name"],
                sector=web["sector"],
                peers=web["peers"],
                complements=web["complements"],
            )
            inst = fetch_institutional_signal(symbol)
            result = compute_final_score(news, inst, veblen=web.get("veblen", False))
            scores[symbol] = float(result.get("sentiment_score", 0.0))

        except Exception as e:
            logger.warning(f"Sentiment fetch failed for {symbol}: {e} — using neutral 0.0")
            scores[symbol] = 0.0

    return scores


def apply_sentiment_modifier(
    mu: np.ndarray,
    symbols: List[str],
    sentiment_scores: Dict[str, float],
    alpha: float = ALPHA,
) -> np.ndarray:
    """
    mu_adj[i] = mu[i] + alpha * sentiment_score[i] * |mu[i]|
    Keeps sentiment as a small directional nudge, never overrides historical returns.
    """
    mu_adj = mu.copy()
    for i, sym in enumerate(symbols):
        score = sentiment_scores.get(sym, 0.0)
        mu_adj[i] = mu[i] + alpha * score * abs(mu[i])
    return mu_adj
