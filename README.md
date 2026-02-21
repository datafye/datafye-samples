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

2. **Java Client API** — A native Java library (built on the [Rumi](https://developer.rumi.systems) framework) that communicates directly with the Data Cloud and Broker Connector over the cloud's messaging backbone. This bypasses the HTTP layer entirely, giving you lower latency.

#### Reference

| Data Type | Mode | API | Name | Main Class | Status |
|-----------|------|-----|------|------------|--------|
| Securities | Fetch | REST | — | — | *Work in progress* |
| Securities | Fetch | Java | — | — | *Work in progress* |

#### Historical

| Data Type | Mode | API | Name | Main Class | Status |
|-----------|------|-----|------|------------|--------|
| Candles | Fetch | REST | GetHistoricalCandles | `com.datafye.samples.rest.GetHistoricalCandles` | Available |
| Candles | Fetch | Java | GetHistoricalCandles | `com.datafye.samples.java.GetHistoricalCandles` | Available |
| Candles | Stream | Java | StreamHistoricalCandles | `com.datafye.samples.java.StreamHistoricalCandles` | Available |
| Candles | Stream | Java | StreamHistoricalCandlesConcurrently | `com.datafye.samples.java.StreamHistoricalCandlesConcurrently` | Available |
| Ticks | Fetch | REST | — | — | *Work in progress* |
| Ticks | Fetch | Java | — | — | *Work in progress* |
| Ticks | Stream | Java | — | — | *Work in progress* |

#### Live

| Data Type | Mode | API | Name | Main Class | Status |
|-----------|------|-----|------|------------|--------|
| Candles | Fetch | REST | GetLiveCandles | `com.datafye.samples.rest.GetLiveCandles` | Available |
| Candles | Fetch | REST | GetLiveCandlesConcurrently | `com.datafye.samples.rest.GetLiveCandlesConcurrently` | Available |
| Candles | Fetch | Java | GetLiveCandles | `com.datafye.samples.java.GetLiveCandles` | Available |
| Candles | Subscribe | Java | — | — | *Work in progress* |
| Ticks | Fetch | REST | GetLiveTopOfBook | `com.datafye.samples.rest.GetLiveTopOfBook` | Available |
| Ticks | Fetch | Java | GetLiveTopOfBook | `com.datafye.samples.java.GetLiveTopOfBook` | Available |
| Ticks | Subscribe | Java | StreamLiveTopOfBook | `com.datafye.samples.java.StreamLiveTopOfBook` | Available |
| Ticks | Subscribe | Java | StreamLiveTrades | `com.datafye.samples.java.StreamLiveTrades` | Available |

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
