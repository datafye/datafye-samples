# Datafye Client Samples

Sample code demonstrating how to interact with the [Datafye](https://www.datafye.io) Data Cloud using both the REST API and the native Java Client API. Each sample is self-contained and shows a common data access pattern — fetching historical candles, querying live quotes, streaming trades — so you can use them as starting points for your own integrations.

The REST samples use standard HTTP/JSON (via [OkHttp](https://square.github.io/okhttp/)) and work from any language that can make HTTP calls. The Java Client samples use the [Datafye Java Client API](https://docs.datafye.io/concepts-and-architecture/the-data-cloud/data-access-modes) which connects directly to backend services over Solace messaging for lower latency and streaming support.

## Build

### Prerequisites

- **Java 17+**
- **Maven 3.8+** — [Download](https://maven.apache.org/index.html)

### Build the Project

```bash
mvn clean install
```

This produces a distribution archive in `target/`. Extract it:

```bash
cd target
tar -xzf datafye-samples-2.0-SNAPSHOT-distribution.tar.gz
cd datafye-samples-2.0-SNAPSHOT
```

The extracted distribution contains:
- `libs/` — All JARs (application + dependencies)
- `conf/rumi.conf` — Connection configuration for all samples

## Samples

The samples are organized into two packages that mirror the two ways to access the Data Cloud:

### REST API Samples (`com.datafye.samples.rest`)

These use HTTP/JSON to query the Datafye REST API. They work from any language — Java is used here for illustration.

| Sample | Description |
|--------|-------------|
| **GetHistoricalCandles** | Fetch historical OHLC candles for a symbol and time range |
| **GetLiveCandles** | Fetch current trading day candles for a symbol |
| **GetLiveTopOfBook** | Fetch live top-of-book bid/ask quotes for one or more symbols |
| **GetLiveCandlesConcurrently** | Fetch live candles for all symbols in parallel using a thread pool |

### Java Client Samples (`com.datafye.samples.java`)

These use the Datafye Java Client API, which communicates directly with backend services over Solace messaging. This gives you lower latency and access to streaming — something the REST API doesn't support.

| Sample | Description |
|--------|-------------|
| **GetHistoricalCandles** | Fetch historical OHLC candles (request-reply pattern) |
| **GetLiveCandles** | Fetch current trading day candles (request-reply pattern) |
| **GetLiveTopOfBook** | Fetch live top-of-book quotes (request-reply pattern) |
| **StreamHistoricalCandles** | Stream historical candles with rate throttling (streaming pattern) |
| **StreamHistoricalCandlesConcurrently** | Stream historical candles across multiple concurrent streams |
| **StreamLiveTopOfBook** | Subscribe to live top-of-book quotes in real time (subscribe/unsubscribe pattern) |
| **StreamLiveTrades** | Subscribe to live trades in real time (subscribe/unsubscribe pattern) |

## Run

### 1. Provision a Local Datafye Environment

The samples need a running Datafye Data Cloud to connect to. The easiest way to get one is to provision a local environment using the Datafye CLI.

**Install the Datafye CLI:**

```bash
curl -fsSL https://downloads.n5corp.com/datafye/cli/latest/install.sh | sudo bash
```

> No sudo access? See [CLI Installation](https://docs.datafye.io/cli-reference/installation) for alternative methods.

**Download the quickstart descriptor and provision:**

```bash
curl -o quickstart.yaml https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only.yaml
datafye foundry local provision --descriptor quickstart.yaml
```

This provisions a Data Cloud with a Synthetic dataset containing 10 symbols (AAPL, MSFT, GOOGL, AMZN, NVDA, TSLA, META, NFLX, AMD, INTC), 90 days of historical data, and live tick and OHLC data. No API keys required.

For full details see the [Foundry: Data Cloud Only](https://docs.datafye.io/quickstart/foundry-data-cloud-only) quickstart, or explore other quickstart scenarios in the [Datafye docs](https://docs.datafye.io).

### 2. Set JVM Options

The Java Client samples require the following JVM options. Set them once as an environment variable:

```bash
export JAVA_OPTS="--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.management/sun.management=ALL-UNNAMED"
```

### 3. Run the Samples

All commands below assume you are in the extracted distribution directory (`datafye-samples-2.0-SNAPSHOT`).

#### REST: Get Historical Candles

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetHistoricalCandles \
  -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required) — Stock symbol
- `-c, --frequency` (default: `Minute`) — Candle frequency (`Second`, `Minute`, `Hour`, `Day`)
- `-f, --from` (required) — Start time (`yyyy-MM-dd'T'HH:mm:ss`)
- `-t, --to` (required) — End time

#### REST: Get Live Candles

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetLiveCandles -s AAPL
```

Options:
- `-s, --symbol` (required) — Stock symbol

#### REST: Get Live Top-Of-Book Quotes

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetLiveTopOfBook -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

#### REST: Get Live Candles Concurrently

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.rest.GetLiveCandlesConcurrently -c 4
```

Options:
- `-c, --concurrency` (default: `1`) — Number of concurrent threads

#### Java: Get Historical Candles

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.GetHistoricalCandles \
  -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required) — Stock symbol
- `-c, --frequency` (default: `Minute`) — Candle frequency
- `-f, --from` (required) — Start time
- `-t, --to` (required) — End time

#### Java: Get Live Candles

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.GetLiveCandles -s AAPL
```

Options:
- `-s, --symbol` (required) — Stock symbol

#### Java: Get Live Top-Of-Book Quotes

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.GetLiveTopOfBook -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

#### Java: Stream Historical Candles

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamHistoricalCandles \
  -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00 -r 1000
```

Options:
- `-s, --symbol` (optional) — Symbol to stream (omit for all symbols)
- `-f, --from` (required) — Start time
- `-t, --to` (required) — End time
- `-r, --rate` (default: `0`) — Max streaming rate (`0` = unlimited)

> **Note:** Streaming samples use the SIP History client. Ensure the SIP dataset is deployed and configured in `rumi.conf`.

#### Java: Stream Historical Candles Concurrently

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamHistoricalCandlesConcurrently \
  -f 2024-01-15 -c 4 -r 1000
```

Options:
- `-i, --instance` (default: `0`) — Client instance ID
- `-c, --concurrency` (default: `1`) — Number of concurrent streams
- `-f, --from` (required) — Base date (`yyyy-MM-dd`)
- `-r, --rate` (default: `0`) — Max streaming rate (`0` = unlimited)

#### Java: Stream Live Top-Of-Book Quotes

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamLiveTopOfBook -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

Subscribes to live top-of-book quotes, prints 1000 incoming quotes, then unsubscribes and exits.

#### Java: Stream Live Trades

```bash
java $JAVA_OPTS -cp "libs/*" com.datafye.samples.java.StreamLiveTrades -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

Subscribes to live trades, prints 1000 incoming trades, then unsubscribes and exits.

### Configuration

Connection settings live in `conf/rumi.conf`. By default it points to `localhost` for all services and uses the Synthetic dataset — which is what the quickstart descriptor provisions. If your environment uses different hosts or ports, update `rumi.conf` accordingly.
