# Running the Samples

## 1. Provision a Local Datafye Environment

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

## 2. Run the Samples

All commands below assume you are in the extracted distribution directory (`datafye-samples-2.0-SNAPSHOT`). Use `bin/run.sh` (Linux/macOS) or `bin\run.bat` (Windows) to run any sample. The scripts handle JVM options and classpath automatically.

To see all available samples:

```bash
bin/run.sh --help
```

### REST: Get Historical Candles

```bash
bin/run.sh get-historical-candles-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required) — Stock symbol
- `-c, --frequency` (default: `Minute`) — Candle frequency (`Second`, `Minute`, `Hour`, `Day`)
- `-f, --from` (required) — Start time (`yyyy-MM-dd'T'HH:mm:ss`)
- `-t, --to` (required) — End time

### REST: Get Live Candles

```bash
bin/run.sh get-live-candles-rest -s AAPL
```

Options:
- `-s, --symbol` (required) — Stock symbol

### REST: Get Live Top-Of-Book Quotes

```bash
bin/run.sh get-live-top-of-book-rest -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

### REST: Get Live Candles Concurrently

```bash
bin/run.sh get-live-candles-concurrently-rest -c 4
```

Options:
- `-c, --concurrency` (default: `1`) — Number of concurrent threads

### Java: Get Historical Candles

```bash
bin/run.sh get-historical-candles-java -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Options:
- `-s, --symbol` (required) — Stock symbol
- `-c, --frequency` (default: `Minute`) — Candle frequency
- `-f, --from` (required) — Start time
- `-t, --to` (required) — End time

### Java: Get Live Candles

```bash
bin/run.sh get-live-candles-java -s AAPL
```

Options:
- `-s, --symbol` (required) — Stock symbol

### Java: Get Live Top-Of-Book Quotes

```bash
bin/run.sh get-live-top-of-book-java -s AAPL,MSFT,GOOGL
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

### Java: Stream Historical Candles

```bash
bin/run.sh stream-historical-candles-java -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00 -r 1000
```

Options:
- `-s, --symbol` (optional) — Symbol to stream (omit for all symbols)
- `-f, --from` (required) — Start time
- `-t, --to` (required) — End time
- `-r, --rate` (default: `0`) — Max streaming rate (`0` = unlimited)

> **Note:** Streaming samples use the SIP History client. Ensure the SIP dataset is deployed in your Datafye environment.

### Java: Stream Historical Candles Concurrently

```bash
bin/run.sh stream-historical-candles-concurrently-java -f 2024-01-15 -c 4 -r 1000
```

Options:
- `-i, --instance` (default: `0`) — Client instance ID
- `-c, --concurrency` (default: `1`) — Number of concurrent streams
- `-f, --from` (required) — Base date (`yyyy-MM-dd`)
- `-r, --rate` (default: `0`) — Max streaming rate (`0` = unlimited)

### Java: Stream Live Top-Of-Book Quotes

```bash
bin/run.sh stream-live-top-of-book-java -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

Subscribes to live top-of-book quotes, prints 1000 incoming quotes, then unsubscribes and exits.

### Java: Stream Live Trades

```bash
bin/run.sh stream-live-trades-java -s AAPL,MSFT,GOOGL,AMZN
```

Options:
- `-s, --symbols` (required) — Comma-separated symbols

Subscribes to live trades, prints 1000 incoming trades, then unsubscribes and exits.

## Configuration

Each sample embeds its connection config directly in a `static {}` block at the top of the class. By default they point to `solace.rumi.local:55555` (messaging backbone) and `api.rest.rumi.local:7776` (REST API) — which is what the quickstart descriptor provisions. If your environment uses different hosts or ports, update the `System.setProperty()` calls in the sample you're running.

The `conf/rumi.conf` file is included in the distribution for optional Rumi runtime tuning (trace levels, etc.) but is not required for connection configuration.
