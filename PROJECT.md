# PROJECT.md — Datafye Samples

## What This Project Is

This repository is a cookbook for the Datafye platform. It covers two types of Datafye environments:

1. **Data Cloud API Samples** — For environments where you bring your own algo container and access market data and broker connectivity through the Data Cloud's APIs. These demonstrate three access modes:
   - **REST API** — HTTP/JSON request-response. Any programming language can do this.
   - **WebSocket API** — Streaming and subscription over WebSocket connections. The streaming counterpart to REST for those not using the Java Client.
   - **Java Client API** — A native Java library that bypasses HTTP entirely and talks directly to Datafye's backend services over the cloud's messaging backbone. Supports request-reply, streaming, and subscription through a single client.

2. **Algo Container Samples** — For environments where you use the Datafye Algo Container and build algo logic with the Datafye SDK. (Work in progress.)

The Data Cloud API samples are intentionally parallel: the same operation (say, "get historical OHLC bars for AAPL") is implemented across REST, WebSocket, and Java so you can compare them side by side and understand the trade-offs. The samples span reference data, historical data, live data, backtesting operations, and broker connectivity — organized by whether they apply to a Foundry (historical + replayed live data), a Trading Environment (real live data), or both.

## Technical Architecture

### The Big Picture

Datafye's Data Cloud is a cluster of specialized backend services — a history service that stores OHLC bars, a feed service that distributes live quotes and trades, an aggregation service that computes live OHLC bars, a reference service that maintains the security master, and (in Trading Environments) a broker connector for order management. These services communicate internally over the cloud's messaging backbone.

There are three ways in:

```
                            ┌──────────────────────────────────────┐
                            │       Datafye Data Cloud &           │
                            │       Broker Connector               │
                            │                                      │
 REST Samples ────HTTP────> │  API Gateway ──> Backend Services    │
                            │     :7776                            │
                            │                                      │
 WebSocket Samples ──WS──> │  Stream Gateway ──> Backend Services  │
                            │     :7775                            │
                            │                                      │
 Java Samples ──Messaging─> │         Backend Services directly    │
                            └──────────────────────────────────────┘
```

The **REST samples** go through the API Gateway. It's an HTTP facade that translates JSON requests into internal messages, forwards them to the right backend service, and translates the response back to JSON. Simple, universal, but every request pays the cost of HTTP serialization and one extra network hop. REST is request-response only.

The **WebSocket samples** go through the Stream Gateway. This is the streaming counterpart to the REST API — it provides subscribe and stream access over WebSocket connections for those who want streaming without using the Java Client.

The **Java Client samples** skip both gateways entirely. They use code-generated client classes (built with the [Rumi](https://developer.rumi.systems) framework) that speak the same protocol the backend services use internally. No HTTP overhead. No JSON parsing. And they support all three patterns — request-reply, streaming, and subscription — through a single client.

### Codebase Structure

```
src/main/java/com/datafye/samples/
├── rest/                          # HTTP/JSON approach
│   ├── GetHistoricalOHLC.java
│   ├── GetLiveOHLC.java
│   ├── GetLiveTopOfBook.java
│   ├── GetLiveOHLCConcurrently.java
│   └── domain/                    # Jackson POJOs for JSON deserialization
│       ├── OHLC.java
│       ├── Quote.java
│       ├── GetHistoricalOHLCResponse.java
│       ├── GetLiveOHLCResponse.java
│       └── GetLiveTopOfBookQuotesResponse.java
│
├── java/                          # Native messaging backbone approach
│   ├── GetHistoricalOHLC.java
│   ├── GetLiveOHLC.java
│   ├── GetLiveTopOfBook.java
│   ├── StreamHistoricalOHLC.java
│   ├── StreamHistoricalOHLCConcurrently.java
│   ├── SubscribeLiveTopOfBook.java
│   └── SubscribeLiveTrades.java
│
bin/
│   ├── run.sh                     # Master run script (Linux/macOS)
│   └── run.bat                    # Master run script (Windows)
│
conf/
│   └── rumi.conf                  # Optional Rumi runtime tuning (trace levels, etc.)
│
pom.xml                            # Maven build with assembly plugin
distribution.xml                   # Packages everything into a deployable tar.gz
```

Notice how `rest/` has 4 samples and `java/` has 7. The extra 3 are the streaming and subscription samples — `StreamHistoricalOHLC`, `SubscribeLiveTopOfBook`, and `SubscribeLiveTrades`. REST is request-response only; streaming and subscription require either the WebSocket API or the Java Client. As the WebSocket samples are built out, a `ws/` package will appear alongside these two.

### How the Parts Connect

**Each sample embeds its own connection config** in a `static {}` block at the top of the class. This uses `System.setProperty()` calls that Rumi's `Config` class picks up automatically. For example, a REST sample sets the API endpoint:

```java
static {
    System.setProperty("datafye-samples.api.endpoint", "api.rest.rumi.local:7776");
}
```

And a Java streaming sample sets both its request-reply and streaming connections:

```java
static {
    System.setProperty("datafye-synthetic-feed.client.samples.connectionDescriptor",
        "solace://solace.rumi.local:55555&client_name=samples-synthetic-feed");
    System.setProperty("datafye-synthetic-feed.stream.samples.connectionDescriptor",
        "solace://solace.rumi.local:55555&client_name=samples-synthetic-feed-stream");
}
```

This makes each sample completely self-contained — you can read a single file and understand everything it needs to run, without cross-referencing a separate config file. The `conf/rumi.conf` file still exists in the distribution for Rumi runtime tuning (e.g. `nv.trace.defaultLevel=warn`) but connection config lives in the code.

The naming convention in the property keys is important: `{service}.{type}.{instance}.{property}`. The `client` suffix means request-reply connections. The `stream` suffix means long-lived pub/sub connections used for streaming data. This distinction matters because streaming samples need a separate messaging session from the one used for request-reply control messages (you can't multiplex both on the same session without blocking).

**The build produces a self-contained distribution**. `mvn clean install` compiles the code, pulls all dependencies into `target/dependency/`, then the Maven Assembly Plugin packages everything into a `tar.gz` using the layout defined in `distribution.xml`. Extract it and you get a `libs/` directory with every JAR you need, plus a `bin/` directory with run scripts — no classpath headaches, no memorizing JVM flags.

The `bin/run.sh` (and `run.bat` for Windows) is a single master script that maps friendly sample names to fully-qualified Java class names. Instead of typing `java --add-opens=java.base/jdk.internal.ref=ALL-UNNAMED ... -cp "libs/*" com.datafye.samples.rest.GetHistoricalOHLC`, you type `bin/run.sh get-historical-ohlc-rest`. JVM options, classpath, and class resolution are all handled in one place. This is a deliberate design choice: 22 per-sample scripts would be 95% identical boilerplate, and if the JVM options ever change, you'd have to update all of them. One script, one place to maintain.

## The Communication Patterns

This is the architectural heart of the project. Every sample falls into one of three patterns, and understanding these three patterns is understanding how Datafye data access works. The REST API supports only Pattern 1. The WebSocket API supports Patterns 2 and 3. The Java Client supports all three.

### Pattern 1: REST Request-Response

The simplest pattern. Build an HTTP URL, send a GET request, deserialize the JSON response.

```java
// From rest/GetHistoricalOHLC.java
HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint")
    + "/datafye-api/v1/stocks/history/ohlc").newBuilder();
urlBuilder.addQueryParameter("dataset", "Synthetic");
urlBuilder.addQueryParameter("frequency", frequency);
urlBuilder.addQueryParameter("symbols", symbol);
urlBuilder.addQueryParameter("from", dateFormat().format(from));
urlBuilder.addQueryParameter("to", dateFormat().format(to));
Request request = new Request.Builder().url(urlBuilder.build().toString()).build();
Response response = webClient.newCall(request).execute();
GetHistoricalOHLCResponse ohlcResponse = objectMapper.readValue(response.body().string(), ...);
```

Every REST sample follows this exact shape. The only things that change are the URL path and the response POJO. It's the kind of code any backend developer has written a hundred times.

The domain POJOs in `rest/domain/` are pure data holders — Lombok's `@Data` and `@Builder` annotations generate all the getters, setters, `equals`, `hashCode`, and `toString` so the files are just field declarations. Jackson's `ObjectMapper` handles the JSON-to-Java mapping, with `FAIL_ON_UNKNOWN_PROPERTIES` disabled so the code doesn't break when the API adds new fields.

### Pattern 2: Java Client Request-Reply

Same logical operation as the REST version, but the protocol is different. Instead of HTTP/JSON, you're creating typed Rumi messages and calling methods on a code-generated client class.

```java
// From java/GetHistoricalOHLC.java
HistoryClient client = new HistoryClient("samples", "0");

GetHistoricalStocksOHLCsRequestMessage request = GetHistoricalStocksOHLCsRequestMessage.create();
request.setFrequency(OHLCFrequency.valueOf(frequency));
request.setSymbol(symbol);
request.setFromAsTimestamp(from.getTime());
request.setToAsTimestamp(to.getTime());
GetHistoricalStocksOHLCsResponseMessage response = client.getHistoricalOHLCs(request);
final int candlesCount = response.getCandlesCount();

response.dispose();  // <-- This is critical. Don't skip this.
client.close();
```

A few things to notice:

- **The client class determines the dataset**. `com.datafye.client.synthetic.HistoryClient` routes to Synthetic data. `com.datafye.client.sip.HistoryClient` routes to SIP data. In Datafye 1.5 you had to call `setMarket()` on each message and hope you got it right. In 2.0, the compiler enforces it — wrong import, wrong dataset, and you'll see it immediately. This is a great example of making illegal states unrepresentable.

- **Messages must be disposed**. Rumi messages come from an object pool, not the garbage collector. When you're done with a response, you call `dispose()` to return it to the pool. If you forget, you leak pooled buffers — and it won't show up in a heap dump because the objects technically still exist, they're just never returned. Think of it like closing a database connection: the runtime won't save you if you forget.

- **The constructor takes an instance name and ID** (`"samples"`, `"0"`). These map to the configuration keys in `rumi.conf` — the client looks up `datafye-synthetic-history.client.samples.connectionDescriptor` to find its messaging connection. Multiple instances of the same client type can coexist by using different IDs.

### Pattern 3: Streaming and Subscription

This is where things get interesting, and it's where the Java Client and WebSocket APIs earn their keep. REST is request-response only — if you need streaming or subscription, you use either WebSocket connections or the Java Client.

#### Historical Streaming (three-step handshake)

Imagine you want to replay a full day of minute-by-minute OHLC data for all symbols. That could be thousands of bars. A REST request would have to materialize the entire result set in memory, serialize it to JSON, send it over HTTP, and deserialize it on the other side. Streaming avoids all of that — the server pushes OHLC bars to you one at a time over a dedicated messaging channel.

The protocol is a three-step handshake:

```java
// From java/StreamHistoricalOHLC.java

// Step 1: Ask the server to prepare the stream
OpenHistoricalStocksOHLCStreamRequestMessage request = OpenHistoricalStocksOHLCStreamRequestMessage.create();
request.setFrequency(OHLCFrequency.Minute);
request.setSymbol(symbol);
request.setFromAsTimestamp(from.getTime());
request.setToAsTimestamp(to.getTime());
OpenHistoricalStocksOHLCStreamResponseMessage response = client.openHistoricalOHLCStream(request);

// Step 2: Use the server's response to open the client-side stream
long streamId = response.getStreamId();
String connectionDescriptor = response.getStreamConnectionDescriptor();
response.dispose();
Stream stream = client.openStream(streamId, connectionDescriptor, this);

// Step 3: Start the stream (with optional rate throttling)
stream.start(rate);
```

Why three steps? Because the server needs to allocate resources (a dedicated messaging topic, a cursor into the historical data) before the client connects. The server returns a `streamId` and a `connectionDescriptor` — essentially a private address that the client dials into. If the client doesn't connect within the allotted timeout, the server cleans up its side. It's like a restaurant giving you a reservation number: they'll hold the table, but not forever.

Data arrives via `@EventHandler` callbacks:

```java
@EventHandler
public void onStreamStart(HistoricalOHLCStreamStartMessage message) { ... }

@EventHandler
public void onStreamData(StocksMinuteOHLCMessage message) { ... }

@EventHandler
public void onStreamEnd(HistoricalOHLCStreamEndMessage message) { ... }

@EventHandler
public void onStreamError(HistoricalOHLCStreamErrorMessage message) { ... }
```

The Rumi framework routes each message type to the correct handler based on its type signature — you never write a switch statement or check message types manually. You just declare "when this type of message arrives, do this" and the framework handles dispatch.

The `StreamHistoricalOHLC` sample also demonstrates **zero-copy deserialization** via the `OHLCPopulator` inner class. Instead of deserializing an entire message into a Java object (which allocates memory), you implement a callback interface where each field is delivered individually:

```java
class OHLCPopulator extends StocksMinuteOHLCMessage.Deserializer.AbstractCallbackImpl {
    @Override public void handleOpen(double val) { _ohlc.setOpen(val); }
    @Override public void handleHigh(double val) { _ohlc.setHigh(val); }
    @Override public void handleClose(double val) { _ohlc.setClose(val); }
    ...
}
```

This is a performance optimization for high-throughput scenarios. When you're streaming millions of OHLC bars, avoiding object allocation per message makes a real difference. You reuse a single `OHLC` instance and overwrite its fields on every message.

#### Live Streaming (subscribe/unsubscribe)

Live streaming follows a pub/sub model. You subscribe to symbols, and the server pushes data as it arrives in real time.

```java
// From java/SubscribeLiveTopOfBook.java

FeedClient client = new FeedClient("samples", "0");
client.openStream(this);              // Open the pub/sub channel

unsubscribe(client, new String[]{"*"});  // Clear previous subscriptions
subscribe(client, symbols);              // Subscribe to what we want

while (_numQuotesReceived < 1000) {      // Wait for data
    Thread.sleep(100);
}

unsubscribe(client, symbols);            // Clean up subscriptions
client.closeStream();                    // Close the pub/sub channel
client.close();                          // Close the client
```

The initial `unsubscribe(client, new String[]{"*"})` is a defensive pattern — it clears any lingering subscriptions from a previous session so you only receive exactly what you've asked for. Think of it as wiping the whiteboard clean before writing on it.

Data and control messages arrive through the same channel but different handlers:

```java
@EventHandler
public void onLiveTopOfBookQuoteDataMessage(LiveTopOfBookStocksQuoteDataMessage message) { ... }

@EventHandler
public void onLiveTopOfBookQuoteHaltMessage(LiveTopOfBookStocksQuoteHaltMessage message) { ... }

@EventHandler
public void onLiveTopOfBookQuoteResumeMessage(LiveTopOfBookStocksQuoteResumeMessage message) { ... }
```

Halt and resume messages are control signals — if the exchange halts trading on a symbol, the platform propagates that to all subscribers. Your code needs to handle both data and control messages. The samples show the minimum viable set of handlers.

## Technologies and Why They Were Chosen

| Technology | Role | Why This One |
|-----------|------|-------------|
| **OkHttp 4** | HTTP client for REST samples | Connection pooling, built-in timeout configuration, widely used. The alternative was Java's built-in `HttpURLConnection`, which is lower-level and requires more boilerplate. |
| **Jackson** | JSON deserialization | Industry standard for Java JSON processing. Combined with Lombok, a JSON response POJO is ~10 lines instead of ~60. |
| **Lombok** | Boilerplate elimination | `@Data` + `@Builder` on a POJO generates getters, setters, `equals`, `hashCode`, `toString`, and a builder. The domain classes in `rest/domain/` are practically just field declarations. |
| **Rumi** (via `datafye-client`) | Code-generated messaging clients | Rumi generates type-safe client classes and message types from a schema. You get compile-time correctness (wrong field type? compiler error), object pooling (no GC pressure), and zero-copy deserialization. It's the backbone of Datafye's high-performance architecture. |
| **jargs** | CLI argument parsing | Lightweight, no annotations, no framework magic. For sample code that's meant to be read and understood, simplicity beats power. |
| **Maven** | Build system | Standard in the Java ecosystem. The Assembly Plugin packages the distribution. |
| **Java 17** | Runtime | Required by Rumi 4.x for module system access. The `--add-opens` JVM flags are needed because Rumi uses internal JDK APIs for its memory management. |

## Lessons and Pitfalls

### 1. Always dispose Rumi responses

This is the single most important thing to remember when working with the Java Client API. Rumi messages are **pooled**, not garbage collected. If you don't call `response.dispose()`, those buffers are never returned to the pool. Your application will appear to leak memory, but heap dumps won't show it because the objects are technically alive — they're just orphaned in the pool.

The samples are disciplined about this. Every request-reply sample calls `dispose()` after extracting data. The streaming samples use `try/finally` blocks to ensure cleanup even on error paths:

```java
SubscribeLiveTopOfBookStocksQuotesResponseMessage response = client.subscribeLiveTopOfBookQuotes(request);
try {
    if (response.getStatus() != null) {
        throw new Exception(response.getStatus());
    }
} finally {
    response.dispose();
}
```

### 2. Streaming is SIP-only (for history)

The Synthetic History client doesn't support streaming — only the SIP History client does. If you try to call `openStream()` on a Synthetic History client, you'll get an error. This is why `StreamHistoricalOHLC.java` imports `com.datafye.client.sip.HistoryClient` while `GetHistoricalOHLC.java` imports `com.datafye.client.synthetic.HistoryClient`. A subtle but critical difference.

Live streaming (quotes and trades) works with both Synthetic and SIP feed clients.

### 3. The benchmarking loop reveals latency characteristics

Every REST and Java request-reply sample runs 100 iterations and averages the timing. This isn't arbitrary — it reveals the difference between cold and warm performance. The first request pays connection setup costs (TCP handshake for REST, messaging session establishment for Java). Subsequent requests reuse those connections. The average over 100 iterations gives you a realistic picture of steady-state performance.

### 4. Configuration naming conventions matter

In the `System.setProperty()` calls, the naming convention `{service}.{type}.{instance}.{property}` is load-bearing. Getting it wrong means the client connects to the wrong service or fails to connect at all. The `client` vs `stream` distinction is especially important — streaming samples need both a `client` connection (for control messages like open/close/subscribe/unsubscribe) and a `stream` connection (for the actual data flow).

### 5. Concurrency patterns are deliberately simple

The concurrent samples (`GetLiveOHLCConcurrently`, `StreamHistoricalOHLCConcurrently`) use plain `Thread` and `join()` rather than `CompletableFuture` or reactive streams. This is intentional — sample code should teach one concept at a time. The concurrency here is straightforward fork-join parallelism, not something that requires understanding reactive programming.

In the historical streaming concurrent sample, notice how each thread gets a different date (each offset by one day) but shares the same `HistoryClient`. The `openStream()` call is synchronized on the client because the initial request-reply handshake must be serialized, but once the streams are open, data flows independently on separate messaging sessions.

### 6. The `dataset` parameter is your safety net

All REST samples pass `dataset=Synthetic` as a query parameter. The Synthetic dataset generates deterministic test data — it doesn't need API keys, market data subscriptions, or a live exchange connection. This means you can run the samples with just a locally provisioned Datafye environment and get meaningful results immediately. When you're ready for real market data, switch to `SIP`.

### 7. Zero-copy deserialization is a power tool

The `OHLCPopulator` pattern in the streaming samples (implementing `StocksMinuteOHLCMessage.Deserializer.AbstractCallbackImpl`) is not beginner-friendly, but it exists for a good reason. In a streaming scenario where millions of messages flow per second, allocating a new object per message creates GC pressure that causes latency spikes. The callback pattern lets you reuse a single object and overwrite its fields — zero allocation per message.

You don't need this for request-reply. It's a streaming optimization for when throughput matters more than code clarity. The fact that it's shown in the samples is a nod to the kind of performance-sensitive use cases Datafye is built for.

### 8. Clean shutdown order matters

The streaming samples are careful about shutdown ordering:

```
1. Unsubscribe from symbols     (stop data flow)
2. Close the stream             (tear down the pub/sub channel)
3. Close the client             (release the messaging session)
```

Reversing step 1 and 2 — closing the stream before unsubscribing — can leave server-side subscriptions dangling. The server will eventually clean them up via timeout, but it's sloppy. The `try/finally` nesting in the samples enforces the correct order even when exceptions interrupt the flow.

### 9. Dataset-determined routing beats explicit market selection

In Datafye 1.5, every request message had a `setMarket(Market.SIP)` call — the client had to explicitly declare which dataset it wanted. In 2.0, the dataset is determined by which client class you instantiate. Use `com.datafye.client.synthetic.FeedClient` and you get Synthetic data. Use `com.datafye.client.sip.FeedClient` and you get SIP data. No field to set, no field to forget.

This is a subtle but important design improvement. When the routing decision lives in the message, every caller must remember to set it correctly, and every handler must check it. When it's structural (baked into the client type), the compiler enforces it. You literally can't send a request to the wrong dataset.

### 10. Message naming conventions tell you the asset class

The old `GetHistoricalOHLCsRequestMessage` became `GetHistoricalStocksOHLCsRequestMessage`. The insertion of `Stocks` is deliberate — Datafye 2.0 supports multiple asset classes (Stocks, Crypto), and the message names now encode the asset class. If you see a message name without an asset class qualifier, it's probably from 1.5.

## How Good Engineers Think About This

**Start simple, add complexity only when you need it.** The REST samples are ~60 lines each. They do one thing, clearly. When that's not enough — when you need streaming, zero-copy deserialization, or sub-millisecond latency — the Java Client samples show you the next step. The codebase doesn't try to be clever. It tries to be clear.

**Make the easy thing the right thing.** Datafye 2.0's dataset-as-client-class design (importing `synthetic.HistoryClient` vs `sip.HistoryClient`) means you can't accidentally query the wrong dataset. The compiler catches it. This is a small design choice that eliminates an entire class of runtime bugs.

**Sample code is documentation that compiles.** Every sample in this repository is a runnable program, not a code snippet in a wiki. If it compiles and runs, the documentation is correct. If the API changes and the sample breaks, the build fails. This is strictly better than prose documentation that can silently drift out of date.

**Self-contained samples are the best documentation.** Each sample embeds its own connection config in a `static {}` block at the top of the class. You can read a single file and understand everything it needs — no hunting through external config files. For sample code, clarity and self-containment beat the DRY principle. The `conf/rumi.conf` file is still available for optional runtime tuning if needed.

## Quick Reference

| What | Where |
|------|-------|
| Run scripts | `bin/run.sh` (Linux/macOS), `bin/run.bat` (Windows) |
| REST samples | `src/main/java/com/datafye/samples/rest/` |
| WebSocket samples | `src/main/java/com/datafye/samples/ws/` (planned) |
| Java Client samples | `src/main/java/com/datafye/samples/java/` |
| REST response POJOs | `src/main/java/com/datafye/samples/rest/domain/` |
| Connection config | Embedded in each sample's `static {}` block |
| Runtime tuning | `conf/rumi.conf` (optional) |
| Distribution archive | `target/datafye-samples-2.0-SNAPSHOT-distribution.tar.gz` |
| Messaging backbone | `solace://solace.rumi.local:55555` |
| REST API | `api.rest.rumi.local:7776` |
| WebSocket API | `api.stream.rumi.local:7775` |
| Wiki (run guides) | [wiki](../../wiki) |
