from typing import List, Dict

SECTOR_MAP = {
    "IT": ["TCS", "INFY", "WIPRO", "HCLTECH", "TECHM", "LTIM", "PERSISTENT", "MPHASIS"],
    "Energy": ["RELIANCE", "ONGC", "BPCL", "POWERGRID", "NTPC", "TATAPOWER"],
    "Banking": ["HDFCBANK", "ICICIBANK", "SBIN", "KOTAKBANK", "AXISBANK", "INDUSINDBK"],
    "Pharma": ["SUNPHARMA", "DRREDDY", "CIPLA", "DIVISLAB", "LUPIN"],
    "Metals": ["TATASTEEL", "HINDALCO", "JSWSTEEL", "COALINDIA", "VEDL"],
    "Auto": ["MARUTI", "TATAMOTORS", "M&M", "BAJAJ-AUTO", "EICHERMOT"],
    "FMCG": ["HINDUNILVR", "ITC", "NESTLEIND", "BRITANNIA", "DABUR"],
    "Consumer": ["TITAN", "ASIANPAINT", "PIDILITIND", "HAVELLS"],
    "Infra": ["LT", "ULTRACEMCO", "ADANIPORTS", "SIEMENS"],
    "NBFC": ["BAJFINANCE", "BAJAJFINSV", "CHOLAFIN"]
}

def get_sector(stock: str) -> str:
    stock_clean = stock.replace(".NS", "")
    for sector, stocks in SECTOR_MAP.items():
        if stock_clean in stocks:
            return sector
    return "Other"

class PortfolioAnalyzer:
    def __init__(self, portfolio: List[Dict[str, float]], total_budget: float = 0.0):
        """
        portfolio: list of dicts with 'stock' and 'amount'
        """
        self.portfolio = portfolio
        self.total_value = sum(item["amount"] for item in portfolio) if portfolio else 0
            
    def analyze(self) -> Dict:
        if not self.portfolio or self.total_value == 0:
            return {"status": "NO_PORTFOLIO", "weights": {}, "sector_exposure": {}, "unique_sectors": 0}
            
        weights = {}
        sectors = {}
        
        for item in self.portfolio:
            stock = item["stock"]
            weight = item["amount"] / self.total_value
            weights[stock] = weight
            
            sector = get_sector(stock)
            sectors[sector] = sectors.get(sector, 0.0) + weight
            
        status = "BALANCED"
        
        # Check concentration
        for stock, w in weights.items():
            if w > 0.50:
                status = "OVER_CONCENTRATED"
                break
                
        # Check diversification
        if status != "OVER_CONCENTRATED":
            if len(sectors) < 3:
                status = "UNDER_DIVERSIFIED"
                
        return {
            "status": status,
            "weights": weights,
            "sector_exposure": sectors,
            "unique_sectors": len(sectors)
        }
        
    def get_sector_exposure(self, stock: str) -> float:
        sector = get_sector(stock)
        return self.analyze()["sector_exposure"].get(sector, 0.0)
        
    def is_high_risk(self, risk_value: float = None) -> bool:
        # High risk threshold: annualized volatility > 25%
        if risk_value is not None:
            return risk_value > 0.25
        return False
