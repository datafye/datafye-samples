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
        ping-rest)                                  echo "com.datafye.samples.rest.health.Ping" ;;
        get-securities-rest)                        echo "com.datafye.samples.rest.reference.GetSecurities" ;;
        get-securities-java)                        echo "com.datafye.samples.java.reference.GetSecurities" ;;
        get-live-top-of-book-rest)                  echo "com.datafye.samples.rest.live.ticks.GetLiveTopOfBook" ;;
        get-live-top-of-book-java)                  echo "com.datafye.samples.java.live.ticks.GetLiveTopOfBook" ;;
        get-live-last-trade-rest)                   echo "com.datafye.samples.rest.live.ticks.GetLiveLastTrade" ;;
        get-live-last-trade-java)                   echo "com.datafye.samples.java.live.ticks.GetLiveLastTrade" ;;
        subscribe-live-top-of-book-java)            echo "com.datafye.samples.java.live.ticks.SubscribeLiveTopOfBook" ;;
        subscribe-live-trades-java)                 echo "com.datafye.samples.java.live.ticks.SubscribeLiveTrades" ;;
        get-live-ohlc-rest)                         echo "com.datafye.samples.rest.live.aggregates.GetLiveOHLC" ;;
        get-live-ohlc-java)                         echo "com.datafye.samples.java.live.aggregates.GetLiveOHLC" ;;
        get-live-sma-rest)                          echo "com.datafye.samples.rest.live.aggregates.GetLiveSMA" ;;
        get-live-sma-java)                          echo "com.datafye.samples.java.live.aggregates.GetLiveSMA" ;;
        get-live-ema-rest)                          echo "com.datafye.samples.rest.live.aggregates.GetLiveEMA" ;;
        get-live-ema-java)                          echo "com.datafye.samples.java.live.aggregates.GetLiveEMA" ;;
        get-historical-ohlc-rest)                   echo "com.datafye.samples.rest.history.GetHistoricalOHLC" ;;
        get-historical-ohlc-java)                   echo "com.datafye.samples.java.history.GetHistoricalOHLC" ;;
        get-historical-top-gainers-rest)            echo "com.datafye.samples.rest.history.GetHistoricalTopGainers" ;;
        get-historical-top-gainers-java)            echo "com.datafye.samples.java.history.GetHistoricalTopGainers" ;;
        stream-historical-ohlc-java)                echo "com.datafye.samples.java.history.StreamHistoricalOHLC" ;;
        stream-historical-ohlc-concurrently-java)   echo "com.datafye.samples.java.history.StreamHistoricalOHLCConcurrently" ;;
        start-tick-download-rest)                  echo "com.datafye.samples.rest.backtest.StartTickDownload" ;;
        start-tick-download-java)                  echo "com.datafye.samples.java.backtest.StartTickDownload" ;;
        is-tick-download-running-rest)              echo "com.datafye.samples.rest.backtest.IsTickDownloadRunning" ;;
        is-tick-download-running-java)              echo "com.datafye.samples.java.backtest.IsTickDownloadRunning" ;;
        cancel-tick-download-rest)                  echo "com.datafye.samples.rest.backtest.CancelTickDownload" ;;
        cancel-tick-download-java)                  echo "com.datafye.samples.java.backtest.CancelTickDownload" ;;
        start-trade-download-rest)                  echo "com.datafye.samples.rest.backtest.StartTradeDownload" ;;
        start-trade-download-java)                  echo "com.datafye.samples.java.backtest.StartTradeDownload" ;;
        is-trade-download-running-rest)             echo "com.datafye.samples.rest.backtest.IsTradeDownloadRunning" ;;
        is-trade-download-running-java)             echo "com.datafye.samples.java.backtest.IsTradeDownloadRunning" ;;
        cancel-trade-download-rest)                 echo "com.datafye.samples.rest.backtest.CancelTradeDownload" ;;
        cancel-trade-download-java)                 echo "com.datafye.samples.java.backtest.CancelTradeDownload" ;;
        start-quote-download-rest)                  echo "com.datafye.samples.rest.backtest.StartQuoteDownload" ;;
        start-quote-download-java)                  echo "com.datafye.samples.java.backtest.StartQuoteDownload" ;;
        is-quote-download-running-rest)             echo "com.datafye.samples.rest.backtest.IsQuoteDownloadRunning" ;;
        is-quote-download-running-java)             echo "com.datafye.samples.java.backtest.IsQuoteDownloadRunning" ;;
        cancel-quote-download-rest)                 echo "com.datafye.samples.rest.backtest.CancelQuoteDownload" ;;
        cancel-quote-download-java)                 echo "com.datafye.samples.java.backtest.CancelQuoteDownload" ;;
        start-ohlc-download-rest)                   echo "com.datafye.samples.rest.backtest.StartOHLCDownload" ;;
        start-ohlc-download-java)                   echo "com.datafye.samples.java.backtest.StartOHLCDownload" ;;
        is-ohlc-download-running-rest)              echo "com.datafye.samples.rest.backtest.IsOHLCDownloadRunning" ;;
        is-ohlc-download-running-java)              echo "com.datafye.samples.java.backtest.IsOHLCDownloadRunning" ;;
        cancel-ohlc-download-rest)                  echo "com.datafye.samples.rest.backtest.CancelOHLCDownload" ;;
        cancel-ohlc-download-java)                  echo "com.datafye.samples.java.backtest.CancelOHLCDownload" ;;
        start-tick-replay-rest)                     echo "com.datafye.samples.rest.backtest.StartTickReplay" ;;
        start-tick-replay-java)                     echo "com.datafye.samples.java.backtest.StartTickReplay" ;;
        is-tick-replay-running-rest)                echo "com.datafye.samples.rest.backtest.IsTickReplayRunning" ;;
        is-tick-replay-running-java)                echo "com.datafye.samples.java.backtest.IsTickReplayRunning" ;;
        stop-tick-replay-rest)                      echo "com.datafye.samples.rest.backtest.StopTickReplay" ;;
        stop-tick-replay-java)                      echo "com.datafye.samples.java.backtest.StopTickReplay" ;;
        *) return 1 ;;
    esac
}

usage() {
    echo "Usage: $(basename "$0") <sample-name> [sample-args...]"
    echo ""
    echo "Available samples:"
    echo ""
    echo "  Health:"
    echo "    ping-rest                              Ping deployment health"
    echo ""
    echo "  Reference:"
    echo "    get-securities-rest                    Fetch securities reference data"
    echo "    get-securities-java                    Fetch securities reference data"
    echo ""
    echo "  Live - Ticks:"
    echo "    get-live-top-of-book-rest              Fetch live top-of-book quotes"
    echo "    get-live-top-of-book-java              Fetch live top-of-book quotes"
    echo "    get-live-last-trade-rest               Fetch last trade for symbols"
    echo "    get-live-last-trade-java               Fetch last trade for symbols"
    echo "    subscribe-live-top-of-book-java        Subscribe to live top-of-book quotes"
    echo "    subscribe-live-trades-java             Subscribe to live trades"
    echo ""
    echo "  Live - Aggregates:"
    echo "    get-live-ohlc-rest                     Fetch current trading day OHLC bars"
    echo "    get-live-ohlc-java                     Fetch current trading day OHLC bars"
    echo "    get-live-sma-rest                      Fetch live SMA values"
    echo "    get-live-sma-java                      Fetch live SMA values"
    echo "    get-live-ema-rest                      Fetch live EMA values"
    echo "    get-live-ema-java                      Fetch live EMA values"
    echo ""
    echo "  History:"
    echo "    get-historical-ohlc-rest               Fetch historical OHLC bars"
    echo "    get-historical-ohlc-java               Fetch historical OHLC bars"
    echo "    get-historical-top-gainers-rest         Fetch historical top gainers"
    echo "    get-historical-top-gainers-java         Fetch historical top gainers"
    echo "    stream-historical-ohlc-java            Stream historical OHLC bars"
    echo "    stream-historical-ohlc-concurrently-java"
    echo "                                           Stream historical OHLC bars concurrently"
    echo ""
    echo "  Backtesting (REST):"
    echo "    start-tick-download-rest                Start tick history download"
    echo "    is-tick-download-running-rest           Check if tick download is running"
    echo "    cancel-tick-download-rest               Cancel tick history download"
    echo "    start-trade-download-rest               Start trade history download"
    echo "    is-trade-download-running-rest          Check if trade download is running"
    echo "    cancel-trade-download-rest              Cancel trade history download"
    echo "    start-quote-download-rest               Start quote history download"
    echo "    is-quote-download-running-rest          Check if quote download is running"
    echo "    cancel-quote-download-rest              Cancel quote history download"
    echo "    start-tick-replay-rest                  Start tick replay"
    echo "    is-tick-replay-running-rest             Check if tick replay is running"
    echo "    stop-tick-replay-rest                   Stop tick replay"
    echo ""
    echo "  Backtesting (Java Client):"
    echo "    start-tick-download-java                Start tick history download"
    echo "    is-tick-download-running-java           Check if tick download is running"
    echo "    cancel-tick-download-java               Cancel tick history download"
    echo "    start-trade-download-java               Start trade history download"
    echo "    is-trade-download-running-java          Check if trade download is running"
    echo "    cancel-trade-download-java              Cancel trade history download"
    echo "    start-quote-download-java               Start quote history download"
    echo "    is-quote-download-running-java          Check if quote download is running"
    echo "    cancel-quote-download-java              Cancel quote history download"
    echo "    start-ohlc-download-rest                Start OHLC history download"
    echo "    start-ohlc-download-java                Start OHLC history download"
    echo "    is-ohlc-download-running-rest           Check if OHLC download is running"
    echo "    is-ohlc-download-running-java           Check if OHLC download is running"
    echo "    cancel-ohlc-download-rest               Cancel OHLC history download"
    echo "    cancel-ohlc-download-java               Cancel OHLC history download"
    echo "    start-tick-replay-java                  Start tick replay"
    echo "    is-tick-replay-running-java             Check if tick replay is running"
    echo "    stop-tick-replay-java                   Stop tick replay"
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
    echo "cancel-ohlc-download-rest"
    echo "cancel-quote-download-java"
    echo "cancel-quote-download-rest"
    echo "cancel-tick-download-java"
    echo "cancel-tick-download-rest"
    echo "cancel-trade-download-java"
    echo "cancel-trade-download-rest"
    echo "get-historical-ohlc-java"
    echo "get-historical-ohlc-rest"
    echo "get-historical-top-gainers-java"
    echo "get-historical-top-gainers-rest"
    echo "get-live-ema-java"
    echo "get-live-ema-rest"
    echo "get-live-last-trade-java"
    echo "get-live-last-trade-rest"
    echo "get-live-ohlc-java"
    echo "get-live-ohlc-rest"
    echo "get-live-sma-java"
    echo "get-live-sma-rest"
    echo "get-live-top-of-book-java"
    echo "get-live-top-of-book-rest"
    echo "get-securities-java"
    echo "get-securities-rest"
    echo "is-ohlc-download-running-java"
    echo "is-ohlc-download-running-rest"
    echo "is-quote-download-running-java"
    echo "is-quote-download-running-rest"
    echo "is-tick-download-running-java"
    echo "is-tick-download-running-rest"
    echo "is-tick-replay-running-java"
    echo "is-tick-replay-running-rest"
    echo "is-trade-download-running-java"
    echo "is-trade-download-running-rest"
    echo "ping-rest"
    echo "start-ohlc-download-java"
    echo "start-ohlc-download-rest"
    echo "start-quote-download-java"
    echo "start-quote-download-rest"
    echo "start-tick-download-java"
    echo "start-tick-download-rest"
    echo "start-tick-replay-java"
    echo "start-tick-replay-rest"
    echo "start-trade-download-java"
    echo "start-trade-download-rest"
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
