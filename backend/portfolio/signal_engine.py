def portfolio_adjusted_signal(signal: str, stock: str, analyzer, portfolio_risk: float = None) -> str:
    sector_exposure = analyzer.get_sector_exposure(stock)
    
    if signal in ["BUY", "STRONG BUY"]:
        if sector_exposure > 0.4:
            return "HOLD (Overexposed Sector)"
        elif analyzer.is_high_risk(portfolio_risk):
            return "BUY (High Risk)"
            
    return signal

def generate_explanation(signal: str, return_pct: float, confidence: float, trend: str) -> str:
    if signal in ["STRONG BUY", "BUY (High Risk)"]:
        return f"Stock shows {trend.lower()} trend with {round(return_pct*100, 2)}% expected return and high confidence."
    elif signal in ["SELL", "STRONG SELL"]:
        return f"Negative trend detected. Risk of price drop with low confidence."
    else:
        if "Overexposed" in signal:
            return f"Hold position. Adding more would overexpose your portfolio to this sector."
        return f"Uncertain movement. Market is sideways."
