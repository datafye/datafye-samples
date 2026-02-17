# Datafye Client Samples

## What Is This?

This is the cookbook for the Datafye platform. If the main `datafye` repository is the engine room of the trading ship, this repo is the manual that shows you how to talk to the engine room from the bridge.

It's a collection of runnable Java samples demonstrating two fundamentally different ways to interact with Datafye: through HTTP REST calls (the way any web developer would expect) and through native Java clients that speak directly to the backend services over Solace messaging (the way a high-frequency trading system would want to). Same data, same operations, two very different performance profiles.

## Why Two Client Types?

This is a design question worth understanding, because it maps to a real tradeoff in distributed systems: **convenience vs. performance**.

### REST Samples: The Universal Remote

The REST samples use OkHttp to hit Datafye's unified API at `localhost:7776`. This is HTTP — the lingua franca of the internet. Any language, any framework, any platform can make HTTP calls. You could rewrite these samples in Python, Go, or JavaScript in an afternoon.

The tradeoff? Every request travels through the API gateway, gets deserialized into Java objects, forwarded to the appropriate backend service, and the response makes the reverse trip. For fetching historical candles or querying reference data, this is perfectly fine. For streaming thousands of ticks per second, you'd drown in HTTP overhead.

### Java Client Samples: The Direct Line

The Java client samples bypass the API gateway entirely. They use Rumi-generated client classes that talk directly to the backend services over Solace messaging. No HTTP serialization, no REST layer in between — just binary messages on a message bus.

Think of it like the difference between calling a restaurant to place an order (REST) versus walking into the kitchen and telling the chef directly what you want (Java client). Both get you food, but one has less overhead.

The streaming samples (`StreamLiveTopOfBook`, `StreamLiveTrades`, `StreamHistoricalCandles`) are the clearest illustration of why the direct line matters. You can't efficiently stream real-time market data over request-response HTTP. You need a persistent channel with push semantics, and that's exactly what the Rumi client provides.

## The Codebase

### Package Structure

```
src/main/java/com/datafye/samples/
├── rest/                                        # REST API samples (HTTP/JSON)
│   ├── GetHistoricalCandles.java                # Fetch historical OHLC candles
│   ├── GetLiveCandles.java                      # Fetch current trading day candles
│   ├── GetLiveTopOfBook.java                    # Fetch live top-of-book quotes
│   ├── GetLiveCandlesConcurrently.java          # Concurrent candle fetches for all symbols
│   └── domain/                                  # Jackson POJOs for REST responses
│       ├── Candle.java
│       ├── Quote.java
│       ├── GetHistoricalCandlesResponse.java
│       ├── GetLiveCandlesResponse.java
│       └── GetLiveTopOfBookQuotesResponse.java
├── java/                                        # Native Java client samples (Solace/Rumi)
│   ├── GetHistoricalCandles.java                # Fetch historical candles (HistoryClient)
│   ├── GetLiveCandles.java                      # Fetch live candles (AggClient)
│   ├── GetLiveTopOfBook.java                    # Fetch top-of-book quotes (FeedClient)
│   ├── StreamHistoricalCandles.java             # Stream historical candles (SIP HistoryClient)
│   ├── StreamHistoricalCandlesConcurrently.java # Concurrent historical streams
│   ├── StreamLiveTopOfBook.java                 # Stream live quotes (FeedClient)
│   └── StreamLiveTrades.java                    # Stream live trades (FeedClient)
conf/
└── rumi.conf                                    # Connection config for all clients
```

### REST Samples: How They Work

Every REST sample follows the same pattern:

1. Parse command-line arguments with `jargs`
2. Build an HTTP URL using `OkHttpClient` + `HttpUrl.Builder`
3. Set `dataset=Synthetic` as a query parameter (the dataset selector)
4. Execute the request and deserialize the JSON response with Jackson

The `domain/` package contains simple Lombok `@Data` classes that map to the JSON response structure. Nothing clever here — just `Candle` with `symbol`, `datetime`, `open`, `high`, `low`, `close`, `volume` fields, and `Quote` with bid/ask prices and sizes.

**The Concurrent Sample** (`GetLiveCandlesConcurrently`) is the most interesting REST example. It first discovers all available symbols by hitting the reference API (`/stocks/reference/securities`), then uses an `ExecutorService` to fetch candles for all symbols in parallel. It demonstrates that the REST API handles concurrent requests well — useful for batch data ingestion scenarios.

### Java Client Samples: Three Communication Patterns

The Java samples demonstrate three distinct patterns for interacting with Datafye services:

#### Pattern 1: Request-Reply (Get*)

```java
HistoryClient client = new HistoryClient("samples", "0");
GetHistoricalStocksOHLCsRequestMessage request = GetHistoricalStocksOHLCsRequestMessage.create();
request.setSymbol("AAPL");
request.setFrequency(OHLCFrequency.Minute);
request.setFromAsTimestamp(from.getTime());
request.setToAsTimestamp(to.getTime());
GetHistoricalStocksOHLCsResponseMessage response = client.getHistoricalOHLCs(request);
// use response
response.dispose();
client.close();
```

Simple synchronous call. Create a client, build a request message, call the method, get the response. The message types are code-generated from ADM XML definitions — `GetHistoricalStocksOHLCsRequestMessage` looks verbose, but it's completely type-safe. No stringly-typed APIs, no runtime serialization surprises.

**Important:** Always call `response.dispose()` when done. These are pooled Rumi messages, not garbage-collected POJOs. Missing a dispose is a memory leak that won't show up in a heap dump.

#### Pattern 2: Historical Streaming (StreamHistoricalCandles)

This is the most complex pattern — a three-step handshake:

1. **Open the stream on the server** — Send an `OpenHistoricalStocksOHLCStreamRequestMessage`. The server responds with a `streamId` and a `connectionDescriptor` (a Solace topic to listen on).
2. **Open the stream on the client** — Use the `streamId` and `connectionDescriptor` to create a `Stream` object. This sets up the client-side listener.
3. **Start the stream** — Call `stream.start(rate)` to tell the server to begin sending data.

Why the three steps? Because streaming large datasets requires coordination. The server needs to know the client is ready before it starts blasting data, and the client needs to know which channel to listen on. The rate parameter provides backpressure — you can throttle the server to `1000` messages per second instead of getting firehosed.

Data arrives via `@EventHandler` callbacks:
- `HistoricalOHLCStreamStartMessage` — Stream is beginning
- `StocksMinuteOHLCMessage` — Each candle
- `HistoricalOHLCStreamEndMessage` — Stream is complete (with total count)
- `HistoricalOHLCStreamErrorMessage` — Something went wrong

The `CandlePopulator` inner class deserves attention. Instead of calling `message.getOpen()`, `message.getClose()`, etc. (which would deserialize the entire message), it uses Rumi's zero-copy `Deserializer` callback pattern. Each field is delivered via a callback (`handleOpen`, `handleClose`, ...), avoiding unnecessary object creation. For high-throughput scenarios, this matters.

**Note:** Historical streaming currently requires the **SIP** History client (`com.datafye.client.sip.HistoryClient`), not the Synthetic one. Only the SIP client exposes the `Stream` class and `openStream()` method. This is a platform limitation, not a design choice.

#### Pattern 3: Live Subscribe/Unsubscribe (StreamLiveTopOfBook, StreamLiveTrades)

```java
FeedClient client = new FeedClient("samples", "0");
client.openStream(this);            // open the messaging connection
unsubscribe(client, new String[]{"*"});   // clear existing subscriptions
subscribe(client, symbols);          // subscribe to desired symbols
// ... data arrives via @EventHandler callbacks ...
unsubscribe(client, symbols);        // unsubscribe when done
client.closeStream();                // close the messaging connection
client.close();                      // release the client
```

This pattern is the pub/sub model. You open a persistent stream connection, subscribe to specific symbols, and live data flows to your `@EventHandler` methods until you unsubscribe. The initial `unsubscribe(*, ...)` is a cleanup step — it clears any lingering subscriptions from a previous session.

The `@EventHandler` annotation is Rumi's event dispatch mechanism. You don't register callbacks or implement interfaces — you just declare a method with the right message type as its parameter, and Rumi routes incoming messages to the correct handler based on the message type. Halt and resume messages arrive through the same channel, so you can handle market halts gracefully:

```java
@EventHandler
public void onLiveTradeHaltMessage(LiveStocksTradeHaltMessage message) { ... }

@EventHandler
public void onLiveTradeResumeMessage(LiveStocksTradeResumeMessage message) { ... }
```

### Configuration: rumi.conf

The `conf/rumi.conf` file is the wiring diagram. It tells each client how to connect to its backend service:

```properties
datafye-synthetic-feed.client.samples.connectionDescriptor=solace://localhost:55555&client_name=samples-synthetic-feed
datafye-synthetic-feed.client.samples.responseTimeout=5
```

The naming convention is `{service}.{client|stream}.{instance}.{property}`. The `client` vs `stream` distinction is important: `client` connections are for request-reply, `stream` connections are for long-lived pub/sub channels. Different connection pools, different lifecycle.

The samples default to the **Synthetic** dataset, which generates deterministic fake market data. This means you can run every sample without API keys or a live market data subscription — the platform generates its own test data using a seeded random walk.

### The Distribution

Running `mvn clean package` produces `datafye-samples-2.0-SNAPSHOT-distribution.tar.gz`. Extract it and you get a self-contained directory with `libs/` (all JARs) and `conf/` (configuration). Every sample runs with a simple `java -cp "libs/*" com.datafye.samples...` command.

The `distribution.xml` assembly descriptor controls what goes into the archive. It copies the compiled JAR, all runtime dependencies, and the configuration files into a flat structure that's easy to unpack and run anywhere.

## Technologies

| Technology | Role | Why |
|-----------|------|-----|
| **OkHttp 4** | HTTP client for REST samples | Clean API, connection pooling, timeouts built in |
| **Jackson** | JSON deserialization | Industry standard, works with Lombok |
| **Lombok** | Boilerplate reduction for POJOs | `@Data` + `@Builder` eliminates 50 lines of getters/setters per class |
| **Rumi (via datafye-client)** | Native messaging client | Direct Solace messaging, code-generated type-safe clients |
| **jargs** | Command-line parsing | Lightweight, no annotation magic, gets out of the way |
| **Java 17** | Runtime | Required by Rumi 4.x; `--add-opens` flags needed for internal access |

## Lessons from the Port (1.5 to 2.0)

This codebase was ported from the old `gb-poc` repository (Datafye 1.5) to Datafye 2.0. The migration surfaced several insights worth remembering.

### Dataset-Determined Routing Beats Explicit Market Selection

In 1.5, every request message had a `setMarket(Market.SIP)` call — the client had to explicitly declare which dataset it wanted. In 2.0, the dataset is determined by **which client class you instantiate**. Use `com.datafye.client.synthetic.FeedClient` and you get Synthetic data. Use `com.datafye.client.sip.FeedClient` and you get SIP data. No field to set, no field to forget.

This is a subtle but important design improvement. When the routing decision lives in the message, every caller must remember to set it correctly, and every handler must check it. When it's structural (baked into the client type), the compiler enforces it. You literally can't send a request to the wrong dataset.

### Unified API Simplifies REST Clients

The old REST API had separate endpoint prefixes per service (`/datafye-ohlc-api/`, `/datafye-quote-api/`). The new API unifies everything under `/datafye-api/v1/stocks/...` with a `dataset` query parameter. This means REST clients only need to know one base URL, and switching datasets is a one-parameter change rather than a URL restructure.

### Streaming Client Availability Isn't Uniform

Not every client supports every operation. The Synthetic History client doesn't expose the `Stream` class — only the SIP History client does. The Synthetic Feed client, however, fully supports live streaming via subscribe/unsubscribe. Don't assume symmetry across datasets; check the actual client class before building a sample around it.

### Message Naming Conventions Tell You What Changed

The old `GetHistoricalOHLCsRequestMessage` became `GetHistoricalStocksOHLCsRequestMessage`. The insertion of `Stocks` is deliberate — Datafye 2.0 supports multiple asset classes (Stocks, Crypto), and the message names now encode the asset class. If you see a message name without an asset class qualifier, it's probably from 1.5.

### Don't Fight the License Plugin

The parent POM includes a copyright header plugin that reformats license headers during the build. You might write `Copyright 2024 Datafye`, but the build will rewrite it to match the configured template (`Copyright 2022 N5 Technologies, Inc`). This is by design — the plugin ensures all files have consistent headers. Don't manually fix what the build will auto-correct.

## How to Think About This Codebase

**The samples are the API documentation.** API docs tell you what endpoints exist. Samples show you how to use them in context — with error handling, connection management, and realistic parameters. If someone asks "how do I get historical candles from Datafye?", you point them at one of these files, not at a Swagger spec.

**Two packages, one mental model.** The REST and Java samples are intentionally parallel. `GetHistoricalCandles` exists in both packages, doing the same thing via different transports. This isn't redundancy — it's a comparison tool. Put them side by side and you immediately see what HTTP abstracts away (connection management, serialization) and what it costs (latency, streaming limitations).

**Configuration is infrastructure.** The `rumi.conf` file is not application code — it's deployment topology. Changing a hostname or port should never require recompilation. This is why every connection parameter lives in config, not in Java source.

## Quick Reference

| What | Where |
|------|-------|
| REST samples | `src/main/java/com/datafye/samples/rest/` |
| Java client samples | `src/main/java/com/datafye/samples/java/` |
| REST response POJOs | `src/main/java/com/datafye/samples/rest/domain/` |
| Connection config | `conf/rumi.conf` |
| Distribution archive | `target/datafye-samples-2.0-SNAPSHOT-distribution.tar.gz` |
| REST API base URL | `http://localhost:7776/datafye-api/v1` |
| Solace broker | `solace://localhost:55555` |

## Related Repositories

- **datafye** — The platform itself (services, API, CLI)
- **datafye-algos** — Trading algorithm implementations
- **datafye-docs** — Documentation source (https://docs.datafye.io)
