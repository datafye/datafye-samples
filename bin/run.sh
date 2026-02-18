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
        get-historical-candles-rest)                 echo "com.datafye.samples.rest.GetHistoricalCandles" ;;
        get-live-candles-rest)                       echo "com.datafye.samples.rest.GetLiveCandles" ;;
        get-live-top-of-book-rest)                   echo "com.datafye.samples.rest.GetLiveTopOfBook" ;;
        get-live-candles-concurrently-rest)           echo "com.datafye.samples.rest.GetLiveCandlesConcurrently" ;;
        get-historical-candles-java)                 echo "com.datafye.samples.java.GetHistoricalCandles" ;;
        get-live-candles-java)                       echo "com.datafye.samples.java.GetLiveCandles" ;;
        get-live-top-of-book-java)                   echo "com.datafye.samples.java.GetLiveTopOfBook" ;;
        stream-historical-candles-java)              echo "com.datafye.samples.java.StreamHistoricalCandles" ;;
        stream-historical-candles-concurrently-java) echo "com.datafye.samples.java.StreamHistoricalCandlesConcurrently" ;;
        stream-live-top-of-book-java)                echo "com.datafye.samples.java.StreamLiveTopOfBook" ;;
        stream-live-trades-java)                     echo "com.datafye.samples.java.StreamLiveTrades" ;;
        *) return 1 ;;
    esac
}

usage() {
    echo "Usage: $(basename "$0") <sample-name> [sample-args...]"
    echo ""
    echo "Available samples:"
    echo ""
    echo "  REST API:"
    echo "    get-historical-candles-rest        Fetch historical OHLC candles"
    echo "    get-live-candles-rest              Fetch current trading day candles"
    echo "    get-live-top-of-book-rest          Fetch live top-of-book quotes"
    echo "    get-live-candles-concurrently-rest Fetch live candles concurrently"
    echo ""
    echo "  Java Client:"
    echo "    get-historical-candles-java        Fetch historical OHLC candles"
    echo "    get-live-candles-java              Fetch current trading day candles"
    echo "    get-live-top-of-book-java          Fetch live top-of-book quotes"
    echo "    stream-historical-candles-java     Stream historical candles"
    echo "    stream-historical-candles-concurrently-java"
    echo "                                       Stream historical candles concurrently"
    echo "    stream-live-top-of-book-java       Stream live top-of-book quotes"
    echo "    stream-live-trades-java            Stream live trades"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") get-historical-candles-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00"
}

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ "$1" = "--list" ]; then
    echo "get-historical-candles-java"
    echo "get-historical-candles-rest"
    echo "get-live-candles-concurrently-rest"
    echo "get-live-candles-java"
    echo "get-live-candles-rest"
    echo "get-live-top-of-book-java"
    echo "get-live-top-of-book-rest"
    echo "stream-historical-candles-concurrently-java"
    echo "stream-historical-candles-java"
    echo "stream-live-top-of-book-java"
    echo "stream-live-trades-java"
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
