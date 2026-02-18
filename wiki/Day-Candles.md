# Day Candles

Fetch and stream day-frequency candle data over multiple trading days.

**Prerequisites:** A running local Datafye environment with the Synthetic dataset (see [Running the Samples](Running-the-Samples)). All commands assume you are in the extracted distribution directory.

**What to look for:** Historical fetch samples run 100 iterations and print average candle count and latency. Verify candle counts are non-zero and consistent between REST and Java. Live streaming samples receive 1000 messages then exit automatically.

## Data scope

- **Symbols:** AAPL, MSFT, GOOGL
- **Date range:** 2024-01-15 through 2024-01-19 (5 trading days)
- **Test subset:** AAPL, MSFT over a 3-day window (Jan 16–18)

## Fetch historical candles (REST)

```bash
bin/run.sh get-historical-candles-rest -s AAPL -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
bin/run.sh get-historical-candles-rest -s MSFT -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
```

## Fetch historical candles (Java)

```bash
bin/run.sh get-historical-candles-java -s AAPL -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
bin/run.sh get-historical-candles-java -s MSFT -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
```

## Stream live data

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT,GOOGL
bin/run.sh stream-live-trades-java -s AAPL,MSFT,GOOGL
```
