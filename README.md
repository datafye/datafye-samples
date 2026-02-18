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
- `bin/` — Run scripts (`run.sh` for Linux/macOS, `run.bat` for Windows)
- `libs/` — All JARs (application + dependencies)
- `conf/rumi.conf` — Optional Rumi runtime tuning (trace levels, etc.)

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

### 2. Run the Samples

All commands below assume you are in the extracted distribution directory (`datafye-samples-2.0-SNAPSHOT`). Use `bin/run.sh` (Linux/macOS) or `bin\run.bat` (Windows) to run any sample. The scripts handle JVM options and classpath automatically.

To see all available samples:

```bash
bin/run.sh --help
```

#### REST: Get Historical Candles

```bash
bin/run.sh get-historical-candles-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required) — Stock symbol
- `-c, --frequency` (default: `Minute`) — Candle frequency (`Second`, `Minute`, `Hour`, `Day`)
- `-f, --from` (required) — Start time (`yyyy-MM-dd'T'HH:mm:ss`)
- `-t, --to` (required) — End time

#### REST: Get Live Candles

```bash
bin/run.sh get-live-candles-rest -s AAPL
```

Options:
- `-s, --symbol` (required) — Stock symbol

#### REST: Get Live Top-Of-Book Quotes

```bash
bin/run.sh get-live-top-of-book-rest -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

#### REST: Get Live Candles Concurrently

```bash
bin/run.sh get-live-candles-concurrently-rest -c 4
```

Options:
- `-c, --concurrency` (default: `1`) — Number of concurrent threads

#### Java: Get Historical Candles

```bash
bin/run.sh get-historical-candles-java -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required) — Stock symbol
- `-c, --frequency` (default: `Minute`) — Candle frequency
- `-f, --from` (required) — Start time
- `-t, --to` (required) — End time

#### Java: Get Live Candles

```bash
bin/run.sh get-live-candles-java -s AAPL
```

Options:
- `-s, --symbol` (required) — Stock symbol

#### Java: Get Live Top-Of-Book Quotes

```bash
bin/run.sh get-live-top-of-book-java -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

#### Java: Stream Historical Candles

```bash
bin/run.sh stream-historical-candles-java -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00 -r 1000
```

Options:
- `-s, --symbol` (optional) — Symbol to stream (omit for all symbols)
- `-f, --from` (required) — Start time
- `-t, --to` (required) — End time
- `-r, --rate` (default: `0`) — Max streaming rate (`0` = unlimited)

> **Note:** Streaming samples use the SIP History client. Ensure the SIP dataset is deployed in your Datafye environment.

#### Java: Stream Historical Candles Concurrently

```bash
bin/run.sh stream-historical-candles-concurrently-java -f 2024-01-15 -c 4 -r 1000
```

Options:
- `-i, --instance` (default: `0`) — Client instance ID
- `-c, --concurrency` (default: `1`) — Number of concurrent streams
- `-f, --from` (required) — Base date (`yyyy-MM-dd`)
- `-r, --rate` (default: `0`) — Max streaming rate (`0` = unlimited)

#### Java: Stream Live Top-Of-Book Quotes

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

Subscribes to live top-of-book quotes, prints 1000 incoming quotes, then unsubscribes and exits.

#### Java: Stream Live Trades

```bash
bin/run.sh stream-live-trades-java -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

Subscribes to live trades, prints 1000 incoming trades, then unsubscribes and exits.

### Configuration

Each sample embeds its connection config directly in a `static {}` block at the top of the class. By default they point to `solace.rumi.local:55555` (Solace broker) and `api.rest.rumi.local:7776` (REST API) — which is what the quickstart descriptor provisions. If your environment uses different hosts or ports, update the `System.setProperty()` calls in the sample you're running.

The `conf/rumi.conf` file is included in the distribution for optional Rumi runtime tuning (trace levels, etc.) but is not required for connection configuration.

## Sanity Tests

A structured walkthrough to verify all samples against a locally provisioned Datafye environment. The tests use the Synthetic dataset and are organized by candle frequency. Each scenario fetches historical candles and streams live data.

**Prerequisites:** A running local Datafye environment (see [Provision a Local Datafye Environment](#1-provision-a-local-datafye-environment) above). The Synthetic quickstart provides 10 symbols with 90 days of historical data and live tick/OHLC data. All commands assume you are in the extracted distribution directory.

**What to look for:** Historical fetch samples run 100 iterations and print average candle count and latency. Verify candle counts are non-zero and consistent between REST and Java. Live streaming samples receive 1000 messages then exit automatically.

### Scenario 1: Second Candles

Historical second-frequency candles for AAPL, MSFT, and GOOGL on a single day. Fetch and stream for AAPL and MSFT over a 3-hour window.

**Fetch historical candles (REST):**

```bash
bin/run.sh get-historical-candles-rest -s AAPL -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-rest -s MSFT -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

**Fetch historical candles (Java):**

```bash
bin/run.sh get-historical-candles-java -s AAPL -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-java -s MSFT -c Second -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

**Stream live data for AAPL and MSFT:**

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT
bin/run.sh stream-live-trades-java -s AAPL,MSFT
```

### Scenario 2: Minute Candles

Same structure as Scenario 1 but with minute-frequency candles, plus live candle fetching, live top-of-book, and concurrent access.

**Fetch historical candles (REST):**

```bash
bin/run.sh get-historical-candles-rest -s AAPL -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-rest -s MSFT -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

**Fetch historical candles (Java):**

```bash
bin/run.sh get-historical-candles-java -s AAPL -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
bin/run.sh get-historical-candles-java -s MSFT -c Minute -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00
```

**Fetch live candles:**

```bash
bin/run.sh get-live-candles-rest -s AAPL
bin/run.sh get-live-candles-java -s AAPL
bin/run.sh get-live-candles-rest -s MSFT
bin/run.sh get-live-candles-java -s MSFT
```

**Fetch live top-of-book quotes:**

```bash
bin/run.sh get-live-top-of-book-rest -s AAPL,MSFT,GOOGL
bin/run.sh get-live-top-of-book-java -s AAPL,MSFT,GOOGL
```

**Fetch live candles concurrently:**

```bash
bin/run.sh get-live-candles-concurrently-rest -c 4
```

**Stream live data:**

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT
bin/run.sh stream-live-trades-java -s AAPL,MSFT
```

### Scenario 3: Day Candles

Historical day-frequency candles for AAPL, MSFT, and GOOGL over a 5-day window (2024-01-15 through 2024-01-19). Fetch and stream for AAPL and MSFT over a 3-day subset.

**Fetch historical candles (REST):**

```bash
bin/run.sh get-historical-candles-rest -s AAPL -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
bin/run.sh get-historical-candles-rest -s MSFT -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
```

**Fetch historical candles (Java):**

```bash
bin/run.sh get-historical-candles-java -s AAPL -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
bin/run.sh get-historical-candles-java -s MSFT -c Day -f 2024-01-16T00:00:00 -t 2024-01-18T23:59:59
```

**Stream live data:**

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT,GOOGL
bin/run.sh stream-live-trades-java -s AAPL,MSFT,GOOGL
```

### Historical Streaming (SIP Dataset)

The historical streaming samples use the SIP History client, which requires SIP data provisioned with an external provider (e.g., Polygon). If your environment has SIP data:

```bash
bin/run.sh stream-historical-candles-java -s AAPL -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00 -r 1000
bin/run.sh stream-historical-candles-concurrently-java -f 2024-01-15 -c 4 -r 1000
```

The stream sample prints a start message, streams candles, then prints an end message with the total count. The concurrent sample runs multiple streams in parallel across different date offsets.
