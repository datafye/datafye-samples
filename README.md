# Datafye Client Samples

Sample code demonstrating how to interact with a [Datafye](https://developer.datafye.io) deployment using both the REST API and the native Java Client API.

## What is Datafye?

[Datafye](https://developer.datafye.io) provides infrastructure for building and running algorithmic trading systems. At its core is the **Data Cloud** — a service that provides normalized, low-latency access to historical and live market data across multiple asset classes (equities, options, crypto, etc.) and data providers (Polygon, Alpaca, and others).

A Datafye deployment is a private, isolated environment — your own dedicated instance with its own compute, storage, and network resources. Deployments come in two types:

- **Foundry** — For algo development, backtesting, and research. No broker connectivity.
- **Trading Environment** — Everything in a foundry, plus a broker connector for paper and live trading.

Each type has two flavors depending on whether you bring your own algo container or use Datafye's:

- **Your own algo container** — Datafye provisions the Data Cloud (and broker connector for Trading Environments); you bring your own algo containers and connect them to the Data Cloud APIs. This is called *Data Cloud Only* for foundries and *Data Cloud + Broker* for trading environments.
- **Datafye algo container** — Datafye provisions everything: the Data Cloud, algo container runtime, backtesting engine, and MCP server (plus broker connector for Trading Environments). You write your algo logic using the Datafye SDK; Datafye handles the rest. This is the *Full Stack* flavor.

These samples are designed for the **Foundry: Data Cloud Only** scenario — they connect directly to a Data Cloud's REST and messaging endpoints to fetch and stream market data. Deployments can be provisioned locally on your machine (for development and testing) or in the cloud (for production) using the [Datafye CLI](https://docs.datafye.io/concepts-and-architecture/cli). You describe what data you need in a [data descriptor](https://docs.datafye.io/concepts-and-architecture/the-data-cloud/data-descriptors), and the CLI provisions the environment for you.

## What These Samples Show

These samples demonstrate the two ways to access market data from a Datafye deployment's Data Cloud:

1. **REST API** — Standard HTTP/JSON requests. The samples use [OkHttp](https://square.github.io/okhttp/) but any HTTP client in any language works. Good for straightforward request-response queries (historical candles, live quotes). WebSocket support for streaming will be available shortly.

2. **Java Client API** — A native Java library (built on the [Rumi](https://developer.rumi.systems) framework) that communicates directly with Data Cloud backend services over the cloud's messaging backbone. This bypasses the HTTP layer entirely, giving you lower latency.

Each sample is self-contained and shows a common data access pattern — fetching historical candles, querying live quotes, streaming trades — so you can use them as starting points for your own integrations.

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

The samples are organized into two packages that mirror the two data access modes described above:

### REST API Samples (`com.datafye.samples.rest`)

These use HTTP/JSON to query the Datafye REST API. They work from any language — Java is used here for illustration.

| Name | Main Class | Description |
|------|------------|-------------|
| **GetHistoricalCandles** | `com.datafye.samples.rest.GetHistoricalCandles` | Fetch historical OHLC candles for a symbol and time range |
| **GetLiveCandles** | `com.datafye.samples.rest.GetLiveCandles` | Fetch current trading day candles for a symbol |
| **GetLiveTopOfBook** | `com.datafye.samples.rest.GetLiveTopOfBook` | Fetch live top-of-book bid/ask quotes for one or more symbols |
| **GetLiveCandlesConcurrently** | `com.datafye.samples.rest.GetLiveCandlesConcurrently` | Fetch live candles for all symbols in parallel using a thread pool |

### Java Client Samples (`com.datafye.samples.java`)

These use the Datafye Java Client API, which communicates directly with backend services over the cloud's messaging backbone. This gives you lower latency and access to streaming — something the REST API doesn't support.

| Name | Main Class | Description |
|------|------------|-------------|
| **GetHistoricalCandles** | `com.datafye.samples.java.GetHistoricalCandles` | Fetch historical OHLC candles (request-reply pattern) |
| **GetLiveCandles** | `com.datafye.samples.java.GetLiveCandles` | Fetch current trading day candles (request-reply pattern) |
| **GetLiveTopOfBook** | `com.datafye.samples.java.GetLiveTopOfBook` | Fetch live top-of-book quotes (request-reply pattern) |
| **StreamHistoricalCandles** | `com.datafye.samples.java.StreamHistoricalCandles` | Stream historical candles with rate throttling (streaming pattern) |
| **StreamHistoricalCandlesConcurrently** | `com.datafye.samples.java.StreamHistoricalCandlesConcurrently` | Stream historical candles across multiple concurrent streams |
| **StreamLiveTopOfBook** | `com.datafye.samples.java.StreamLiveTopOfBook` | Subscribe to live top-of-book quotes in real time (subscribe/unsubscribe pattern) |
| **StreamLiveTrades** | `com.datafye.samples.java.StreamLiveTrades` | Subscribe to live trades in real time (subscribe/unsubscribe pattern) |

## Quick Start

Once you've built the project and extracted the distribution, provision a local environment and run a sample:

```bash
# Install the Datafye CLI
curl -fsSL https://downloads.n5corp.com/datafye/cli/latest/install.sh | sudo bash

# Provision a local Data Cloud with synthetic data
curl -o quickstart.yaml https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only.yaml
datafye foundry local provision --descriptor quickstart.yaml

# Run a sample (from the extracted distribution directory)
bin/run.sh get-historical-candles-rest -s AAPL -c Minute -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Use `bin/run.sh --help` to see all available samples.

For detailed per-sample instructions, configuration, and scenario guides, see the [wiki](../../wiki).
