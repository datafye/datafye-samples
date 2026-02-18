# Second Candles

Fetch and stream second-frequency candle data for a small set of symbols over a few hours of a single trading day.

**Prerequisites:** A running local Datafye environment with the Synthetic dataset (see [Running the Samples](Running-the-Samples)). All commands assume you are in the extracted distribution directory.

**What to look for:** Historical fetch samples run 100 iterations and print average candle count and latency. Verify candle counts are non-zero and consistent between REST and Java. Live streaming samples receive 1000 messages then exit automatically.

## Data scope

- **Symbols:** AAPL, MSFT, GOOGL
- **Day:** 2024-01-15
- **Test subset:** AAPL, MSFT over a 3-hour window (10:00–13:00)

## Fetch historical candles (REST)

```bash
bin/run.sh get-historical-candles-rest -s AAPL -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-rest -s MSFT -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

## Fetch historical candles (Java)

```bash
bin/run.sh get-historical-candles-java -s AAPL -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-java -s MSFT -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

## Stream live data

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT
bin/run.sh stream-live-trades-java -s AAPL,MSFT
```
