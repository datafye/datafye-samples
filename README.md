# Datafye Samples

Sample code and guides for working with [Datafye](https://developer.datafye.io) deployments.

## What is Datafye?

Datafye is a cloud platform that democratizes institutional-grade algorithmic trading. Built on [Rumi](https://developer.rumi.systems) -- the same distributed systems foundation used in sophisticated institutional trading stacks -- Datafye is a single platform offering institutional-quality algorithm development and trading infrastructure, designed to be built and operated with an AI co-developer. AI is natively integrated into the tooling and drives the entire strategy lifecycle -- from ideation and backtesting to optimization and live trading -- using the data providers and brokers you choose. You focus on the idea and logic; Datafye handles the heavy lifting.

- [developer.datafye.io](https://developer.datafye.io) — Get introduced to Datafye through guided questions and chat
- [docs.datafye.io](https://docs.datafye.io) — Developer documentation

## What's in This Repo

This repo contains samples for two types of Datafye environments:

### Data Cloud API Samples

For [Foundry: Data Cloud Only](https://docs.datafye.io/quickstart/foundry-data-cloud-only) and [Trading: Data Cloud + Broker](https://docs.datafye.io/quickstart/trading-data-cloud-broker) environments — where you bring your own algo container and use the Data Cloud's REST and client APIs to access market data and broker connectivity.

These samples demonstrate two access modes:

1. **REST API** — Standard HTTP/JSON requests. The samples use [OkHttp](https://square.github.io/okhttp/) but any HTTP client in any language works. Good for straightforward request-response queries (historical candles, live quotes). WebSocket support for streaming will be available shortly.

2. **Java Client API** — A native Java library (built on the [Rumi](https://developer.rumi.systems) framework) that communicates directly with Data Cloud backend services over the cloud's messaging backbone. This bypasses the HTTP layer entirely, giving you lower latency.

#### REST API Samples (`com.datafye.samples.rest`)

| Name | Main Class | Description |
|------|------------|-------------|
| **GetHistoricalCandles** | `com.datafye.samples.rest.GetHistoricalCandles` | Fetch historical OHLC candles for a symbol and time range |
| **GetLiveCandles** | `com.datafye.samples.rest.GetLiveCandles` | Fetch current trading day candles for a symbol |
| **GetLiveTopOfBook** | `com.datafye.samples.rest.GetLiveTopOfBook` | Fetch live top-of-book bid/ask quotes for one or more symbols |
| **GetLiveCandlesConcurrently** | `com.datafye.samples.rest.GetLiveCandlesConcurrently` | Fetch live candles for all symbols in parallel using a thread pool |

#### Java Client API Samples (`com.datafye.samples.java`)

| Name | Main Class | Description |
|------|------------|-------------|
| **GetHistoricalCandles** | `com.datafye.samples.java.GetHistoricalCandles` | Fetch historical OHLC candles (request-reply pattern) |
| **GetLiveCandles** | `com.datafye.samples.java.GetLiveCandles` | Fetch current trading day candles (request-reply pattern) |
| **GetLiveTopOfBook** | `com.datafye.samples.java.GetLiveTopOfBook` | Fetch live top-of-book quotes (request-reply pattern) |
| **StreamHistoricalCandles** | `com.datafye.samples.java.StreamHistoricalCandles` | Stream historical candles with rate throttling (streaming pattern) |
| **StreamHistoricalCandlesConcurrently** | `com.datafye.samples.java.StreamHistoricalCandlesConcurrently` | Stream historical candles across multiple concurrent streams |
| **StreamLiveTopOfBook** | `com.datafye.samples.java.StreamLiveTopOfBook` | Subscribe to live top-of-book quotes in real time (subscribe/unsubscribe pattern) |
| **StreamLiveTrades** | `com.datafye.samples.java.StreamLiveTrades` | Subscribe to live trades in real time (subscribe/unsubscribe pattern) |

### Algo Container Samples

For [Foundry: Full Stack](https://docs.datafye.io/quickstart/foundry-full-stack) and [Trading: Full Stack](https://docs.datafye.io/quickstart/trading-full-stack) environments — where you use the Datafye Algo Container and build your algo logic with the Datafye SDK.

> **Work in progress.** Algo container samples and guides are coming soon.

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
