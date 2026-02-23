#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

JAVA_OPTS="--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED \
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
--add-opens=java.base/java.lang=ALL-UNNAMED \
--add-opens=java.base/java.nio=ALL-UNNAMED \
--add-opens=java.base/java.io=ALL-UNNAMED \
--add-opens=java.management/sun.management=ALL-UNNAMED"

resolve_class() {
    case "$1" in
        get-historical-ohlc-rest)                 echo "com.datafye.samples.rest.GetHistoricalOHLC" ;;
        get-live-ohlc-rest)                       echo "com.datafye.samples.rest.GetLiveOHLC" ;;
        get-live-top-of-book-rest)                echo "com.datafye.samples.rest.GetLiveTopOfBook" ;;
        get-live-ohlc-concurrently-rest)          echo "com.datafye.samples.rest.GetLiveOHLCConcurrently" ;;
        get-historical-ohlc-java)                 echo "com.datafye.samples.java.GetHistoricalOHLC" ;;
        get-live-ohlc-java)                       echo "com.datafye.samples.java.GetLiveOHLC" ;;
        get-live-top-of-book-java)                echo "com.datafye.samples.java.GetLiveTopOfBook" ;;
        stream-historical-ohlc-java)              echo "com.datafye.samples.java.StreamHistoricalOHLC" ;;
        stream-historical-ohlc-concurrently-java) echo "com.datafye.samples.java.StreamHistoricalOHLCConcurrently" ;;
        subscribe-live-top-of-book-java)             echo "com.datafye.samples.java.SubscribeLiveTopOfBook" ;;
        subscribe-live-trades-java)                  echo "com.datafye.samples.java.SubscribeLiveTrades" ;;
        get-historical-top-gainers-rest)             echo "com.datafye.samples.rest.GetHistoricalTopGainers" ;;
        get-historical-top-gainers-java)             echo "com.datafye.samples.java.GetHistoricalTopGainers" ;;
        get-last-trade-rest)                         echo "com.datafye.samples.rest.GetLastTrade" ;;
        get-last-trade-java)                         echo "com.datafye.samples.java.GetLastTrade" ;;
        get-live-sma-rest)                           echo "com.datafye.samples.rest.GetLiveSMA" ;;
        get-live-sma-java)                           echo "com.datafye.samples.java.GetLiveSMA" ;;
        get-live-ema-rest)                           echo "com.datafye.samples.rest.GetLiveEMA" ;;
        get-live-ema-java)                           echo "com.datafye.samples.java.GetLiveEMA" ;;
        *) return 1 ;;
    esac
}

usage() {
    echo "Usage: $(basename "$0") <sample-name> [sample-args...]"
    echo ""
    echo "Available samples:"
    echo ""
    echo "  REST API:"
    echo "    get-historical-ohlc-rest             Fetch historical OHLC bars"
    echo "    get-historical-top-gainers-rest       Fetch historical top gainers"
    echo "    get-live-ohlc-rest                   Fetch current trading day OHLC bars"
    echo "    get-live-ohlc-concurrently-rest       Fetch live OHLC bars concurrently"
    echo "    get-live-top-of-book-rest             Fetch live top-of-book quotes"
    echo "    get-last-trade-rest                   Fetch last trade for symbols"
    echo "    get-live-sma-rest                     Fetch live SMA values"
    echo "    get-live-ema-rest                     Fetch live EMA values"
    echo ""
    echo "  Java Client:"
    echo "    get-historical-ohlc-java             Fetch historical OHLC bars"
    echo "    get-historical-top-gainers-java       Fetch historical top gainers"
    echo "    get-live-ohlc-java                   Fetch current trading day OHLC bars"
    echo "    get-live-top-of-book-java             Fetch live top-of-book quotes"
    echo "    get-last-trade-java                   Fetch last trade for symbols"
    echo "    get-live-sma-java                     Fetch live SMA values"
    echo "    get-live-ema-java                     Fetch live EMA values"
    echo "    stream-historical-ohlc-java              Stream historical OHLC bars"
    echo "    stream-historical-ohlc-concurrently-java"
    echo "                                              Stream historical OHLC bars concurrently"
    echo "    subscribe-live-top-of-book-java            Subscribe to live top-of-book quotes"
    echo "    subscribe-live-trades-java                 Subscribe to live trades"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") get-historical-ohlc-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00"
}

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ "$1" = "--list" ]; then
    echo "get-historical-ohlc-java"
    echo "get-historical-ohlc-rest"
    echo "get-historical-top-gainers-java"
    echo "get-historical-top-gainers-rest"
    echo "get-last-trade-java"
    echo "get-last-trade-rest"
    echo "get-live-ema-java"
    echo "get-live-ema-rest"
    echo "get-live-ohlc-concurrently-rest"
    echo "get-live-ohlc-java"
    echo "get-live-ohlc-rest"
    echo "get-live-sma-java"
    echo "get-live-sma-rest"
    echo "get-live-top-of-book-java"
    echo "get-live-top-of-book-rest"
    echo "stream-historical-ohlc-concurrently-java"
    echo "stream-historical-ohlc-java"
    echo "subscribe-live-top-of-book-java"
    echo "subscribe-live-trades-java"
    exit 0
fi

SAMPLE_NAME="$1"
shift

CLASS=$(resolve_class "$SAMPLE_NAME") || {
    echo "Error: Unknown sample '$SAMPLE_NAME'" >&2
    echo "" >&2
    echo "Run '$(basename "$0") --help' to see available samples." >&2
    exit 1
}

exec java $JAVA_OPTS -cp "$BASE_DIR/libs/*" "$CLASS" "$@"
