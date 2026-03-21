# Datafye Samples

Sample code for working with [Datafye](https://developer.datafye.io) deployments.

- [What is Datafye?](#what-is-datafye)
- [Concepts](#concepts)
  - [Environments](#environments)
  - [Data Horizon](#data-horizon)
  - [Delivery Modes](#delivery-modes)
  - [Backtesting](#backtesting-concepts)
- [What's in This Repo](#whats-in-this-repo)
  - [Data Cloud API Samples](#data-cloud-api-samples)
  - [Broker Connector API Samples](#broker-connector-api-samples)
  - [Algo Container Samples](#algo-container-samples)
- [Build](#build)
- [Running the Samples](#running-the-samples)

## What is Datafye?

Datafye is a cloud platform that democratizes institutional-grade algorithmic trading. Built on [Rumi](https://developer.rumi.systems) - the same distributed systems foundation used in sophisticated institutional trading stacks - Datafye is a single platform offering institutional-quality algorithm development and trading infrastructure, designed to be built and operated with an AI co-developer. AI is natively integrated into the tooling and drives the entire strategy lifecycle - from ideation and backtesting to optimization and live trading - using the data providers and brokers you choose. You focus on the idea and logic; Datafye handles the heavy lifting.

- [developer.datafye.io](https://developer.datafye.io) — An introduction to Datafye through guided questions and chat
- [docs.datafye.io](https://docs.datafye.io) — Developer documentation

## Concepts

Four ideas come up throughout the samples: **environments**, **data horizon**, **delivery modes**, and **backtesting**. Understanding how they fit together will make the sample tables below much easier to follow.

### Environments

Datafye supports two types of environments:

- **Foundry** — A self-contained sandbox for strategy development and backtesting. A Foundry runs locally (or in the cloud) with downloaded historical data. There is no connection to a live market or broker. Ticks are replayed from stored data to simulate a live trading session, letting you develop and test strategies without risking real capital or requiring live market access.

- **Trading** — An environment connected to a real market data feed and, optionally, a broker for order execution. Used for both paper trading and live trading. Data flows directly from the exchange, and orders can be routed to a broker.

The same APIs work in both environments. Code written against a Foundry requires no changes to run in a Trading environment — only the data source changes.

### Data Horizon

Every piece of market data falls into one of two horizons relative to the **current trading day**:

- **Live** — Data from the current trading day. In a Trading environment, this is literally today's market activity arriving in real time from the exchange. In a Foundry, it is the simulated trading day produced by replaying downloaded historical ticks (see [Backtesting](#backtesting-concepts) below). Live data includes top-of-book quotes, last trades, and intraday aggregates (OHLC, SMA, EMA). It can be [fetched](#fetch) or [subscribed to](#subscribe), but not streamed.

- **Historical** — Data from trading days prior to the current one. Available in both Foundry and Trading environments. Historical aggregates can be [fetched](#fetch) in both environments, or [streamed](#stream) in a Foundry. Historical ticks are not accessed directly — in a Foundry, they are [downloaded](#download) and then [replayed](#replay) to produce live data.

The distinction matters because the delivery modes available to you depend on which horizon the data belongs to:

| | Fetch | Subscribe | Stream |
|---|:---:|:---:|:---:|
| **Live** (ticks, aggregates) | Yes | Yes | — |
| **Historical** (aggregates) | Yes | — | Foundry only |
| **Historical** (ticks) | — | — | — (download & replay instead) |

<h3 id="delivery-modes">Delivery Modes</h3>

How data gets from the Data Cloud to your code.

<h5 id="fetch">Fetch</h5>

Request-response. Client sends a request, gets back a complete result. Works for both live and historical data.

<h5 id="stream">Stream</h5>

Server pushes data one record at a time over a dedicated channel. Efficient for large historical datasets — for example, streaming months of minute-bar OHLC data without loading it all into memory at once. Available for historical aggregates in a Foundry only.

<h5 id="subscribe">Subscribe</h5>

Client subscribes and receives live updates as they occur in real time. Use this to watch quotes, trades, or aggregates update throughout the current trading day.

<h3 id="backtesting-concepts">Backtesting</h3>

Backtesting lets you test a strategy against historical market conditions. It is available only in a Foundry and always starts with a download.

<h5 id="download">Download (prerequisite)</h5>

Downloads historical data from the data provider into the Foundry's local store. You can download ticks (trades and/or quotes) and aggregates (OHLC). Downloads are long-running operations with lifecycle APIs to check status and cancel.

Once data is downloaded, there are three ways to consume it — choose based on what your strategy needs:

<h5 id="fetch-aggs">Fetch</h5>

[Fetch](#fetch) downloaded historical aggregates on demand. Suitable when your strategy needs specific aggregate windows.

<h5 id="stream-aggs">Stream</h5>

[Stream](#stream) downloaded historical aggregates record by record. Efficient when your strategy needs to process large volumes of aggregate data — for example, months of minute-bar OHLC — without loading it all into memory.

<h5 id="replay">Replay</h5>

[Replays](#replay) downloaded tick data to produce a simulated live feed within the Foundry. The day being replayed becomes the current trading day — the replayed ticks are the environment's "live" data. Once a replay is running, your code can fetch and subscribe to live quotes, trades, and aggregates exactly as it would against a real market. Replays have lifecycle APIs to check status and stop.

**If your strategy only needs aggregates**, you can download aggs and fetch or stream them directly — no tick replay required. **If your strategy needs tick-level data** (quotes, trades), you must download and replay ticks. Replay also produces live aggregates, so a tick replay covers both cases.

## What's in This Repo

This repo contains samples for three types of Datafye APIs:

### Data Cloud API Samples

For [Foundry: Data Cloud Only](https://docs.datafye.io/quickstart/foundry-data-cloud-only) and [Trading: Data Cloud + Broker](https://docs.datafye.io/quickstart/trading-data-cloud-broker) environments — where you bring your own algo container and use the Data Cloud's REST and client APIs to access market data.

These samples demonstrate three access modes:

1. **REST API** — Standard HTTP/JSON request-response. The samples use [OkHttp](https://square.github.io/okhttp/) but any HTTP client in any language works.

2. **WebSocket API** — Streaming and subscription over WebSocket connections. This is the streaming counterpart to the REST API for those not using the Java Client.

3. **Java Client API** — A native Java library (built on the [Rumi](https://developer.rumi.systems) framework) that communicates directly with the Data Cloud and Broker Connector over the cloud's messaging backbone. Supports request-reply, streaming, and subscription through a single client. Bypasses the HTTP layer entirely for lower latency.

#### Sample Packages

| API | Package | Source |
|-----|---------|--------|
| REST | `com.datafye.samples.rest.*` | [src/.../rest](src/main/java/com/datafye/samples/rest) |
| WebSocket | `com.datafye.samples.ws` | [src/.../ws](src/main/java/com/datafye/samples/ws) |
| Java Client | `com.datafye.samples.java.*` | [src/.../java](src/main/java/com/datafye/samples/java) |

The tables below cover stocks. Equivalent crypto samples are planned.

#### Health

<table>
<tr><th>Operation</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td>Ping</td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/health/Ping.java">Ping</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Reference

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="2" style="vertical-align:middle">Securities</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/reference/GetSecurities.java">GetSecurities</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/reference/GetSecurities.java">GetSecurities</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Live — Ticks

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="4" style="vertical-align:middle">Top-of-Book Quotes</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/live/ticks/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/ticks/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveTopOfBook</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/ticks/SubscribeLiveTopOfBook.java">SubscribeLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="4" style="vertical-align:middle">Trades</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/live/ticks/GetLiveLastTrade.java">GetLiveLastTrade</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/ticks/GetLiveLastTrade.java">GetLiveLastTrade</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveTrades</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/ticks/SubscribeLiveTrades.java">SubscribeLiveTrades</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Live — Aggregates

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="4" style="vertical-align:middle">OHLC</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/live/aggregates/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/aggregates/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveOHLC</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>SubscribeLiveOHLC</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="4" style="vertical-align:middle">SMA</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/live/aggregates/GetLiveSMA.java">GetLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/aggregates/GetLiveSMA.java">GetLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveSMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>SubscribeLiveSMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="4" style="vertical-align:middle">EMA</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/live/aggregates/GetLiveEMA.java">GetLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/live/aggregates/GetLiveEMA.java">GetLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>WS</td><td>SubscribeLiveEMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>SubscribeLiveEMA</td><td align="center">✓</td><td align="center">✓</td><td><em>WIP</em></td></tr>
</table>

#### Historical Aggregates

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="5" style="vertical-align:middle">OHLC</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/history/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/history/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle"><a href="#stream">Stream</a></td><td>WS</td><td>StreamHistoricalOHLC</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/history/StreamHistoricalOHLC.java">StreamHistoricalOHLC</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/history/StreamHistoricalOHLCConcurrently.java">StreamHistoricalOHLCConcurrently</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Top Gainers</td><td rowspan="2" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td><a href="src/main/java/com/datafye/samples/rest/history/GetHistoricalTopGainers.java">GetHistoricalTopGainers</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td><a href="src/main/java/com/datafye/samples/java/history/GetHistoricalTopGainers.java">GetHistoricalTopGainers</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Backtesting

Foundry-only. See [Backtesting under Concepts](#backtesting-concepts) for how download and replay work together.

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="12" style="vertical-align:middle">Ticks</td><td rowspan="6" style="vertical-align:middle"><a href="#download">Download</a></td><td rowspan="3" style="vertical-align:middle">REST</td><td><a href="src/main/java/com/datafye/samples/rest/backtest/StartTickDownload.java">StartTickDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/IsTickDownloadRunning.java">IsTickDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/CancelTickDownload.java">CancelTickDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle">Java</td><td><a href="src/main/java/com/datafye/samples/java/backtest/StartTickDownload.java">StartTickDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/IsTickDownloadRunning.java">IsTickDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/CancelTickDownload.java">CancelTickDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="6" style="vertical-align:middle"><a href="#replay">Replay</a></td><td rowspan="3" style="vertical-align:middle">REST</td><td><a href="src/main/java/com/datafye/samples/rest/backtest/StartTickReplay.java">StartTickReplay</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/IsTickReplayRunning.java">IsTickReplayRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/StopTickReplay.java">StopTickReplay</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle">Java</td><td><a href="src/main/java/com/datafye/samples/java/backtest/StartTickReplay.java">StartTickReplay</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/IsTickReplayRunning.java">IsTickReplayRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/StopTickReplay.java">StopTickReplay</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="6" style="vertical-align:middle">Trades</td><td rowspan="6" style="vertical-align:middle"><a href="#download">Download</a></td><td rowspan="3" style="vertical-align:middle">REST</td><td><a href="src/main/java/com/datafye/samples/rest/backtest/StartTradeDownload.java">StartTradeDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/IsTradeDownloadRunning.java">IsTradeDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/CancelTradeDownload.java">CancelTradeDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle">Java</td><td><a href="src/main/java/com/datafye/samples/java/backtest/StartTradeDownload.java">StartTradeDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/IsTradeDownloadRunning.java">IsTradeDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/CancelTradeDownload.java">CancelTradeDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="6" style="vertical-align:middle">Quotes</td><td rowspan="6" style="vertical-align:middle"><a href="#download">Download</a></td><td rowspan="3" style="vertical-align:middle">REST</td><td><a href="src/main/java/com/datafye/samples/rest/backtest/StartQuoteDownload.java">StartQuoteDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/IsQuoteDownloadRunning.java">IsQuoteDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/rest/backtest/CancelQuoteDownload.java">CancelQuoteDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle">Java</td><td><a href="src/main/java/com/datafye/samples/java/backtest/StartQuoteDownload.java">StartQuoteDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/IsQuoteDownloadRunning.java">IsQuoteDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/CancelQuoteDownload.java">CancelQuoteDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle">OHLC</td><td rowspan="3" style="vertical-align:middle"><a href="#download">Download</a></td><td rowspan="3" style="vertical-align:middle">Java</td><td><a href="src/main/java/com/datafye/samples/java/backtest/StartOHLCDownload.java">StartOHLCDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/IsOHLCDownloadRunning.java">IsOHLCDownloadRunning</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td><a href="src/main/java/com/datafye/samples/java/backtest/CancelOHLCDownload.java">CancelOHLCDownload</a></td><td align="center">✓</td><td align="center">X</td><td>Available</td></tr>
<tr><td style="vertical-align:middle">State</td><td style="vertical-align:middle">Clear</td><td>REST</td><td>ClearBacktestState</td><td align="center">✓</td><td align="center">X</td><td><em>WIP</em></td></tr>
</table>

### Broker Connector API Samples

For [Trading: Data Cloud + Broker](https://docs.datafye.io/quickstart/trading-data-cloud-broker) environments — where you connect to a broker for order management and execution.

<table>
<tr><th>Operation</th><th>API</th><th>Sample</th><th>Status</th></tr>
<tr><td rowspan="2" style="vertical-align:middle">Place order</td><td>REST</td><td>PlaceOrder</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>PlaceOrder</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Get orders</td><td>REST</td><td>GetOrders</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetOrders</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Get order</td><td>REST</td><td>GetOrder</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>GetOrder</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Cancel order</td><td>REST</td><td>CancelOrder</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>CancelOrder</td><td><em>WIP</em></td></tr>
</table>

### Algo Container Samples

For [Foundry: Full Stack](https://docs.datafye.io/quickstart/foundry-full-stack) and [Trading: Full Stack](https://docs.datafye.io/quickstart/trading-full-stack) environments — where you use the Datafye Algo Container and build your algo logic with the Datafye SDK.

> **Work in progress.** Algo container samples are coming soon.

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

## Running the Samples

### 1. Provision a Local Datafye Environment

The samples need a running Datafye environment to connect to. The easiest way to get one is to provision a local environment using the Datafye CLI.

**Install the Datafye CLI:**

```bash
curl -fsSL https://downloads.n5corp.com/datafye/cli/latest/install.sh | sudo bash
```

> No sudo access? See [CLI Installation](https://docs.datafye.io/cli-reference/installation) for alternative methods.

**Download the quickstart descriptor and provision:**

**Option A: Synthetic Data (no API keys required)**

```bash
curl -o quickstart.yaml https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-synthetic.yaml
datafye foundry local provision --descriptor quickstart.yaml
```

**Option B: Real Market Data (SIP via Polygon)**

```bash
export POLYGON_API_KEY="your-polygon-api-key"
curl -o quickstart.yaml https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-sip.yaml
datafye foundry local provision --descriptor quickstart.yaml
```

Both options provision a Data Cloud with 10 symbols (AAPL, MSFT, GOOGL, AMZN, NVDA, TSLA, META, NFLX, AMD, INTC), 90 days of historical data, and live tick and OHLC data. The Synthetic option requires no API keys; the SIP option uses real market data via [Polygon](https://polygon.io).

For full details see the [Foundry: Data Cloud Only](https://docs.datafye.io/quickstart/foundry-data-cloud-only) quickstart, or explore other quickstart scenarios in the [Datafye docs](https://docs.datafye.io).

### 2. Run a Sample

Use `bin/run.sh` (Linux/macOS) or `bin\run.bat` (Windows) from the extracted distribution directory. The scripts handle JVM options and classpath automatically.

```bash
bin/run.sh <sample-name> [options]
```

Use `--help` to see all available samples, or `--help` after a sample name to see its options:

```bash
bin/run.sh --help
bin/run.sh get-historical-ohlc-rest --help
```

**Example:**

```bash
bin/run.sh get-historical-ohlc-rest -s AAPL -c Minute -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

### Configuration

Each sample embeds its connection config directly in a `static {}` block at the top of the class. By default they point to `solace.rumi.local:55555` (messaging backbone) and `api.rest.rumi.local:7776` (REST API) — which is what the quickstart descriptor provisions. If your environment uses different hosts or ports, update the `System.setProperty()` calls in the sample you're running.
