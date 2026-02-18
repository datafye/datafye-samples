# Historical Streaming (SIP)

Stream historical candle data using the SIP History client. Unlike the other guides which use the Synthetic dataset, the historical streaming samples require the SIP dataset provisioned with an external data provider (e.g., Polygon).

**Prerequisites:** A running Datafye environment with SIP data provisioned. See `sip-data-descriptor.yaml` in the repository root for an example data descriptor. All commands assume you are in the extracted distribution directory.

## Data scope

- **Symbols:** AAPL, MSFT, GOOGL
- **Day:** 2024-01-15
- **Test subset:** AAPL over a 3-hour window (10:00–13:00)

## Stream historical candles

Streams minute-frequency candles for AAPL, throttled to 1000 candles/second. Prints a stream start message, streams candle data, then prints an end message with the total count.

```bash
bin/run.sh stream-historical-candles-java -s AAPL -f 2024-01-15T10:00:00 -t 2024-01-15T13:00:00 -r 1000
```

## Stream historical candles concurrently

Runs 4 concurrent streams across different date offsets, each throttled to 1000 candles/second.

```bash
bin/run.sh stream-historical-candles-concurrently-java -f 2024-01-15 -c 4 -r 1000
```
