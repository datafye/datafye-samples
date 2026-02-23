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

#### Sample Packages

| API | Package | Source |
|-----|---------|--------|
| REST | `com.datafye.samples.rest` | [src/.../rest](src/main/java/com/datafye/samples/rest) |
| WebSocket | `com.datafye.samples.ws` | [src/.../ws](src/main/java/com/datafye/samples/ws) |
| Java Client | `com.datafye.samples.java` | [src/.../java](src/main/java/com/datafye/samples/java) |

#### Delivery Modes

<h5 id="fetch">Fetch</h5>

Request-response. Client sends a request, gets back a complete result.

<h5 id="stream">Stream</h5>

Server pushes data one record at a time over a dedicated channel. Efficient for large historical datasets.

<h5 id="subscribe">Subscribe</h5>

Client subscribes and receives live updates as they occur in real time.

#### Backtesting Operations

<h5 id="download">Download</h5>

Downloads historical data from the data provider into the Foundry's local store for backtesting. Includes lifecycle operations to check download status and cancel a running download.

<h5 id="replay">Replay</h5>

Replays downloaded historical tick data to produce a simulated live feed within the Foundry. Includes lifecycle operations to check replay status and stop a running replay.

The tables below cover stocks. Equivalent crypto samples are planned.

#### Reference

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="2" style="vertical-align:middle">Securities</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>GetSecurities</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetSecurities</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
</table>

#### Historical

Historical data is available in a Foundry only.

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="5" style="vertical-align:middle">OHLC</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle"><a href="#stream">Stream</a></td><td>WS</td><td>StreamHistoricalOHLC</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/StreamHistoricalOHLC.java">StreamHistoricalOHLC</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/StreamHistoricalOHLCConcurrently.java">StreamHistoricalOHLCConcurrently</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Top Gainers</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>GetHistoricalTopGainers</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetHistoricalTopGainers</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
</table>

#### Live

In a Foundry, live data is produced by replaying historical tick data — see [Backtesting](#backtesting) for how to download and replay ticks. In a Trading Environment, live data comes directly from the market. The same fetch and subscribe APIs apply in both cases.

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="4" style="vertical-align:middle">Top-of-Book</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveTopOfBook</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/SubscribeLiveTopOfBook.java">SubscribeLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="4" style="vertical-align:middle">Trades</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>GetLastTrade</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetLastTrade</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveTrades</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/SubscribeLiveTrades.java">SubscribeLiveTrades</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="5" style="vertical-align:middle">OHLC</td><td rowspan="3" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/GetLiveOHLCConcurrently.java">GetLiveOHLCConcurrently</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveOHLC</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>SubscribeLiveOHLC</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">SMA</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>GetLiveSMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetLiveSMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">EMA</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>GetLiveEMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetLiveEMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
</table>

#### Backtesting

Backtesting samples are Foundry-only. They demonstrate downloading historical data from the data provider and replaying ticks to produce live data for fetch and subscribe operations.

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Samples</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="4" style="vertical-align:middle">Ticks</td><td rowspan="2" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>DownloadTickHistory, IsTickDownloadRunning, CancelTickDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>DownloadTickHistory, IsTickDownloadRunning, CancelTickDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#replay">Replay</a></td><td>REST</td><td>ReplayTicks, IsTickReplayRunning, StopTickReplay</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>ReplayTicks, IsTickReplayRunning, StopTickReplay</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Trades</td><td rowspan="2" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>DownloadTradeHistory, IsTradeDownloadRunning, CancelTradeDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>DownloadTradeHistory, IsTradeDownloadRunning, CancelTradeDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Quotes</td><td rowspan="2" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>DownloadQuoteHistory, IsQuoteDownloadRunning, CancelQuoteDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>DownloadQuoteHistory, IsQuoteDownloadRunning, CancelQuoteDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td style="vertical-align:middle">OHLC</td><td style="vertical-align:middle"><a href="#download">Download</a></td><td>Java</td><td>DownloadOHLCHistory, IsOHLCDownloadRunning, CancelOHLCDownload</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td style="vertical-align:middle">State</td><td style="vertical-align:middle">Clear</td><td>REST</td><td>ClearBacktestState</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
</table>

#### Broker

Broker samples are available in Trading Environments only.

<table>
<tr><th>Operation</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="2" style="vertical-align:middle">Place order</td><td>REST</td><td>PlaceOrder</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>PlaceOrder</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Get orders</td><td>REST</td><td>GetOrders</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetOrders</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Get order</td><td>REST</td><td>GetOrder</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetOrder</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Cancel order</td><td>REST</td><td>CancelOrder</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>CancelOrder</td><td align="center">X</td><td align="center">✓</td><td><em>WIP</em></td></tr>
</table>

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
bin/run.sh get-historical-ohlc-rest -s AAPL -c Minute -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

Use `bin/run.sh --help` to see all available samples.

For detailed per-sample instructions, configuration, and scenario guides, see the [wiki](../../wiki).
