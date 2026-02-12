# Technical README

## Architecture

- App: SwiftUI
- Main views:
  - `Compound Interest/ContentView.swift`
  - `Compound Interest/StockHistoryView.swift`
  - `Compound Interest/History0050View.swift`
- Theme tokens:
  - `Compound Interest/AppTheme.swift`
- Data pipeline:
  - `scripts/stock_csv_pipeline.py`

## Compound Logic

Annual compounding with contribution at the beginning of each year:

1. Add annual contribution (if enabled)
2. Apply annual interest once at year end

Per-year output includes:

- Total
- Growth multiple
- Principal / interest / contribution breakdown

## Stock Projection Logic (Year 1–20)

Used in `ContentView` for `0050` and `2330`.

### Inputs

- Latest adjusted close (fallback to close)
- Lookback window: `3Y`, `5Y`, `10Y`

### Growth model

1. Estimate CAGR from lookback range
2. Clamp CAGR to `[-5%, +12%]`
3. Mean-revert for long horizon:
  - Year 1–10: use base CAGR
  - Year 11–20: converge toward `4%`

### Yearly stock estimate

- `price[t] = price[t-1] * (1 + effectiveGrowth[t])`

### Equivalent shares

- Year 1 investment:
  - `principal + annualContribution` (if contribution enabled)
- Year 2+ investment:
  - `annualContribution` (if enabled)
- Fractional shares allowed:
  - `bought[t] = invest[t] / price[t]`
  - `accumulated[t] = accumulated[t-1] + bought[t]`

Displayed as:

- Total shares and yearly delta:
  - `0050 ~= total (+delta)`
  - `2330 ~= total (+delta)`

## Stock History Page

### Data hierarchy

- Year section
- Month section
- Daily records

### Display behavior

- Year/month can expand/collapse
- Daily is collapsed by default
- If annual/monthly summary is missing, fallback computes from daily records when possible

### Candlestick scaling

- Annual: 100%
- Monthly: 80%
- Daily: 70%

### Color convention

- Up: red
- Down: green
- Flat: white/gray

## Data Pipeline (CSV → JSON)

Source patterns:

- Daily: `STOCK_DAY_*`
- Monthly summary: `FMSRFK_*`
- Annual summary: `FMNPTK_*`

Outputs:

- `Compound Interest/0050_history.json`
- `Compound Interest/2330_history.json`

JSON schema (current):

- `records`
- `annual_summaries`
- `monthly_summaries`
- `dividends`

Commands:

```bash
python3 scripts/stock_csv_pipeline.py --root "/Users/sam/Developer/Compound Interest"
python3 scripts/stock_csv_pipeline.py --root "/Users/sam/Developer/Compound Interest" --normalize
```

## Theme System

`AppTheme.swift` provides semantic tokens:

- `overlayScrim`
- `separatorStrong`
- `surfaceElevatedFill/Stroke`
- `surfaceLevel1Fill/Stroke`
- `surfaceLevel2Fill/Stroke`
- `surfaceLevel3Fill/Stroke`
- `semanticError`

All major surfaces in Compound + Stock pages use these tokens for light/dark consistency.

## Known Limits

- Dividend reinvestment is not implemented yet
- Projection is model-based, not a forecast guarantee
- No external real-time market feed; uses bundled history JSON
