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
- [Sanity Test](#sanity-test)
- [Build](#build)
- [Running the Samples](#running-the-samples)

## What is Datafye?

Datafye is a cloud platform that democratizes institutional-grade algorithmic trading. Built on [Rumi](https://www.rumi.systems) - the same distributed systems foundation used in sophisticated institutional trading stacks - Datafye is a single platform offering institutional-quality algorithm development and trading infrastructure, designed to be built and operated with an AI co-developer. AI is natively integrated into the tooling and drives the entire strategy lifecycle - from ideation and backtesting to optimization and live trading - using the data providers and brokers you choose. You focus on the idea and logic; Datafye handles the heavy lifting.

- [developer.datafye.io](https://developer.datafye.io) — Chat with an AI agent about Datafye — ask it anything
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

> **Note:** Fetch and stream are useful for early-stage development — quickly iterating on a signal generator or validating aggregate-based logic. However, replay is the most accurate way to backtest. Because it recreates a live trading session tick by tick, it avoids look-ahead bias and tests your strategy in an environment closest to actual trading conditions. For final validation before going live, always use replay.

## What's in This Repo

This repo contains samples for three types of Datafye APIs:

### Data Cloud API Samples

For [Foundry: Data Cloud Only](https://docs.datafye.io/quickstart/foundry-data-cloud-only) and [Trading: Data Cloud + Broker](https://docs.datafye.io/quickstart/trading-data-cloud-broker) environments — where you bring your own algo container and use the Data Cloud's REST and client APIs to access market data.

These samples demonstrate three access modes:

1. **REST API** — Standard HTTP/JSON request-response. The samples use [OkHttp](https://square.github.io/okhttp/) but any HTTP client in any language works.

2. **WebSocket API** — Streaming and subscription over WebSocket connections. This is the streaming counterpart to the REST API for those not using the Java Client.

3. **Java Client API** — A native Java library (built on the [Rumi](https://www.rumi.systems) framework) that communicates directly with the Data Cloud and Broker Connector over the cloud's messaging backbone. Supports request-reply, streaming, and subscription through a single client. Bypasses the HTTP layer entirely for lower latency.

#### Sample Packages

| API | Package | Source |
|-----|---------|--------|
| REST | `com.datafye.samples.rest.{stocks,crypto}.*` | [src/.../rest](src/main/java/com/datafye/samples/rest) |
| WebSocket | `com.datafye.samples.ws` | [src/.../ws](src/main/java/com/datafye/samples/ws) |
| Java Client | `com.datafye.samples.java.{stocks,crypto}.*` | [src/.../java](src/main/java/com/datafye/samples/java) |

**Reading the tables.** Each row is one runnable sample. The **Datasets** column lists the datasets that sample serves — **stocks** samples cover `SIP` and `Synthetic` (pass `-D SIP` / `-D Synthetic`, default `Synthetic`); **crypto** samples cover `Crypto` (launched with the `-crypto` run keys); the **WebSocket** samples are a single dataset-aware set that picks the dataset at runtime via `-d SIP|Synthetic|Crypto`. The **Sample** column links to the source for that asset class. In the **Foundry** / **Trading** columns, ✓ means supported and ✗ means not applicable in that environment. Run keys add the matching `-stocks` / `-crypto` / `-ws` suffix — see `bin/run.sh --list`.

#### Health

<table>
<tr><th>Operation</th><th>API</th><th>Datasets</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td>Ping</td><td>REST</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/health/Ping.java">Ping</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Reference

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Datasets</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="4" style="vertical-align:middle">Securities</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/reference/GetSecurities.java">GetSecurities</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/reference/GetSecurities.java">GetSecurities</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/reference/GetSecurities.java">GetSecurities</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/reference/GetSecurities.java">GetSecurities</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Live — Ticks

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Datasets</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="6" style="vertical-align:middle">Top-of-Book Quotes</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/live/ticks/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/live/ticks/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/ticks/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/ticks/GetLiveTopOfBook.java">GetLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/ticks/SubscribeLiveTopOfBook.java">SubscribeLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>WS</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/ws/SubscribeLiveTopOfBook.java">SubscribeLiveTopOfBook</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="6" style="vertical-align:middle">Trades</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/live/ticks/GetLiveLastTrade.java">GetLiveLastTrade</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/live/ticks/GetLiveLastTrade.java">GetLiveLastTrade</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/ticks/GetLiveLastTrade.java">GetLiveLastTrade</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/ticks/GetLiveLastTrade.java">GetLiveLastTrade</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="2" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/ticks/SubscribeLiveTrades.java">SubscribeLiveTrades</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>WS</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/ws/SubscribeLiveTrades.java">SubscribeLiveTrades</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Live — Aggregates

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Datasets</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="7" style="vertical-align:middle">OHLC</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/live/aggregates/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/live/aggregates/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/aggregates/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/aggregates/GetLiveOHLC.java">GetLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/aggregates/SubscribeLiveOHLC.java">SubscribeLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/aggregates/SubscribeLiveOHLC.java">SubscribeLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>WS</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/ws/SubscribeLiveOHLC.java">SubscribeLiveOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="7" style="vertical-align:middle">SMA</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/live/aggregates/GetLiveSMA.java">GetLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/live/aggregates/GetLiveSMA.java">GetLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/aggregates/GetLiveSMA.java">GetLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/aggregates/GetLiveSMA.java">GetLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/aggregates/SubscribeLiveSMA.java">SubscribeLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/aggregates/SubscribeLiveSMA.java">SubscribeLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>WS</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/ws/SubscribeLiveSMA.java">SubscribeLiveSMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="7" style="vertical-align:middle">EMA</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/live/aggregates/GetLiveEMA.java">GetLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/live/aggregates/GetLiveEMA.java">GetLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/aggregates/GetLiveEMA.java">GetLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/aggregates/GetLiveEMA.java">GetLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="3" style="vertical-align:middle"><a href="#subscribe">Subscribe</a></td><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/live/aggregates/SubscribeLiveEMA.java">SubscribeLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/live/aggregates/SubscribeLiveEMA.java">SubscribeLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>WS</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/ws/SubscribeLiveEMA.java">SubscribeLiveEMA</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Historical Aggregates

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Datasets</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="9" style="vertical-align:middle">OHLC</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/history/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/history/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/history/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/history/GetHistoricalOHLC.java">GetHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td rowspan="5" style="vertical-align:middle"><a href="#stream">Stream</a></td><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/history/StreamHistoricalOHLC.java">StreamHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/history/StreamHistoricalOHLC.java">StreamHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/history/StreamHistoricalOHLCConcurrently.java">StreamHistoricalOHLCConcurrently</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/history/StreamHistoricalOHLCConcurrently.java">StreamHistoricalOHLCConcurrently</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>WS</td><td>SIP, Synthetic, Crypto</td><td><a href="src/main/java/com/datafye/samples/ws/StreamHistoricalOHLC.java">StreamHistoricalOHLC</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td rowspan="4" style="vertical-align:middle">Top Gainers</td><td rowspan="4" style="vertical-align:middle"><a href="#fetch">Fetch</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/history/GetHistoricalTopGainers.java">GetHistoricalTopGainers</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/history/GetHistoricalTopGainers.java">GetHistoricalTopGainers</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/history/GetHistoricalTopGainers.java">GetHistoricalTopGainers</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/history/GetHistoricalTopGainers.java">GetHistoricalTopGainers</a></td><td align="center">✓</td><td align="center">✓</td><td>Available</td></tr>
</table>

#### Backtesting

Foundry-only. See [Backtesting under Concepts](#backtesting-concepts) for how download and replay work together.

<table>
<tr><th>Data Type</th><th>Mode</th><th>API</th><th>Datasets</th><th>Sample</th><th>Foundry</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="24" style="vertical-align:middle">Ticks</td><td rowspan="12" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/StartTickDownload.java">StartTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/IsTickDownloadRunning.java">IsTickDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/CancelTickDownload.java">CancelTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/StartTickDownload.java">StartTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/IsTickDownloadRunning.java">IsTickDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/CancelTickDownload.java">CancelTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/StartTickDownload.java">StartTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/IsTickDownloadRunning.java">IsTickDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/CancelTickDownload.java">CancelTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/StartTickDownload.java">StartTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/IsTickDownloadRunning.java">IsTickDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/CancelTickDownload.java">CancelTickDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td rowspan="12" style="vertical-align:middle"><a href="#replay">Replay</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/StartTickReplay.java">StartTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/IsTickReplayRunning.java">IsTickReplayRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/StopTickReplay.java">StopTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/StartTickReplay.java">StartTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/IsTickReplayRunning.java">IsTickReplayRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/StopTickReplay.java">StopTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/StartTickReplay.java">StartTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/IsTickReplayRunning.java">IsTickReplayRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/StopTickReplay.java">StopTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/StartTickReplay.java">StartTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/IsTickReplayRunning.java">IsTickReplayRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/StopTickReplay.java">StopTickReplay</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td rowspan="12" style="vertical-align:middle">Trades</td><td rowspan="12" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/StartTradeDownload.java">StartTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/IsTradeDownloadRunning.java">IsTradeDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/CancelTradeDownload.java">CancelTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/StartTradeDownload.java">StartTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/IsTradeDownloadRunning.java">IsTradeDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/CancelTradeDownload.java">CancelTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/StartTradeDownload.java">StartTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/IsTradeDownloadRunning.java">IsTradeDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/CancelTradeDownload.java">CancelTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/StartTradeDownload.java">StartTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/IsTradeDownloadRunning.java">IsTradeDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/CancelTradeDownload.java">CancelTradeDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td rowspan="12" style="vertical-align:middle">Quotes</td><td rowspan="12" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/StartQuoteDownload.java">StartQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/IsQuoteDownloadRunning.java">IsQuoteDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/CancelQuoteDownload.java">CancelQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/StartQuoteDownload.java">StartQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/IsQuoteDownloadRunning.java">IsQuoteDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/CancelQuoteDownload.java">CancelQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/StartQuoteDownload.java">StartQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/IsQuoteDownloadRunning.java">IsQuoteDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/CancelQuoteDownload.java">CancelQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/StartQuoteDownload.java">StartQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/IsQuoteDownloadRunning.java">IsQuoteDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/CancelQuoteDownload.java">CancelQuoteDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td rowspan="12" style="vertical-align:middle">OHLC</td><td rowspan="12" style="vertical-align:middle"><a href="#download">Download</a></td><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/StartOHLCDownload.java">StartOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/IsOHLCDownloadRunning.java">IsOHLCDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/rest/stocks/backtest/CancelOHLCDownload.java">CancelOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/StartOHLCDownload.java">StartOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/IsOHLCDownloadRunning.java">IsOHLCDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>REST</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/rest/crypto/backtest/CancelOHLCDownload.java">CancelOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/StartOHLCDownload.java">StartOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/IsOHLCDownloadRunning.java">IsOHLCDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>SIP, Synthetic</td><td><a href="src/main/java/com/datafye/samples/java/stocks/backtest/CancelOHLCDownload.java">CancelOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/StartOHLCDownload.java">StartOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/IsOHLCDownloadRunning.java">IsOHLCDownloadRunning</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
<tr><td>Java</td><td>Crypto</td><td><a href="src/main/java/com/datafye/samples/java/crypto/backtest/CancelOHLCDownload.java">CancelOHLCDownload</a></td><td align="center">✓</td><td align="center">✗</td><td>Available</td></tr>
</table>

### Broker Connector API Samples

For [Trading: Data Cloud + Broker](https://docs.datafye.io/quickstart/trading-data-cloud-broker) environments — where you connect to a broker for order management and execution. Broker connectivity is **stocks-only**; orders route through the broker connector in a Trading environment (not available in a Foundry).

<table>
<tr><th>Operation</th><th>API</th><th>Datasets</th><th>Sample</th><th>Trading</th><th>Status</th></tr>
<tr><td rowspan="2" style="vertical-align:middle">Place order</td><td>REST</td><td>Stocks</td><td>PlaceOrder</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>Stocks</td><td>PlaceOrder</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Get orders</td><td>REST</td><td>Stocks</td><td>GetOrders</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>Stocks</td><td>GetOrders</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Get order</td><td>REST</td><td>Stocks</td><td>GetOrder</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>Stocks</td><td>GetOrder</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td rowspan="2" style="vertical-align:middle">Cancel order</td><td>REST</td><td>Stocks</td><td>CancelOrder</td><td align="center">✓</td><td><em>WIP</em></td></tr>
<tr><td>Java</td><td>Stocks</td><td>CancelOrder</td><td align="center">✓</td><td><em>WIP</em></td></tr>
</table>

### Algo Container Samples

For [Foundry: Full Stack](https://docs.datafye.io/quickstart/foundry-full-stack) and [Trading: Full Stack](https://docs.datafye.io/quickstart/trading-full-stack) environments — where you use the Datafye Algo Container and build your algo logic with the Datafye SDK.

> **Work in progress.** Algo container samples are coming soon.

## Sanity Test

The quickest way to verify everything works end to end is the included sanity test. It checks prerequisites, installs anything missing, provisions a local foundry, runs the samples, and cleans up after itself.

```bash
sudo bash sanity-test.sh
```

The script is interactive — it shows you what's installed and what's missing, asks before installing anything, and confirms before running. It covers health, reference data, OHLC download, historical aggregate fetch, and historical aggregate stream.

To use real market data instead of synthetic:

```bash
export POLYGON_API_KEY="your-polygon-api-key"
sudo -E bash sanity-test.sh
```

Supported platforms: Amazon Linux 2/2023, RHEL, CentOS, Fedora, Rocky Linux, AlmaLinux, Ubuntu/Debian (including WSL), and macOS.

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

> **Windows or no sudo access?** Windows requires WSL (Windows Subsystem for Linux). See [CLI Installation](https://docs.datafye.io/cli-reference/installation) for Windows setup and alternative install methods.

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
bin/run.sh get-historical-ohlc-stocks-rest --help
```

**Example:**

```bash
bin/run.sh get-historical-ohlc-stocks-rest -s AAPL -c Minute -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
```

### Configuration

The Java client samples connect to `solace.rumi.local:55554` (messaging backbone) and the REST samples connect to `api.rest.rumi.local:7776` (REST API) — which is what the quickstart descriptor provisions. Connection config is centralized in the adapter classes under `com.datafye.samples.client`.
