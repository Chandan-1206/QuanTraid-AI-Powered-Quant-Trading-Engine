import numpy as np
import pandas as pd
from scipy.optimize import minimize
from typing import List, Dict

def optimize_allocation(expected_returns: pd.Series, cov_matrix: pd.DataFrame) -> List[Dict[str, float]]:
    """
    Markowitz Optimization to Maximize Sharpe Ratio.
    Assumes risk-free rate = 0.05 (5%)
    """
    num_assets = len(expected_returns)
    risk_free_rate = 0.05
    
    returns_arr = expected_returns.values
    cov_arr = cov_matrix.values
    
    def negative_sharpe(weights):
        portfolio_return = np.sum(returns_arr * weights)
        portfolio_volatility = np.sqrt(np.dot(weights.T, np.dot(cov_arr, weights)))
        sharpe = (portfolio_return - risk_free_rate) / (portfolio_volatility + 1e-6)
        return -sharpe
        
    # Constraints: weights sum to 1
    constraints = ({'type': 'eq', 'fun': lambda w: np.sum(w) - 1})
    # Bounds: weights between 0 and 1 (long only)
    bounds = tuple((0.0, 1.0) for _ in range(num_assets))
    # Initial guess: equal weight
    init_guess = num_assets * [1. / num_assets,]
    
    optimized = minimize(negative_sharpe, init_guess, method='SLSQP', bounds=bounds, constraints=constraints)
    
    optimized_weights = []
    for i, stock in enumerate(expected_returns.index):
        # Round to 4 decimal places
        weight = round(optimized.x[i], 4)
        if weight > 0:
            optimized_weights.append({
                "stock": stock,
                "weight": weight
            })
            
    # Sort by weight descending
    optimized_weights.sort(key=lambda x: x["weight"], reverse=True)
    return optimized_weights
