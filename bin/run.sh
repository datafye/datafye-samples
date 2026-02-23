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
        get-live-last-trade-rest)                         echo "com.datafye.samples.rest.GetLiveLastTrade" ;;
        get-live-last-trade-java)                         echo "com.datafye.samples.java.GetLiveLastTrade" ;;
        get-live-sma-rest)                           echo "com.datafye.samples.rest.GetLiveSMA" ;;
        get-live-sma-java)                           echo "com.datafye.samples.java.GetLiveSMA" ;;
        get-live-ema-rest)                           echo "com.datafye.samples.rest.GetLiveEMA" ;;
        get-live-ema-java)                           echo "com.datafye.samples.java.GetLiveEMA" ;;
        get-securities-rest)                         echo "com.datafye.samples.rest.GetSecurities" ;;
        get-securities-java)                         echo "com.datafye.samples.java.GetSecurities" ;;
        download-tick-history-rest)                   echo "com.datafye.samples.rest.DownloadTickHistory" ;;
        download-tick-history-java)                   echo "com.datafye.samples.java.DownloadTickHistory" ;;
        is-tick-download-running-rest)                echo "com.datafye.samples.rest.IsTickDownloadRunning" ;;
        is-tick-download-running-java)                echo "com.datafye.samples.java.IsTickDownloadRunning" ;;
        cancel-tick-download-rest)                    echo "com.datafye.samples.rest.CancelTickDownload" ;;
        cancel-tick-download-java)                    echo "com.datafye.samples.java.CancelTickDownload" ;;
        download-trade-history-rest)                  echo "com.datafye.samples.rest.DownloadTradeHistory" ;;
        download-trade-history-java)                  echo "com.datafye.samples.java.DownloadTradeHistory" ;;
        is-trade-download-running-rest)               echo "com.datafye.samples.rest.IsTradeDownloadRunning" ;;
        is-trade-download-running-java)               echo "com.datafye.samples.java.IsTradeDownloadRunning" ;;
        cancel-trade-download-rest)                   echo "com.datafye.samples.rest.CancelTradeDownload" ;;
        cancel-trade-download-java)                   echo "com.datafye.samples.java.CancelTradeDownload" ;;
        download-quote-history-rest)                  echo "com.datafye.samples.rest.DownloadQuoteHistory" ;;
        download-quote-history-java)                  echo "com.datafye.samples.java.DownloadQuoteHistory" ;;
        is-quote-download-running-rest)               echo "com.datafye.samples.rest.IsQuoteDownloadRunning" ;;
        is-quote-download-running-java)               echo "com.datafye.samples.java.IsQuoteDownloadRunning" ;;
        cancel-quote-download-rest)                   echo "com.datafye.samples.rest.CancelQuoteDownload" ;;
        cancel-quote-download-java)                   echo "com.datafye.samples.java.CancelQuoteDownload" ;;
        download-ohlc-history-java)                   echo "com.datafye.samples.java.DownloadOHLCHistory" ;;
        is-ohlc-download-running-java)                echo "com.datafye.samples.java.IsOHLCDownloadRunning" ;;
        cancel-ohlc-download-java)                    echo "com.datafye.samples.java.CancelOHLCDownload" ;;
        replay-ticks-rest)                            echo "com.datafye.samples.rest.ReplayTicks" ;;
        replay-ticks-java)                            echo "com.datafye.samples.java.ReplayTicks" ;;
        is-tick-replay-running-rest)                  echo "com.datafye.samples.rest.IsTickReplayRunning" ;;
        is-tick-replay-running-java)                  echo "com.datafye.samples.java.IsTickReplayRunning" ;;
        stop-tick-replay-rest)                        echo "com.datafye.samples.rest.StopTickReplay" ;;
        stop-tick-replay-java)                        echo "com.datafye.samples.java.StopTickReplay" ;;
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
    echo "    get-live-last-trade-rest                   Fetch last trade for symbols"
    echo "    get-live-sma-rest                     Fetch live SMA values"
    echo "    get-live-ema-rest                     Fetch live EMA values"
    echo "    get-securities-rest                   Fetch securities reference data"
    echo ""
    echo "  Java Client:"
    echo "    get-historical-ohlc-java             Fetch historical OHLC bars"
    echo "    get-historical-top-gainers-java       Fetch historical top gainers"
    echo "    get-live-ohlc-java                   Fetch current trading day OHLC bars"
    echo "    get-live-top-of-book-java             Fetch live top-of-book quotes"
    echo "    get-live-last-trade-java                   Fetch last trade for symbols"
    echo "    get-live-sma-java                     Fetch live SMA values"
    echo "    get-live-ema-java                     Fetch live EMA values"
    echo "    get-securities-java                   Fetch securities reference data"
    echo "    stream-historical-ohlc-java              Stream historical OHLC bars"
    echo "    stream-historical-ohlc-concurrently-java"
    echo "                                              Stream historical OHLC bars concurrently"
    echo "    subscribe-live-top-of-book-java            Subscribe to live top-of-book quotes"
    echo "    subscribe-live-trades-java                 Subscribe to live trades"
    echo ""
    echo "  Backtesting (REST):"
    echo "    download-tick-history-rest                Download tick history"
    echo "    is-tick-download-running-rest             Check if tick download is running"
    echo "    cancel-tick-download-rest                 Cancel tick history download"
    echo "    download-trade-history-rest               Download trade history"
    echo "    is-trade-download-running-rest            Check if trade download is running"
    echo "    cancel-trade-download-rest                Cancel trade history download"
    echo "    download-quote-history-rest               Download quote history"
    echo "    is-quote-download-running-rest            Check if quote download is running"
    echo "    cancel-quote-download-rest                Cancel quote history download"
    echo "    replay-ticks-rest                         Replay historical ticks"
    echo "    is-tick-replay-running-rest               Check if tick replay is running"
    echo "    stop-tick-replay-rest                     Stop tick replay"
    echo ""
    echo "  Backtesting (Java Client):"
    echo "    download-tick-history-java                Download tick history"
    echo "    is-tick-download-running-java             Check if tick download is running"
    echo "    cancel-tick-download-java                 Cancel tick history download"
    echo "    download-trade-history-java               Download trade history"
    echo "    is-trade-download-running-java            Check if trade download is running"
    echo "    cancel-trade-download-java                Cancel trade history download"
    echo "    download-quote-history-java               Download quote history"
    echo "    is-quote-download-running-java            Check if quote download is running"
    echo "    cancel-quote-download-java                Cancel quote history download"
    echo "    download-ohlc-history-java                Download OHLC history"
    echo "    is-ohlc-download-running-java             Check if OHLC download is running"
    echo "    cancel-ohlc-download-java                 Cancel OHLC history download"
    echo "    replay-ticks-java                         Replay historical ticks"
    echo "    is-tick-replay-running-java               Check if tick replay is running"
    echo "    stop-tick-replay-java                     Stop tick replay"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") get-historical-ohlc-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00"
}

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ "$1" = "--list" ]; then
    echo "cancel-ohlc-download-java"
    echo "cancel-quote-download-java"
    echo "cancel-quote-download-rest"
    echo "cancel-tick-download-java"
    echo "cancel-tick-download-rest"
    echo "cancel-trade-download-java"
    echo "cancel-trade-download-rest"
    echo "download-ohlc-history-java"
    echo "download-quote-history-java"
    echo "download-quote-history-rest"
    echo "download-tick-history-java"
    echo "download-tick-history-rest"
    echo "download-trade-history-java"
    echo "download-trade-history-rest"
    echo "get-historical-ohlc-java"
    echo "get-historical-ohlc-rest"
    echo "get-historical-top-gainers-java"
    echo "get-historical-top-gainers-rest"
    echo "get-live-last-trade-java"
    echo "get-live-last-trade-rest"
    echo "get-live-ema-java"
    echo "get-live-ema-rest"
    echo "get-live-ohlc-concurrently-rest"
    echo "get-live-ohlc-java"
    echo "get-live-ohlc-rest"
    echo "get-live-sma-java"
    echo "get-live-sma-rest"
    echo "get-live-top-of-book-java"
    echo "get-live-top-of-book-rest"
    echo "get-securities-java"
    echo "get-securities-rest"
    echo "is-ohlc-download-running-java"
    echo "is-quote-download-running-java"
    echo "is-quote-download-running-rest"
    echo "is-tick-download-running-java"
    echo "is-tick-download-running-rest"
    echo "is-tick-replay-running-java"
    echo "is-tick-replay-running-rest"
    echo "is-trade-download-running-java"
    echo "is-trade-download-running-rest"
    echo "replay-ticks-java"
    echo "replay-ticks-rest"
    echo "stop-tick-replay-java"
    echo "stop-tick-replay-rest"
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
