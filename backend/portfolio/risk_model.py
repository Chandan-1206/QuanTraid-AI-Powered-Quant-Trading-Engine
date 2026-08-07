import numpy as np
import pandas as pd

def calculate_expected_returns(prices_df: pd.DataFrame) -> pd.Series:
    """Calculates annualized expected returns from daily prices."""
    daily_returns = prices_df.pct_change().dropna()
    expected_returns = daily_returns.mean() * 252
    return expected_returns

def calculate_volatility(prices_df: pd.DataFrame) -> pd.Series:
    """Calculates annualized volatility (risk) from daily prices."""
    daily_returns = prices_df.pct_change().dropna()
    volatility = daily_returns.std() * np.sqrt(252)
    return volatility

def calculate_covariance_matrix(prices_df: pd.DataFrame) -> pd.DataFrame:
    """Calculates annualized covariance matrix."""
    daily_returns = prices_df.pct_change().dropna()
    cov_matrix = daily_returns.cov() * 252
    return cov_matrix
