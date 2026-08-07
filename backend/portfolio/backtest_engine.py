def backtest(predictions: list, actual_prices: list) -> dict:
    if len(predictions) < 2 or len(actual_prices) < 2:
        return {"direction_accuracy": 0.0, "model_reliability": "UNKNOWN"}
        
    correct = 0
    n = min(len(predictions), len(actual_prices))
    
    for i in range(n - 1):
        pred_dir = predictions[i+1] > predictions[i]
        actual_dir = actual_prices[i+1] > actual_prices[i]
        
        if pred_dir == actual_dir:
            correct += 1
            
    accuracy = correct / (n - 1)
    
    reliability = "POOR"
    if accuracy >= 0.60:
        reliability = "GOOD"
    if accuracy >= 0.70:
        reliability = "EXCELLENT"
        
    return {
        "direction_accuracy": round(accuracy, 2),
        "model_reliability": reliability
    }
