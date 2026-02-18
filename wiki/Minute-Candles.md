# Minute Candles

Fetch and stream minute-frequency candle data, plus exercise live candle fetching, live top-of-book quotes, and concurrent access.

**Prerequisites:** A running local Datafye environment with the Synthetic dataset (see [Running the Samples](Running-the-Samples)). All commands assume you are in the extracted distribution directory.

**What to look for:** Historical fetch samples run 100 iterations and print average candle count and latency. Verify candle counts are non-zero and consistent between REST and Java. Live streaming samples receive 1000 messages then exit automatically.

## Data scope

- **Symbols:** AAPL, MSFT, GOOGL
- **Day:** 2024-01-15
- **Test subset:** AAPL, MSFT over a 3-hour window (10:00–13:00)

## Fetch historical candles (REST)

```bash
bin/run.sh get-historical-candles-rest -s AAPL -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-rest -s MSFT -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

## Fetch historical candles (Java)

```bash
bin/run.sh get-historical-candles-java -s AAPL -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-java -s MSFT -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

## Fetch live candles

```bash
bin/run.sh get-live-candles-rest -s AAPL
bin/run.sh get-live-candles-java -s AAPL
bin/run.sh get-live-candles-rest -s MSFT
bin/run.sh get-live-candles-java -s MSFT
```

## Fetch live top-of-book quotes

```bash
bin/run.sh get-live-top-of-book-rest -s AAPL,MSFT,GOOGL
bin/run.sh get-live-top-of-book-java -s AAPL,MSFT,GOOGL
```

## Fetch live candles concurrently

```bash
bin/run.sh get-live-candles-concurrently-rest -c 4
```

## Stream live data

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT
bin/run.sh stream-live-trades-java -s AAPL,MSFT
```
