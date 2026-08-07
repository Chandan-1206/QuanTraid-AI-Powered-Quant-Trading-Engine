# backend/portfolio/routes.py
from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timezone
from typing import List
import numpy as np

from core.firebase import verify_firebase_token
from .schemas import (
    HoldingsSaveRequest, AnalyseRequest, OptimiseRequest,
    OptimisationResult, WeightDetail, RebalancingItem,
)
from . import data as data_module
from . import health as health_module
from . import optimizer as optimizer_module
from . import recommender as recommender_module
from . import backtest as backtest_module
from . import firestore as fs
from .sentiment_bridge import get_sentiment_scores, apply_sentiment_modifier

router = APIRouter(prefix="/portfolio", tags=["portfolio"])


# ── 1. Save holdings ──────────────────────────────────────────────────────────

@router.post("/holdings", status_code=200)
async def save_holdings(
    body: HoldingsSaveRequest,
    user=Depends(verify_firebase_token),
):
    holdings_dicts = [h.model_dump() for h in body.holdings]
    fs.save_portfolio(user, holdings_dicts)
    return {"message": "Holdings saved.", "count": len(holdings_dicts)}


# ── 2. Get holdings ───────────────────────────────────────────────────────────

@router.get("/holdings", status_code=200)
async def get_holdings(user=Depends(verify_firebase_token)):
    holdings = fs.get_portfolio(user)
    if holdings is None:
        return {"holdings": []}
    return {"holdings": holdings}


# ── 3. Analyse (health only) ──────────────────────────────────────────────────

@router.post("/analyse", status_code=200)
async def analyse_portfolio(
    body: AnalyseRequest,
    user=Depends(verify_firebase_token),
):
    holdings = body.holdings
    if not holdings:
        stored = fs.get_portfolio(user)
        if not stored:
            raise HTTPException(400, "No holdings provided and none found in Firestore.")
        from .schemas import HoldingInput
        holdings = [HoldingInput(**h) for h in stored]

    if len(holdings) < 2:
        raise HTTPException(400, "Need at least 2 stocks to analyse a portfolio.")

    symbols = [h.symbol.upper() for h in holdings]
    bad = data_module.validate_symbols(symbols)
    if bad:
        raise HTTPException(422, f"Invalid or unlisted NSE symbols: {bad}")

    prices = data_module.fetch_price_history(symbols)
    valid_symbols = list(prices.columns)
    returns = data_module.compute_log_returns(prices)
    weights, total_value = data_module.current_weights(holdings, prices)
    mu, Sigma, cols = data_module.annualise_stats(returns)

    current_stats = optimizer_module.current_portfolio_stats(weights, mu, Sigma)
    health = health_module.analyse_health(valid_symbols, weights, returns)

    return {
        "symbols": valid_symbols,
        "portfolio_value_inr": round(total_value, 2),
        "health": health,
        "current_stats": current_stats,
        "as_of": datetime.now(timezone.utc).isoformat(),
    }


# ── 4. Optimise ───────────────────────────────────────────────────────────────

@router.post("/optimise", status_code=200, response_model=OptimisationResult)
async def optimise_portfolio(
    body: OptimiseRequest,
    user=Depends(verify_firebase_token),
):
    # --- Load holdings ---
    holdings = body.holdings
    if not holdings:
        stored = fs.get_portfolio(user)
        if not stored:
            raise HTTPException(400, "No holdings provided and none found in Firestore.")
        from .schemas import HoldingInput
        holdings = [HoldingInput(**h) for h in stored]

    if len(holdings) < 2:
        raise HTTPException(400, "Need at least 2 stocks to optimise.")

    # Mode B: add synthetic holding for new capital split evenly if needed
    # (new capital is handled by increasing portfolio_value, weights will naturally shift)
    symbols = [h.symbol.upper() for h in holdings]
    bad = data_module.validate_symbols(symbols)
    if bad:
        raise HTTPException(422, f"Invalid or unlisted NSE symbols: {bad}")

    # --- Fetch data ---
    prices = data_module.fetch_price_history(symbols)
    valid_symbols = list(prices.columns)
    returns = data_module.compute_log_returns(prices)
    mu, Sigma, cols = data_module.annualise_stats(returns)
    current_w, total_value = data_module.current_weights(holdings, prices)

    # Mode B: scale total value
    if body.mode == "B" and body.new_capital_inr:
        total_value += body.new_capital_inr

    # --- Sentiment modifier ---
    sentiment_scores = get_sentiment_scores(valid_symbols)
    mu_adj = apply_sentiment_modifier(mu, valid_symbols, sentiment_scores)

    # --- Current stats ---
    current_stats = optimizer_module.current_portfolio_stats(current_w, mu, Sigma)

    # --- Optimise ---
    opt_weights, opt_stats = optimizer_module.maximise_sharpe(
        mu_adj, Sigma, current_w, turnover_limit=body.turnover_limit
    )

    # --- Health ---
    health = health_module.analyse_health(valid_symbols, current_w, returns)

    # --- Weight details ---
    weight_details = []
    for i, sym in enumerate(valid_symbols):
        cw = float(current_w[i])
        ow = float(opt_weights[i])
        diff = ow - cw
        action = "increase" if diff > 0.01 else "reduce" if diff < -0.01 else "hold"
        weight_details.append(WeightDetail(
            symbol=sym,
            current_weight=round(cw, 4),
            optimised_weight=round(ow, 4),
            action=action,
        ))

    # --- Rebalancing ---
    rebalancing = []
    for i, sym in enumerate(valid_symbols):
        change_pct = round((float(opt_weights[i]) - float(current_w[i])) * 100, 2)
        change_inr = round(change_pct / 100 * total_value, 2)
        if abs(change_pct) >= 0.5:
            rebalancing.append(RebalancingItem(
                symbol=sym,
                change_pct=change_pct,
                change_inr=change_inr,
            ))

    # --- Sector suggestions ---
    sector_weights = health_module.sector_breakdown(valid_symbols, current_w)
    suggestions = recommender_module.generate_suggestions(valid_symbols, current_w, sector_weights)

    # --- Backtest ---
    backtest = backtest_module.run_backtest(current_w, opt_weights, returns, period_months=6)

    # --- Save to Firestore ---
    result_dict = {
        "sharpe_before": current_stats.sharpe_ratio,
        "sharpe_after": opt_stats.sharpe_ratio,
        "optimised_weights": {sym: round(float(opt_weights[i]), 4) for i, sym in enumerate(valid_symbols)},
    }
    fs.save_optimisation_result(user, result_dict)

    return OptimisationResult(
        ticker_count=len(valid_symbols),
        portfolio_value_inr=round(total_value, 2),
        health=health,
        current=current_stats,
        optimised=opt_stats,
        weights=weight_details,
        rebalancing=rebalancing,
        sector_suggestions=suggestions,
        backtest=backtest,
        sentiment_modifiers_applied={sym: round(sentiment_scores.get(sym, 0.0), 4) for sym in valid_symbols},
        as_of=datetime.now(timezone.utc).isoformat(),
    )


# ── 5. Optimisation history ───────────────────────────────────────────────────

@router.get("/history", status_code=200)
async def get_history(user=Depends(verify_firebase_token)):
    history = fs.get_optimisation_history(user)
    return {"history": history}


# ── 6. Delete holdings ────────────────────────────────────────────────────────

@router.delete("/holdings", status_code=200)
async def delete_holdings(user=Depends(verify_firebase_token)):
    fs.delete_portfolio(user)
    return {"message": "Holdings deleted."}
