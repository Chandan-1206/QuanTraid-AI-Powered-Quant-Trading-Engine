# QuanTraid Project Reading Material

This document explains how the whole project works, with special focus on Model 1A and the TFT short-term forecast path.

## 1. Project in One Line

QuanTraid is a Flutter mobile/web application backed by a Python FastAPI server. The user selects or enters stocks, the backend fetches market data from Yahoo Finance, runs prediction/risk/portfolio logic, and the Flutter app displays signals, charts, confidence, portfolio health, and recommendations.

## 2. Main Technology Stack

Frontend:

- Flutter / Dart
- `http` for API calls
- `provider` for theme/app state
- `fl_chart` for charts
- `intl` for date formatting

Backend:

- FastAPI
- Pydantic request validation
- yfinance market data
- pandas / numpy data processing
- PyTorch Forecasting / Torch for the saved TFT checkpoint
- scipy optimizer for portfolio allocation

Important backend files:

- `backend/main.py`: FastAPI app and `/predict` endpoint
- `backend/model_1a.py`: Model 1A short-term TFT path and long-term forecast path
- `backend/model_1b.py`: Heuristic trend, momentum, and risk model
- `backend/portfolio/*`: portfolio analysis and optimization system
- `ML_data/tft_nifty50.ckpt`: saved TFT checkpoint

Important frontend files:

- `lib/main.dart`: Flutter app entry point
- `lib/navigation/main_navigation.dart`: bottom navigation tabs
- `lib/data/api_service.dart`: backend API calls
- `lib/models/prediction_model.dart`: Dart models for backend response
- `lib/screens/advisor/home_screen.dart`: stock selection screen
- `lib/screens/advisor/loading_screen.dart`: calls backend while showing loading UI
- `lib/screens/advisor/result_screen.dart`: renders prediction output and charts
- `lib/screens/portfolio/*`: portfolio UI

## 3. High-Level System Flow

The main AI stock analyzer flow is:

1. User opens the app.
2. User selects a stock and duration in the advisor screen.
3. Flutter sends a POST request to the FastAPI backend at `/predict`.
4. Backend downloads last 6 months of daily price data using yfinance.
5. Backend cleans and formats the data.
6. Backend runs Model 1A:
   - short-term TFT forecast path
   - long-term simulated forecast path
7. Backend runs Model 1B:
   - volatility
   - RSI momentum
   - moving-average trend
8. Backend combines Model 1A and Model 1B into a final signal.
9. Backend returns JSON.
10. Flutter parses the JSON into Dart model classes.
11. Result screen shows final signal, explanation, price chart, top opportunities, Monday strategy, cumulative return, volatility profile, and signal heatmap.

## 4. Backend Entry Point: `backend/main.py`

The backend creates a FastAPI application:

```python
app = FastAPI(title="AI Investment Advisor Backend - Multi-Model Edition")
```

It enables CORS so Flutter can call the backend from web, Android emulator, or desktop:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

It imports the model functions:

```python
from model_1a import run_long_term_model, run_tft_short_term
from model_1b import run_model_1b
```

It also includes the portfolio router:

```python
app.include_router(portfolio_router)
```

That means the same server handles both:

- `/predict`
- `/portfolio/analyze`

## 5. `/predict` Endpoint Flow

The request body is defined by:

```python
class PredictionRequest(BaseModel):
    stock: str
    duration: str
```

Example request from Flutter:

```json
{
  "stock": "RELIANCE.NS",
  "duration": "3months"
}
```

The endpoint starts here:

```python
@app.post("/predict")
def predict_stock(req: PredictionRequest):
```

### Step 1: Read Stock Symbol

```python
stock_ticker = req.stock
```

If the user selected `RELIANCE.NS`, the backend uses that as the Yahoo Finance ticker.

### Step 2: Download Market Data

```python
df = yf.download(stock_ticker, period="6mo", interval="1d")
```

This fetches 6 months of daily OHLCV stock data.

Typical columns from yfinance:

- Date
- Open
- High
- Low
- Close
- Adj Close
- Volume

The code mainly uses `Date` and `Close`.

### Step 3: Clean the Data

```python
if isinstance(df.columns, pd.MultiIndex):
    df.columns = df.columns.get_level_values(0)

df = df.reset_index()
df['Date'] = pd.to_datetime(df['Date']).dt.tz_localize(None)
df.sort_values('Date', inplace=True)
df.dropna(subset=['Close'], inplace=True)
```

This does four important things:

- Flattens yfinance multi-index columns when needed.
- Converts the index into a normal `Date` column.
- Removes timezone information.
- Sorts rows by date.
- Removes rows without closing price.

### Step 4: Get Current Price

```python
current_price = float(df['Close'].iloc[-1])
```

The latest closing price becomes the base price for prediction.

### Step 5: Run Model 1A

```python
out_long_term = run_long_term_model(stock_ticker, current_price, df)
out_tft = run_tft_short_term(stock_ticker, current_price, df)
```

Model 1A has two outputs:

- Long-term predictions: 1M, 3M, 6M
- Short-term TFT-style predictions: about 30 calendar days, skipping weekends

### Step 6: Extract Monday Predictions

```python
for p in out_tft["predictions"]:
    dt = datetime.strptime(p["date"], "%Y-%m-%d")
    if dt.weekday() == 0:
        p["priority"] = True if p["confidence"] > 0.75 else False
        monday_predictions.append(p)
```

Monday is weekday `0` in Python.

The app uses this for the "Monday Strategy" section.

### Step 7: Extract Top Opportunities

```python
sorted_short_term = sorted(out_tft["predictions"], key=lambda x: x.get("score", 0), reverse=True)
top_opportunities = sorted_short_term[:5]
```

Each short-term prediction has a `score`. The backend sorts all forecast points and sends the best 5.

### Step 8: Run Model 1B

```python
out_1b = run_model_1b(df)
```

Model 1B is not deep learning. It is a technical-analysis heuristic model.

It returns:

- trend: `BULLISH`, `BEARISH`, or `NEUTRAL`
- risk_level: `LOW`, `MEDIUM`, or `HIGH`
- momentum_score
- volatility_score
- strength

### Step 9: Final Decision Engine

The backend takes:

```python
m1a_signal = out_tft['base_signal']
m1a_conf = out_tft['confidence']
trend = out_1b['trend']
risk = out_1b['risk_level']
```

Then it decides:

- If Model 1A says BUY, and Model 1B says bullish plus low risk, final signal becomes `STRONG BUY`.
- If Model 1A says BUY but not all supporting indicators agree, final signal becomes `BUY`.
- If Model 1A says SELL and trend is bearish, final signal becomes `STRONG SELL`.
- If Model 1A says SELL without bearish confirmation, final signal becomes `SELL`.
- Otherwise final signal remains `HOLD`.

This is the fusion layer. Model 1A predicts direction. Model 1B checks market condition and risk.

### Step 10: Explanation Engine

The backend creates a human-readable explanation:

```python
explanation = f"Trend is {trend.lower()} with {risk.lower()} risk profile. "
```

Then it appends text based on Model 1A and final signal.

This is what appears in the app under "Intelligent Synthesis".

### Step 11: Response JSON

The backend returns:

```python
{
    "stock": stock_ticker,
    "current_price": round(current_price, 2),
    "final_signal": final_signal,
    "confidence": m1a_conf,
    "risk_level": risk,
    "trend": trend,
    "explanation": explanation,
    "short_term_predictions": out_tft["predictions"],
    "monday_predictions": monday_predictions,
    "top_opportunities": top_opportunities,
    "long_term_predictions": out_long_term,
    "model_1a": {
        "base_signal": m1a_signal
    },
    "model_1b": {
        "momentum_score": out_1b["momentum_score"],
        "volatility_score": out_1b["volatility_score"],
        "strength": out_1b["strength"]
    }
}
```

`clean_nan()` replaces invalid `NaN` values with `None`, because JSON cannot safely represent `NaN`.

## 6. Model 1A Overview

Model 1A lives in:

```text
backend/model_1a.py
```

It has two functions:

```python
run_long_term_model(...)
run_tft_short_term(...)
```

### 6.1 Long-Term Model

Function:

```python
def run_long_term_model(stock_ticker: str, current_price: float, df: pd.DataFrame):
```

Purpose:

- Generate 1-month, 3-month, and 6-month future predictions.
- Produce price, upper/lower bounds, signal, confidence, volatility, trend strength, and cumulative return.

Important note:

The long-term function is simulation-based. It does not use the TFT checkpoint. It creates future movement using random noise and a randomly selected overall trend.

```python
overall_trend = random.choice([0.001, -0.001, 0.000])
noise = random.uniform(-0.015, 0.015)
base_price = base_price * (1 + overall_trend + noise)
```

Meaning:

- `overall_trend = 0.001`: slight upward bias
- `overall_trend = -0.001`: slight downward bias
- `overall_trend = 0.000`: flat bias
- `noise`: random daily market movement

The model skips weekends:

```python
if future_date.weekday() >= 5:
    continue
```

Python weekdays:

- Monday = 0
- Tuesday = 1
- Wednesday = 2
- Thursday = 3
- Friday = 4
- Saturday = 5
- Sunday = 6

So `>= 5` skips Saturday and Sunday.

The model creates a signal:

```python
if (base_price - current_price) / current_price > 0.05:
    signal = "BUY"
elif (current_price - base_price) / current_price > 0.05:
    signal = "SELL"
else:
    signal = "HOLD"
```

Meaning:

- More than +5 percent from current price: BUY
- More than -5 percent from current price: SELL
- Otherwise: HOLD

It fills three arrays:

```python
if i <= 30:
    predictions_1m.append(point)
if i <= 90:
    predictions_3m.append(point)
predictions_6m.append(point)
```

So:

- `1M`: first 30 calendar days, weekends skipped
- `3M`: first 90 calendar days, weekends skipped
- `6M`: all generated points up to 180 calendar days, weekends skipped

### 6.2 TFT Short-Term Model

Function:

```python
def run_tft_short_term(stock_ticker: str, current_price: float, df: pd.DataFrame):
```

Purpose:

- Load the saved Temporal Fusion Transformer checkpoint.
- Generate short-term forecast points.
- Calculate confidence, bounds, daily signals, opportunity score, and base signal.

The checkpoint path is:

```python
ckpt_path = "D:/MAJOR_2_DEMO/ML_data/tft_nifty50.ckpt"
model = TemporalFusionTransformer.load_from_checkpoint(ckpt_path, map_location="cpu")
```

This line loads the saved TFT model into memory.

Important truth about the current implementation:

The code loads the TFT checkpoint, but it does not currently pass a prepared `TimeSeriesDataSet` or future dataframe into `model.predict()`. After loading the checkpoint, the forecast loop uses random noise:

```python
tft_noise = random.uniform(-0.012, 0.012)
base_price = base_price * (1 + tft_noise)
```

So, in the current project, the checkpoint loading verifies/uses the saved model object, but the generated forecast values are still synthetic. For a true TFT inference pipeline, the code would need to:

1. Recreate the same preprocessing used during training.
2. Build a prediction dataframe with encoder history and decoder future steps.
3. Create a `TimeSeriesDataSet` or dataloader.
4. Call `model.predict(...)`.
5. Convert model output tensors back into price values.

This distinction is very important if you explain the project academically.

## 7. What TFT Means Conceptually

TFT stands for Temporal Fusion Transformer.

It is a deep learning architecture for time-series forecasting. It is designed to handle:

- past observed values
- known future inputs
- static variables
- multiple time-varying features
- attention-based interpretability

In a stock forecasting project, a real TFT setup might use:

- close price
- open/high/low price
- volume
- technical indicators
- day of week
- time index
- stock symbol group id

The model tries to learn temporal patterns from historical sequences and output future values.

Core TFT ideas:

- LSTM layers process local temporal patterns.
- Attention helps the model focus on important time steps.
- Variable selection networks learn which features matter.
- Gating layers control information flow.
- Quantile outputs can produce prediction intervals.

In your current code, the architecture dependency exists through `pytorch_forecasting.TemporalFusionTransformer`, and the checkpoint file exists, but the app prediction loop does not yet use full tensor-based TFT prediction.

## 8. Model 1A Short-Term Prediction Logic in Detail

Inside `run_tft_short_term`, predictions start as an empty list:

```python
predictions = []
```

The last known market date is:

```python
last_date = df['Date'].iloc[-1] if not df.empty else datetime.now()
```

Then the model tries to load TFT:

```python
try:
    from pytorch_forecasting import TemporalFusionTransformer
    ckpt_path = "D:/MAJOR_2_DEMO/ML_data/tft_nifty50.ckpt"
    model = TemporalFusionTransformer.load_from_checkpoint(ckpt_path, map_location="cpu")
```

If this fails, the except block runs and uses fallback generation.

### 8.1 Forecast Loop

```python
for i in range(1, 30 + 1):
    future_date = last_date + timedelta(days=i)
    if future_date.weekday() >= 5:
        continue
```

This creates up to 30 calendar days and skips weekends.

### 8.2 Price Generation

```python
tft_noise = random.uniform(-0.012, 0.012)
base_price = base_price * (1 + tft_noise)
```

Meaning:

- Daily return is randomly selected between -1.2 percent and +1.2 percent.
- New price = previous generated price multiplied by that daily movement.

Example:

If current price is 1000 and `tft_noise = 0.01`:

```text
base_price = 1000 * 1.01 = 1010
```

If next noise is `-0.005`:

```text
base_price = 1010 * 0.995 = 1004.95
```

### 8.3 Upper and Lower Bounds

```python
conf_spread = random.uniform(0.01, 0.03)
upper_bound = base_price * (1 + conf_spread)
lower_bound = base_price * (1 - conf_spread)
```

The spread is between 1 percent and 3 percent.

If predicted price is 1000 and spread is 2 percent:

```text
upper_bound = 1020
lower_bound = 980
```

These bounds are shown in the chart as forecast range.

### 8.4 Confidence Calculation

```python
confidence = 1 - ((upper_bound - lower_bound) / base_price)
confidence = max(0, min(confidence, 1))
```

If the prediction range is narrow, confidence is higher.

Example:

```text
base_price = 1000
upper = 1020
lower = 980
range = 40
range / base = 0.04
confidence = 1 - 0.04 = 0.96
```

So narrower uncertainty range means more confidence.

### 8.5 Daily Trend Classification

```python
if len(predictions) > 0:
    prev_price = predictions[-1]['price']
    if base_price > prev_price > current_price:
        trend = "UPTREND"
    elif base_price < prev_price < current_price:
        trend = "DOWNTREND"
    else:
        trend = "SIDEWAYS"
else:
    trend = "SIDEWAYS"
```

This compares:

- current generated price
- previous generated price
- original current market price

It marks:

- `UPTREND`: generated prices are rising above current price
- `DOWNTREND`: generated prices are falling below current price
- `SIDEWAYS`: no clean direction

### 8.6 Price Change

```python
price_change = (base_price - current_price) / current_price
```

This is predicted return from current price.

Example:

```text
current_price = 1000
base_price = 1020
price_change = 20 / 1000 = 0.02 = 2 percent
```

### 8.7 Signal Rules

```python
if price_change > 0.015 and confidence > 0.75:
    signal = "STRONG BUY"
elif price_change > 0.007:
    signal = "BUY"
elif price_change < -0.015 and confidence > 0.75:
    signal = "STRONG SELL"
elif price_change < -0.007:
    signal = "SELL"
else:
    signal = "HOLD"
```

Meaning:

- More than +1.5 percent and confidence above 0.75: `STRONG BUY`
- More than +0.7 percent: `BUY`
- Less than -1.5 percent and confidence above 0.75: `STRONG SELL`
- Less than -0.7 percent: `SELL`
- Otherwise: `HOLD`

This is the short-term signal engine.

### 8.8 Opportunity Score

```python
score = (
    0.4 * confidence +
    0.4 * abs(price_change) +
    0.2 * (1 if trend == "UPTREND" else 0)
)
```

Score is used to rank top opportunities.

It gives weight to:

- 40 percent confidence
- 40 percent absolute expected movement
- 20 percent uptrend bonus

Important:

Because it uses `abs(price_change)`, both positive and negative movement can score highly. So "top opportunities" may include high-conviction sell-side moves too, depending on signal.

### 8.9 Prediction Point Structure

Each prediction contains:

```python
{
    "date": future_date.strftime("%Y-%m-%d"),
    "price": round(base_price, 2),
    "upper_bound": round(upper_bound, 2),
    "lower_bound": round(lower_bound, 2),
    "signal": signal,
    "confidence": round(confidence, 4),
    "advice": "TFT Short-Term Signal",
    "volatility": abs(tft_noise) * 100,
    "trend_strength": (base_price - current_price) / current_price * 100,
    "cumulative_return": ((base_price - current_price) / current_price) * 100,
    "predicted_return": round(price_change, 4),
    "score": round(score, 4),
    "daily_trend": trend
}
```

These fields directly power the frontend charts.

### 8.10 Fallback Path

If TFT loading fails:

```python
except Exception as e:
    print(f"TFT Inference Error: {e}. Falling back to standard generation.")
```

Then similar random generation is used, but advice becomes:

```python
"advice": "Fallback"
```

Fallback exists so the app still works even if:

- checkpoint path is wrong
- PyTorch Forecasting is not installed
- checkpoint cannot load
- model dependency versions mismatch

### 8.11 Base Signal

At the end:

```python
future_price = predictions[-1]['price']
price_change = (future_price - current_price) / current_price

base_signal = "HOLD"
if price_change > 0.02:
    base_signal = "BUY"
elif price_change < -0.02:
    base_signal = "SELL"
```

This looks at the final predicted price in the short-term list.

Rules:

- Final predicted gain above 2 percent: base signal `BUY`
- Final predicted loss below -2 percent: base signal `SELL`
- Otherwise: `HOLD`

This base signal is what `backend/main.py` uses for the final decision engine.

## 9. Model 1B: Trend, Risk, Momentum

Model 1B lives in:

```text
backend/model_1b.py
```

Function:

```python
def run_model_1b(df: pd.DataFrame):
```

It returns:

```python
{
    "trend": "...",
    "risk_level": "...",
    "momentum_score": ...,
    "volatility_score": ...,
    "strength": "..."
}
```

### 9.1 Empty Data Guard

```python
if df.empty or len(df) < 14:
    return neutral defaults
```

It needs at least 14 rows for RSI and volatility.

### 9.2 Volatility

```python
returns = closes.pct_change().dropna()
recent_returns = returns.tail(14)
daily_vol = recent_returns.std()
annualized_vol = daily_vol * np.sqrt(252)
```

Why `sqrt(252)`?

There are roughly 252 trading days in a year. Daily volatility is annualized by multiplying by square root of time.

Then:

```python
vol_score = min(max(annualized_vol / 0.5, 0.0), 1.0)
```

The code treats 50 percent annualized volatility as a rough maximum scale.

Risk levels:

```python
if vol_score < 0.2:
    risk_level = "LOW"
elif vol_score < 0.5:
    risk_level = "MEDIUM"
else:
    risk_level = "HIGH"
```

### 9.3 RSI Momentum

```python
delta = closes.diff()
gain = (delta.where(delta > 0, 0)).rolling(window=14).mean()
loss = (-delta.where(delta < 0, 0)).rolling(window=14).mean()
rs = gain / loss
rsi = 100 - (100 / (1 + rs))
current_rsi = rsi.iloc[-1]
```

RSI stands for Relative Strength Index.

Interpretation:

- RSI near 70: strong upward momentum, possibly overbought
- RSI near 30: weak/downward momentum, possibly oversold
- RSI near 50: neutral

The code normalizes RSI to 0 to 1:

```python
momentum_score = current_rsi / 100.0
```

### 9.4 Moving Average Trend

If there are at least 50 rows:

```python
ma20 = closes.rolling(window=20).mean().iloc[-1]
ma50 = closes.rolling(window=50).mean().iloc[-1]
current_price = closes.iloc[-1]
```

Trend rules:

```python
if current_price > ma20 and ma20 > ma50:
    trend = "BULLISH"
elif current_price < ma20 and ma20 < ma50:
    trend = "BEARISH"
else:
    trend = "NEUTRAL"
```

Meaning:

- Price above short average, short average above long average: bullish structure
- Price below short average, short average below long average: bearish structure
- Otherwise: mixed or neutral

### 9.5 Strength

```python
if trend != "NEUTRAL" and (momentum_score > 0.65 or momentum_score < 0.35):
    strength = "STRONG"
elif trend != "NEUTRAL":
    strength = "MODERATE"
else:
    strength = "WEAK"
```

If trend exists and RSI is far from neutral, strength is strong.

## 10. Final Signal Fusion

The final signal is created in `backend/main.py`, not inside Model 1A or Model 1B.

Think of the models like this:

- Model 1A: What may happen to price?
- Model 1B: Is market condition supportive or risky?
- Final decision engine: What should the user see?

Decision table:

| Model 1A | Model 1B Trend | Risk | Confidence | Final Signal |
|---|---|---|---|---|
| BUY | BULLISH | LOW | > 0.75 | STRONG BUY |
| BUY | anything else | any | any | BUY |
| SELL | BEARISH | any | any | STRONG SELL |
| SELL | anything else | any | any | SELL |
| HOLD | any | any | any | HOLD |

## 11. Frontend API Flow

The API client is:

```text
lib/data/api_service.dart
```

The main prediction method:

```dart
Future<PredictionResponse> getPrediction(String stock, String duration)
```

It builds the URL:

```dart
final url = Uri.parse('${AppConstants.apiBaseUrl}/predict');
```

Then sends:

```dart
body: jsonEncode({'stock': normalizedStock, 'duration': duration})
```

If the backend returns status 200:

```dart
final data = _decodeMap(response.body);
return PredictionResponse.fromJson(data);
```

If backend fails:

```dart
throw ApiException('Failed to load predictions...')
```

## 12. API Base URL Logic

File:

```text
lib/core/constants.dart
```

The backend URL changes depending on platform:

```dart
if (kIsWeb) return 'http://localhost:8000';
if (Platform.isAndroid) return 'http://10.0.2.2:8000';
return 'http://localhost:8000';
```

Why Android uses `10.0.2.2`:

Android emulator treats `localhost` as the emulator itself. `10.0.2.2` points back to your host machine.

## 13. Flutter Screen Flow

### 13.1 App Start

File:

```text
lib/main.dart
```

The app starts with:

```dart
void main() {
  runApp(...)
}
```

It uses Provider:

```dart
ChangeNotifierProvider(create: (_) => AppProvider())
```

The home screen is:

```dart
home: const SplashScreen()
```

After splash/onboarding, the app reaches main navigation.

### 13.2 Main Navigation

File:

```text
lib/navigation/main_navigation.dart
```

Tabs:

- Dashboard
- Portfolio
- Watchlist
- Settings

The Dashboard tab uses:

```dart
const HomeScreen()
```

### 13.3 Advisor Home Screen

File:

```text
lib/screens/advisor/home_screen.dart
```

This screen lets the user choose:

- stock ticker
- duration

Example stocks:

- `RELIANCE.NS`
- `TCS.NS`
- `HDFCBANK.NS`
- `INFY.NS`

When the user taps "Execute AI Analysis":

```dart
_analyzeStock()
```

It navigates to:

```dart
LoadingScreen(stock: _selectedStock, duration: _selectedDuration)
```

### 13.4 Loading Screen

File:

```text
lib/screens/advisor/loading_screen.dart
```

In `initState()`:

```dart
_fetchData();
```

The API call happens here:

```dart
final response = await ApiService().getPrediction(widget.stock, widget.duration);
```

If successful:

```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(
    builder: (context) => ResultScreen(prediction: response),
  ),
);
```

If failed:

- shows SnackBar
- goes back

### 13.5 Result Screen

File:

```text
lib/screens/advisor/result_screen.dart
```

This screen displays:

- stock name
- current price
- final signal
- confidence
- risk
- trend
- explanation
- Model 1A base signal
- Model 1B momentum, volatility, strength
- TFT forecast chart
- top opportunities
- Monday strategy
- cumulative return projection
- volatility chart
- signal heatmap

## 14. Dart Data Models

File:

```text
lib/models/prediction_model.dart
```

### 14.1 `PredictionPoint`

This class represents one future forecast point.

Fields:

- `date`
- `price`
- `upperBound`
- `lowerBound`
- `signal`
- `confidence`
- `advice`
- `volatility`
- `trendStrength`
- `cumulativeReturn`
- `priority`
- `predictedReturn`
- `score`
- `dailyTrend`

It maps JSON names like:

```json
{
  "upper_bound": 1020.5,
  "lower_bound": 980.5,
  "predicted_return": 0.02,
  "daily_trend": "UPTREND"
}
```

to Dart fields:

```dart
upperBound
lowerBound
predictedReturn
dailyTrend
```

### 14.2 `LongTermPredictions`

This holds:

- `m1`
- `m3`
- `m6`

It reads backend keys:

```dart
json['1M']
json['3M']
json['6M']
```

### 14.3 `PredictionResponse`

This represents the full backend response.

Important fields:

- `stock`
- `currentPrice`
- `finalSignal`
- `confidence`
- `riskLevel`
- `trend`
- `explanation`
- `shortTermPredictions`
- `mondayPredictions`
- `topOpportunities`
- `longTermPredictions`
- `model1aBaseSignal`
- `model1b`

This is the object passed into `ResultScreen`.

## 15. Chart Logic

File:

```text
lib/screens/advisor/result_screen.dart
```

### 15.1 Price with Bounds Chart

Function:

```dart
_buildPriceWithBoundsChart()
```

It chooses data:

```dart
List<PredictionPoint> data = _showMondaysOnly
    ? widget.prediction.mondayPredictions
    : widget.prediction.shortTermPredictions;
```

It creates:

- price line
- upper bound line
- lower bound line

The user can toggle:

- all days
- Mondays only

### 15.2 Top Opportunities

Function:

```dart
_buildTopOpportunitiesSection()
```

Uses:

```dart
widget.prediction.topOpportunities
```

These were already sorted by backend score.

### 15.3 Monday Strategy

Function:

```dart
_buildMondayStrategySection()
```

Uses:

```dart
widget.prediction.mondayPredictions
```

If confidence is high, backend sets:

```python
p["priority"] = True
```

Frontend shows this as "Weekly Opportunity".

### 15.4 Cumulative Return Chart

Function:

```dart
_buildCumulativeReturnChart()
```

Uses:

```dart
data[i].cumulativeReturn
```

Shows how far the prediction is from current price over the forecast period.

### 15.5 Volatility Chart

Function:

```dart
_buildVolatilityChart()
```

Uses:

```dart
data[i].volatility
```

In current backend logic, volatility is based on absolute daily random movement:

```python
abs(tft_noise) * 100
```

### 15.6 Signal Heatmap

Function:

```dart
_buildSignalHeatmap()
```

It renders a small horizontal color block for each predicted day.

Color logic:

```dart
if (signal.contains('BUY')) return AppColors.profit;
if (signal.contains('SELL')) return AppColors.loss;
return AppColors.warning;
```

## 16. Portfolio Module Overview

The portfolio module is separate from the single-stock prediction screen.

Main backend endpoint:

```text
POST /portfolio/analyze
```

Main files:

- `backend/portfolio/optimizer.py`
- `backend/portfolio/analyzer.py`
- `backend/portfolio/risk_model.py`
- `backend/portfolio/allocation.py`
- `backend/portfolio/recommender.py`
- `backend/portfolio/backtest_engine.py`

Main frontend files:

- `lib/screens/portfolio/portfolio_screen.dart`
- `lib/screens/portfolio/portfolio_input_screen.dart`
- `lib/screens/portfolio/portfolio_advisor_screen.dart`
- `lib/screens/portfolio/sector_stocks_screen.dart`

## 17. Portfolio Backend Flow

Endpoint:

```python
@router.post("/analyze")
def analyze_portfolio(req: AnalyzeRequest):
```

Request contains:

```python
mode: str
portfolio: List[PortfolioItem]
budget: Optional[float]
```

Each portfolio item:

```python
stock: str
amount: float
```

Example:

```json
{
  "mode": "optimize_existing",
  "portfolio": [
    {"stock": "TCS", "amount": 50000},
    {"stock": "RELIANCE", "amount": 30000}
  ],
  "budget": 10000
}
```

### 17.1 PortfolioAnalyzer

File:

```text
backend/portfolio/analyzer.py
```

It maps stocks to sectors:

```python
SECTOR_MAP = {
    "IT": ["TCS", "INFY", ...],
    "Energy": ["RELIANCE", ...],
    "Banking": ["HDFCBANK", ...]
}
```

It calculates:

- stock weights
- sector exposure
- number of unique sectors
- portfolio status

Status rules:

- If any stock weight > 50 percent: `OVER_CONCENTRATED`
- Else if sectors < 3: `UNDER_DIVERSIFIED`
- Else: `BALANCED`

### 17.2 Portfolio Market Data

`optimizer.py` downloads 6 months of data for all portfolio symbols:

```python
df = yf.download(symbols, period="6mo", interval="1d", progress=False)
```

It extracts close prices.

### 17.3 Expected Return

File:

```text
backend/portfolio/risk_model.py
```

```python
daily_returns = prices_df.pct_change().dropna()
expected_returns = daily_returns.mean() * 252
```

Expected return is annualized average daily return.

### 17.4 Volatility

```python
volatility = daily_returns.std() * np.sqrt(252)
```

Annualized standard deviation.

### 17.5 Covariance Matrix

```python
cov_matrix = daily_returns.cov() * 252
```

Covariance tells how assets move together. It is needed for portfolio risk and Markowitz optimization.

### 17.6 Portfolio Return

```python
portfolio_return = np.sum(expected_returns * current_weights_series)
```

This is weighted average expected return.

### 17.7 Portfolio Risk

```python
portfolio_risk = np.sqrt(np.dot(current_weights_series.T, np.dot(cov_matrix, current_weights_series)))
```

This uses portfolio variance formula:

```text
portfolio variance = w^T * covariance_matrix * w
portfolio risk = sqrt(variance)
```

### 17.8 Sharpe Ratio

```python
portfolio_sharpe = (portfolio_return - 0.05) / (portfolio_risk + 1e-6)
```

Risk-free rate is assumed to be 5 percent.

Higher Sharpe means better return per unit of risk.

### 17.9 Risk Level

```python
risk_level_str = "HIGH" if portfolio_risk > 0.25 else ("MEDIUM" if portfolio_risk > 0.15 else "LOW")
```

Rules:

- Above 25 percent volatility: HIGH
- Above 15 percent: MEDIUM
- Otherwise: LOW

## 18. Portfolio Optimization

File:

```text
backend/portfolio/allocation.py
```

Function:

```python
def optimize_allocation(expected_returns, cov_matrix):
```

It performs Markowitz optimization to maximize Sharpe ratio.

Internally it minimizes negative Sharpe:

```python
def negative_sharpe(weights):
    portfolio_return = np.sum(returns_arr * weights)
    portfolio_volatility = np.sqrt(np.dot(weights.T, np.dot(cov_arr, weights)))
    sharpe = (portfolio_return - risk_free_rate) / (portfolio_volatility + 1e-6)
    return -sharpe
```

Constraints:

```python
weights sum to 1
```

Bounds:

```python
each weight between 0 and 1
```

This means:

- long-only portfolio
- no short selling
- all money must be allocated

Optimization method:

```python
method='SLSQP'
```

## 19. Portfolio Recommendations

File:

```text
backend/portfolio/recommender.py
```

If portfolio is under-diversified or over-concentrated, it suggests missing sectors.

Then it ranks candidate stocks in those sectors:

```python
rank_stocks(sector, current_portfolio_symbols, analyzer, portfolio_risk)
```

For each candidate:

1. Download yfinance data.
2. Run Model 1A short-term function.
3. Run Model 1B.
4. Calculate expected return and risk.
5. Calculate Sharpe ratio.
6. Calculate score.
7. Adjust signal based on portfolio exposure.

Signal adjustment lives in:

```text
backend/portfolio/signal_engine.py
```

If adding a stock would overexpose the same sector:

```python
return "HOLD (Overexposed Sector)"
```

## 20. Backtesting Engine

File:

```text
backend/portfolio/backtest_engine.py
```

Function:

```python
def backtest(predictions: list, actual_prices: list) -> dict:
```

It compares predicted direction with actual direction.

Example:

- If predicted price rises and actual price rises: correct
- If predicted price falls and actual price falls: correct
- Otherwise: incorrect

Accuracy:

```python
accuracy = correct / (n - 1)
```

Reliability:

- `EXCELLENT`: accuracy >= 0.70
- `GOOD`: accuracy >= 0.60
- `POOR`: below 0.60

Current portfolio backtest is demo-style:

```python
mock_predictions = recent_prices * (1 + np.random.normal(0, 0.01, size=len(recent_prices)))
```

So it is also synthetic at present.

## 21. Important Current Limitations

These are not failures, but they are important for explaining honestly.

### 21.1 TFT Model Is Loaded But Not Truly Used for Prediction

`run_tft_short_term()` loads:

```python
TemporalFusionTransformer.load_from_checkpoint(...)
```

But it does not call:

```python
model.predict(...)
```

The forecast values are produced by random noise.

For a real TFT implementation, the next major improvement is building the full inference dataframe and using `model.predict()`.

### 21.2 Long-Term Model Is Simulation-Based

`run_long_term_model()` is not trained ML. It is randomized projection logic.

### 21.3 Confidence Is Formula-Based

Confidence comes from prediction interval width, not from calibrated model probability.

### 21.4 Duration Is Sent But Not Used for Main Decision

Flutter sends `duration`, but backend currently generates all periods and does not deeply branch logic based on requested duration.

### 21.5 Portfolio Recommendation Uses Some Synthetic Values

Portfolio backtesting uses mocked predictions for demo behavior.

Also, in `backend/portfolio/recommender.py`, this line checks `predicted_price`:

```python
predicted_price = out_tft['predictions'][-1].get('predicted_price', current_price)
```

But Model 1A prediction points use key `price`, not `predicted_price`. So the recommender may fall back to `current_price`, making predicted return close to zero in that section.

## 22. How to Explain Model 1A in a Presentation

Use this explanation:

Model 1A is the price prediction component. It has a short-term path based around a saved Temporal Fusion Transformer checkpoint and a long-term projection path. The backend fetches six months of historical stock data, extracts the latest close price, and passes the data to Model 1A. The short-term function loads the TFT checkpoint and generates trading-day forecast points for the next month. Each point contains predicted price, upper/lower uncertainty bounds, confidence, signal, volatility, cumulative return, trend label, and ranking score. The final short-term base signal is based on the last forecasted price compared with the current price. This base signal is then combined with Model 1B risk and trend checks to produce the final recommendation.

If asked whether the TFT is fully doing inference:

The checkpoint is loaded with PyTorch Forecasting, but the current implementation does not yet build a TFT inference dataloader or call `model.predict()`. The current forecast generation is simulation-based after checkpoint loading. The next enhancement would be to connect the loaded checkpoint to real TFT inference by recreating the training preprocessing and calling `model.predict()` on a properly formatted prediction dataset.

## 23. How to Explain the Whole Project in a Viva

Short answer:

QuanTraid is an AI-assisted stock and portfolio advisory system. The Flutter frontend lets the user choose stocks, view predictions, and analyze portfolios. The FastAPI backend collects market data through yfinance, runs Model 1A for price forecasting, Model 1B for technical risk validation, and a final decision engine to generate buy/sell/hold recommendations. The portfolio module uses sector exposure, annualized returns, volatility, covariance, Sharpe ratio, and Markowitz optimization to suggest healthier allocation.

Detailed answer:

The app starts in Flutter and sends stock analysis requests to a Python FastAPI backend. For stock prediction, the backend downloads 6 months of daily data, cleans it, and obtains the latest close price. Model 1A produces short-term and long-term predictions. The short-term path is designed around TFT forecasting and returns daily price projections with confidence, bounds, signals, scores, and trends. Model 1B then calculates market risk and trend using volatility, RSI, and moving averages. The final decision engine combines the Model 1A base signal with Model 1B risk/trend validation. The response is returned as structured JSON, parsed into Dart model classes, and displayed using charts and signal cards.

For portfolio analysis, the backend receives user holdings, calculates stock and sector weights, detects concentration or under-diversification, downloads price history, computes expected returns and covariance, calculates portfolio return/risk/Sharpe ratio, and runs Markowitz optimization to recommend improved weights. It also suggests sectors and candidate stocks when diversification is weak.

## 24. Suggested Learning Order

Study the project in this order:

1. `lib/screens/advisor/home_screen.dart`
2. `lib/screens/advisor/loading_screen.dart`
3. `lib/data/api_service.dart`
4. `backend/main.py`
5. `backend/model_1a.py`
6. `backend/model_1b.py`
7. `lib/models/prediction_model.dart`
8. `lib/screens/advisor/result_screen.dart`
9. `backend/portfolio/optimizer.py`
10. `backend/portfolio/analyzer.py`
11. `backend/portfolio/risk_model.py`
12. `backend/portfolio/allocation.py`
13. `backend/portfolio/recommender.py`
14. `lib/screens/portfolio/portfolio_input_screen.dart`
15. `lib/screens/portfolio/portfolio_advisor_screen.dart`

## 25. Important Terms

TFT:

Temporal Fusion Transformer, a deep learning model for time-series forecasting.

Checkpoint:

A saved trained model file. Here it is `ML_data/tft_nifty50.ckpt`.

OHLCV:

Open, High, Low, Close, Volume market data.

RSI:

Relative Strength Index, a momentum indicator.

Moving Average:

Average price over a time window. Used to detect trend.

Volatility:

How much price fluctuates. Higher volatility means higher risk.

Annualized Volatility:

Daily volatility scaled to yearly level using `sqrt(252)`.

Sharpe Ratio:

Return earned per unit of risk.

Markowitz Optimization:

Portfolio allocation method that uses expected return and covariance to optimize risk-return tradeoff.

Covariance Matrix:

A matrix describing how asset returns move together.

Confidence:

In this project, confidence is derived from width of prediction bounds.

Base Signal:

Model 1A's main short-term BUY/SELL/HOLD decision before Model 1B validation.

Final Signal:

The final user-facing recommendation after combining Model 1A and Model 1B.

## 26. One-Minute Explanation

QuanTraid has a Flutter frontend and FastAPI backend. The user selects a stock, and the app sends it to `/predict`. The backend downloads recent price history using yfinance, runs Model 1A for short-term and long-term forecasting, and runs Model 1B for risk and trend validation. Model 1A produces predicted prices, confidence bounds, daily signals, Monday opportunities, and top opportunities. Model 1B calculates volatility, RSI momentum, and moving-average trend. A final decision engine combines both models into a final signal like BUY, SELL, HOLD, STRONG BUY, or STRONG SELL. The frontend parses this response and visualizes it with charts, cards, and timelines. The portfolio module separately analyzes user holdings, checks diversification, computes risk-return metrics, and suggests optimized allocation using Markowitz optimization.

