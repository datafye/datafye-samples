# Datafye Client Samples

Sample code demonstrating how to interact with the Datafye platform using both the REST API and native Java (Rumi) clients.

## What's in the Repo

The samples are organized into two packages:

### REST API Samples (`com.datafye.samples.rest`)

| Name | Description | Main Class |
|------|-------------|------------|
| Get Historical Candles | Fetch historical OHLC candles via REST | `com.datafye.samples.rest.GetHistoricalCandles` |
| Get Live Candles | Fetch current trading day candles via REST | `com.datafye.samples.rest.GetLiveCandles` |
| Get Live Top-Of-Book | Fetch live top-of-book quotes via REST | `com.datafye.samples.rest.GetLiveTopOfBook` |
| Get Live Candles Concurrently | Concurrent REST candle fetches for all symbols | `com.datafye.samples.rest.GetLiveCandlesConcurrently` |

### Java Client Samples (`com.datafye.samples.java`)

| Name | Description | Main Class |
|------|-------------|------------|
| Get Historical Candles | Fetch historical OHLC candles via Java client | `com.datafye.samples.java.GetHistoricalCandles` |
| Get Live Candles | Fetch current trading day candles via Java client | `com.datafye.samples.java.GetLiveCandles` |
| Get Live Top-Of-Book | Fetch live top-of-book quotes via Java client | `com.datafye.samples.java.GetLiveTopOfBook` |
| Stream Historical Candles | Stream historical OHLC candles via Java client | `com.datafye.samples.java.StreamHistoricalCandles` |
| Stream Historical Candles Concurrently | Concurrent historical OHLC streams | `com.datafye.samples.java.StreamHistoricalCandlesConcurrently` |
| Stream Live Top-Of-Book | Stream live top-of-book quotes via Java client | `com.datafye.samples.java.StreamLiveTopOfBook` |
| Stream Live Trades | Stream live trades via Java client | `com.datafye.samples.java.StreamLiveTrades` |

## Prerequisites

### Maven
Maven 3.8+ is required. Download from [here](https://maven.apache.org/index.html).

### Java
Java 17 is required.

### JVM Options
The following JVM options are required when running the samples:

```
--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.management/sun.management=ALL-UNNAMED
```

For convenience, set these as an environment variable:

```bash
export JAVA_OPTS="--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.management/sun.management=ALL-UNNAMED"
```

### Datafye Platform
The samples require a running Datafye platform. REST samples connect to the API service (default: `localhost:7776`). Java client samples connect to the backend services via Solace (default: `localhost:55555`).

## Build

Build the project from the repository root:

```bash
mvn clean install
```

This produces a distribution archive: `datafye-samples-2.0-SNAPSHOT-distribution.tar.gz`. Extract it:

```bash
cd target
tar -xzf datafye-samples-2.0-SNAPSHOT-distribution.tar.gz
cd datafye-samples-2.0-SNAPSHOT
```

## Configuration

The `conf/rumi.conf` file contains connection configuration for both REST and Java clients. By default, it points to `localhost` for all services and uses the Synthetic dataset.

## Run

All examples below assume you are in the extracted distribution directory.

### REST Samples

#### Get Historical Candles
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetHistoricalCandles \
  -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required): Stock symbol
- `-c, --frequency` (default: Minute): Candle frequency (Second, Minute, Hour, Day)
- `-f, --from` (required): Start time (format: `yyyy-MM-dd'T'HH:mm:ss`)
- `-t, --to` (required): End time

#### Get Live Candles
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetLiveCandles -s AAPL
```

Options:
- `-s, --symbol` (required): Stock symbol

#### Get Live Top-Of-Book Quotes
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetLiveTopOfBook -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required): Comma-separated symbols

#### Get Live Candles Concurrently
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetLiveCandlesConcurrently -c 4
```

Options:
- `-c, --concurrency` (default: 1): Number of concurrent threads

### Java Client Samples

#### Get Historical Candles
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.GetHistoricalCandles \
  -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required): Stock symbol
- `-c, --frequency` (default: Minute): Candle frequency
- `-f, --from` (required): Start time
- `-t, --to` (required): End time

#### Get Live Candles
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.GetLiveCandles -s AAPL
```

Options:
- `-s, --symbol` (required): Stock symbol

#### Get Live Top-Of-Book Quotes
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.GetLiveTopOfBook -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required): Comma-separated symbols

#### Stream Historical Candles
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamHistoricalCandles \
  -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00 -r 1000
```

Options:
- `-s, --symbol` (optional): Symbol to stream (omit for all symbols)
- `-f, --from` (required): Start time
- `-t, --to` (required): End time
- `-r, --rate` (default: 0): Max streaming rate (0 = unlimited)

> Note: Streaming samples use the SIP History client which provides streaming support. Ensure the SIP dataset is deployed and configured in `rumi.conf`.

#### Stream Historical Candles Concurrently
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamHistoricalCandlesConcurrently \
  -f 2024-01-15 -c 4 -r 1000
```

Options:
- `-i, --instance` (default: 0): Client instance ID
- `-c, --concurrency` (default: 1): Number of concurrent streams
- `-f, --from` (required): Base date (format: `yyyy-MM-dd`)
- `-r, --rate` (default: 0): Max streaming rate (0 = unlimited)

#### Stream Live Top-Of-Book Quotes
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamLiveTopOfBook -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required): Comma-separated symbols

Streams live top-of-book quotes using the subscribe/unsubscribe pattern. The sample subscribes to the specified symbols, prints 1000 incoming quotes, then unsubscribes and exits.

#### Stream Live Trades
```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamLiveTrades -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required): Comma-separated symbols

Streams live trades using the subscribe/unsubscribe pattern. The sample subscribes to the specified symbols, prints 1000 incoming trades, then unsubscribes and exits.

## REST API Endpoints

The REST samples target the Datafye unified API at port 7776:

| Endpoint | Description |
|----------|-------------|
| `GET /datafye-api/v1/stocks/history/ohlc` | Historical OHLC candles |
| `GET /datafye-api/v1/stocks/live/agg/ohlc` | Current trading day candles |
| `GET /datafye-api/v1/stocks/live/topofbook` | Live top-of-book quotes |
| `GET /datafye-api/v1/stocks/reference/securities` | Security master |

All endpoints accept a `dataset` query parameter (`SIP` or `Synthetic`, default: `SIP`). The samples default to `Synthetic`.
