# Compound Interest

Compound Interest is an iOS SwiftUI app that combines:

- Compound growth simulation (principal + optional annual contribution)
- Taiwan stock history browser (`0050`, `2330`)
- Year-by-year stock projection with equivalent shares (fractional shares supported)

Language:

- English (this file)
- Traditional Chinese: `README.zh-Hant.md`

## Highlights

- `Compound` tab:
  - Real-time yearly projection (Year 1 → Year 20)
  - Input panel for principal, annual contribution, and growth lookback (`3Y/5Y/10Y`)
  - Estimated stock prices and equivalent shares for `0050` / `2330`
- `Stock` tab:
  - Segmented switch between `0050` and `2330`
  - Year/month/day expandable hierarchy with index jump
  - Annual/monthly summary cards + daily records with candlestick visuals
- Localization:
  - English + Traditional Chinese (`en`, `zh-Hant`)
- UI consistency:
  - Centralized semantic theme (`AppTheme.swift`) with light/dark support

## Quick Start

1. Open `Compound Interest.xcodeproj`
2. Select simulator or device
3. Build and run

## Screenshots

Put screenshots under `docs/images/` and keep these names:

- `compound-light.png`
- `compound-dark.png`
- `stock-history-light.png`
- `stock-history-dark.png`

Example markdown (already wired below):

![Compound Light](docs/images/compound-light.png)
![Compound Dark](docs/images/compound-dark.png)
![Stock History Light](docs/images/stock-history-light.png)
![Stock History Dark](docs/images/stock-history-dark.png)

## Data

Source folders:

- `0050_history/`
- `2330_history/`

Generate app JSON:

```bash
python3 scripts/stock_csv_pipeline.py --root "/Users/sam/Developer/Compound Interest"
```

Normalize CSV encoding and generate JSON:

```bash
python3 scripts/stock_csv_pipeline.py --root "/Users/sam/Developer/Compound Interest" --normalize
```

## Docs

- Product overview: `README.md` (this file)
- Traditional Chinese overview: `README.zh-Hant.md`
- Technical details: `TECHNICAL_README.md`

## License

This project is licensed under the MIT License. See `LICENSE`.

## Disclaimer

- This app and repository are for educational and informational purposes only.
- It is not investment advice, financial advice, tax advice, or legal advice.
- Historical data and model-based projections do not guarantee future results.
- You are solely responsible for any investment decisions and related risk.
