# Datafye Samples

Sample code and guides that use these samples for working with [Datafye](https://developer.datafye.io) deployments.

## What is Datafye?

Datafye is a cloud platform that democratizes institutional-grade algorithmic trading. Built on [Rumi](https://developer.rumi.systems) - the same distributed systems foundation used in sophisticated institutional trading stacks - Datafye is a single platform offering institutional-quality algorithm development and trading infrastructure, designed to be built and operated with an AI co-developer. AI is natively integrated into the tooling and drives the entire strategy lifecycle - from ideation and backtesting to optimization and live trading - using the data providers and brokers you choose. You focus on the idea and logic; Datafye handles the heavy lifting.

- [developer.datafye.io](https://developer.datafye.io) — An introduction to Datafye through guided questions and chat
- [docs.datafye.io](https://docs.datafye.io) — Developer documentation

## What's in This Repo

This repo contains samples for two types of Datafye environments:

### Data Cloud API Samples

For [Foundry: Data Cloud Only](https://docs.datafye.io/quickstart/foundry-data-cloud-only) and [Trading: Data Cloud + Broker](https://docs.datafye.io/quickstart/trading-data-cloud-broker) environments — where you bring your own algo container and use the Data Cloud's REST and client APIs to access market data and broker connectivity.

These samples demonstrate three access modes:

1. **REST API** — Standard HTTP/JSON request-response. The samples use [OkHttp](https://square.github.io/okhttp/) but any HTTP client in any language works.

2. **WebSocket API** — Streaming and subscription over WebSocket connections. This is the streaming counterpart to the REST API for those not using the Java Client.

3. **Java Client API** — A native Java library (built on the [Rumi](https://developer.rumi.systems) framework) that communicates directly with the Data Cloud and Broker Connector over the cloud's messaging backbone. Supports request-reply, streaming, and subscription through a single client. Bypasses the HTTP layer entirely for lower latency.

> **Sample packages:** REST samples are in `c.d.s.rest`, WebSocket samples in `c.d.s.ws`, and Java Client samples in `c.d.s.java` (where `c.d.s` = `com.datafye.samples`).

The tables below cover stocks. Equivalent crypto samples are planned.

#### Reference

| Data Type | Mode | API | Sample | Foundry | Trading | Status |
|-----------|------|-----|--------|:-------:|:-------:|--------|
| Securities | Fetch | REST | GetSecurities | ✓ | ✓ | *WIP* |
| Securities | Fetch | Java | GetSecurities | ✓ | ✓ | *WIP* |

#### Historical

Historical data is available in a Foundry only.

| Data Type | Mode | API | Sample | Foundry | Trading | Status |
|-----------|------|-----|--------|:-------:|:-------:|--------|
| Candles | Fetch | REST | GetHistoricalCandles | ✓ | — | Available |
| Candles | Fetch | Java | GetHistoricalCandles | ✓ | — | Available |
| Candles | Stream | WS | StreamHistoricalCandles | ✓ | — | *WIP* |
| Candles | Stream | Java | StreamHistoricalCandles | ✓ | — | Available |
| Candles | Stream | Java | StreamHistoricalCandlesConcurrently | ✓ | — | Available |
| Ticks | Fetch | REST | GetHistoricalTicks | ✓ | — | *WIP* |
| Ticks | Fetch | Java | GetHistoricalTicks | ✓ | — | *WIP* |
| Ticks | Stream | WS | StreamHistoricalTicks | ✓ | — | *WIP* |
| Ticks | Stream | Java | StreamHistoricalTicks | ✓ | — | *WIP* |
| Top Gainers | Fetch | REST | GetHistoricalTopGainers | ✓ | — | *WIP* |
| Top Gainers | Fetch | Java | GetHistoricalTopGainers | ✓ | — | *WIP* |

#### Live

In a Foundry, live data is produced by replaying historical tick data — see [Backtesting](#backtesting) for how to download and replay ticks. In a Trading Environment, live data comes directly from the market. The same fetch and subscribe APIs apply in both cases.

| Data Type | Mode | API | Sample | Foundry | Trading | Status |
|-----------|------|-----|--------|:-------:|:-------:|--------|
| Candles | Fetch | REST | GetLiveCandles | ✓ | ✓ | Available |
| Candles | Fetch | REST | GetLiveCandlesConcurrently | ✓ | ✓ | Available |
| Candles | Fetch | Java | GetLiveCandles | ✓ | ✓ | Available |
| Candles | Subscribe | WS | SubscribeLiveCandles | ✓ | ✓ | *WIP* |
| Candles | Subscribe | Java | SubscribeLiveCandles | ✓ | ✓ | *WIP* |
| Top-of-Book | Fetch | REST | GetLiveTopOfBook | ✓ | ✓ | Available |
| Top-of-Book | Fetch | Java | GetLiveTopOfBook | ✓ | ✓ | Available |
| Top-of-Book | Subscribe | WS | SubscribeLiveTopOfBook | ✓ | ✓ | *WIP* |
| Top-of-Book | Subscribe | Java | StreamLiveTopOfBook | ✓ | ✓ | Available |
| Trades | Fetch | REST | GetLastTrade | ✓ | ✓ | *WIP* |
| Trades | Subscribe | WS | SubscribeLiveTrades | ✓ | ✓ | *WIP* |
| Trades | Subscribe | Java | StreamLiveTrades | ✓ | ✓ | Available |
| SMA | Fetch | REST | GetLiveSMA | ✓ | ✓ | *WIP* |
| SMA | Fetch | Java | GetLiveSMA | ✓ | ✓ | *WIP* |
| EMA | Fetch | REST | GetLiveEMA | ✓ | ✓ | *WIP* |
| EMA | Fetch | Java | GetLiveEMA | ✓ | ✓ | *WIP* |

#### Backtesting

Backtesting samples are Foundry-only. They demonstrate downloading historical data from the data provider and replaying ticks to produce live data for fetch and subscribe operations.

| Operation | API | Sample | Foundry | Trading | Status |
|-----------|-----|--------|:-------:|:-------:|--------|
| Download ticks | REST | DownloadTickHistory | ✓ | — | *WIP* |
| Download ticks | Java | DownloadTickHistory | ✓ | — | *WIP* |
| Download trades | REST | DownloadTradeHistory | ✓ | — | *WIP* |
| Download trades | Java | DownloadTradeHistory | ✓ | — | *WIP* |
| Download quotes | REST | DownloadQuoteHistory | ✓ | — | *WIP* |
| Download quotes | Java | DownloadQuoteHistory | ✓ | — | *WIP* |
| Replay ticks | REST | ReplayTicks | ✓ | — | *WIP* |
| Replay ticks | Java | ReplayTicks | ✓ | — | *WIP* |
| Clear state | REST | ClearBacktestState | ✓ | — | *WIP* |

#### Broker

Broker samples are available in Trading Environments only.

| Operation | API | Sample | Foundry | Trading | Status |
|-----------|-----|--------|:-------:|:-------:|--------|
| Place order | REST | PlaceOrder | — | ✓ | *WIP* |
| Place order | Java | PlaceOrder | — | ✓ | *WIP* |
| Get orders | REST | GetOrders | — | ✓ | *WIP* |
| Get orders | Java | GetOrders | — | ✓ | *WIP* |
| Cancel order | REST | CancelOrder | — | ✓ | *WIP* |
| Cancel order | Java | CancelOrder | — | ✓ | *WIP* |

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
