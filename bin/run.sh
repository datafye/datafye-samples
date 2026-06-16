#!/usr/bin/env bash
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

JAVA_OPTS="${JAVA_OPTS:-} --add-opens=java.base/jdk.internal.ref=ALL-UNNAMED \
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED \
--add-opens=java.base/java.lang=ALL-UNNAMED \
--add-opens=java.base/java.nio=ALL-UNNAMED \
--add-opens=java.base/java.io=ALL-UNNAMED \
--add-opens=java.management/sun.management=ALL-UNNAMED"

resolve_class() {
    case "$1" in
        ping-rest)                                  echo "com.datafye.samples.rest.health.Ping" ;;
        get-securities-stocks-rest)                        echo "com.datafye.samples.rest.stocks.reference.GetSecurities" ;;
        get-securities-stocks-java)                        echo "com.datafye.samples.java.stocks.reference.GetSecurities" ;;
        get-securities-crypto-rest)                 echo "com.datafye.samples.rest.crypto.reference.GetSecurities" ;;
        get-securities-crypto-java)                 echo "com.datafye.samples.java.crypto.reference.GetSecurities" ;;
        get-live-top-of-book-stocks-rest)                  echo "com.datafye.samples.rest.stocks.live.ticks.GetLiveTopOfBook" ;;
        get-live-top-of-book-stocks-java)                  echo "com.datafye.samples.java.stocks.live.ticks.GetLiveTopOfBook" ;;
        get-live-top-of-book-crypto-rest)           echo "com.datafye.samples.rest.crypto.live.ticks.GetLiveTopOfBook" ;;
        get-live-top-of-book-crypto-java)           echo "com.datafye.samples.java.crypto.live.ticks.GetLiveTopOfBook" ;;
        get-live-last-trade-stocks-rest)                   echo "com.datafye.samples.rest.stocks.live.ticks.GetLiveLastTrade" ;;
        get-live-last-trade-stocks-java)                   echo "com.datafye.samples.java.stocks.live.ticks.GetLiveLastTrade" ;;
        get-live-last-trade-crypto-rest)            echo "com.datafye.samples.rest.crypto.live.ticks.GetLiveLastTrade" ;;
        get-live-last-trade-crypto-java)            echo "com.datafye.samples.java.crypto.live.ticks.GetLiveLastTrade" ;;
        subscribe-live-top-of-book-stocks-java)            echo "com.datafye.samples.java.stocks.live.ticks.SubscribeLiveTopOfBook" ;;
        subscribe-live-trades-stocks-java)                 echo "com.datafye.samples.java.stocks.live.ticks.SubscribeLiveTrades" ;;
        subscribe-live-ohlc-stocks-java)                   echo "com.datafye.samples.java.stocks.live.aggregates.SubscribeLiveOHLC" ;;
        subscribe-live-ohlc-crypto-java)            echo "com.datafye.samples.java.crypto.live.aggregates.SubscribeLiveOHLC" ;;
        subscribe-live-sma-stocks-java)                    echo "com.datafye.samples.java.stocks.live.aggregates.SubscribeLiveSMA" ;;
        subscribe-live-sma-crypto-java)             echo "com.datafye.samples.java.crypto.live.aggregates.SubscribeLiveSMA" ;;
        subscribe-live-ema-stocks-java)                    echo "com.datafye.samples.java.stocks.live.aggregates.SubscribeLiveEMA" ;;
        subscribe-live-ema-crypto-java)             echo "com.datafye.samples.java.crypto.live.aggregates.SubscribeLiveEMA" ;;
        get-live-ohlc-stocks-rest)                         echo "com.datafye.samples.rest.stocks.live.aggregates.GetLiveOHLC" ;;
        get-live-ohlc-stocks-java)                         echo "com.datafye.samples.java.stocks.live.aggregates.GetLiveOHLC" ;;
        get-live-ohlc-crypto-rest)                  echo "com.datafye.samples.rest.crypto.live.aggregates.GetLiveOHLC" ;;
        get-live-ohlc-crypto-java)                  echo "com.datafye.samples.java.crypto.live.aggregates.GetLiveOHLC" ;;
        get-live-sma-stocks-rest)                          echo "com.datafye.samples.rest.stocks.live.aggregates.GetLiveSMA" ;;
        get-live-sma-stocks-java)                          echo "com.datafye.samples.java.stocks.live.aggregates.GetLiveSMA" ;;
        get-live-sma-crypto-rest)                   echo "com.datafye.samples.rest.crypto.live.aggregates.GetLiveSMA" ;;
        get-live-sma-crypto-java)                   echo "com.datafye.samples.java.crypto.live.aggregates.GetLiveSMA" ;;
        get-live-ema-stocks-rest)                          echo "com.datafye.samples.rest.stocks.live.aggregates.GetLiveEMA" ;;
        get-live-ema-stocks-java)                          echo "com.datafye.samples.java.stocks.live.aggregates.GetLiveEMA" ;;
        get-live-ema-crypto-rest)                   echo "com.datafye.samples.rest.crypto.live.aggregates.GetLiveEMA" ;;
        get-live-ema-crypto-java)                   echo "com.datafye.samples.java.crypto.live.aggregates.GetLiveEMA" ;;
        get-historical-ohlc-stocks-rest)                   echo "com.datafye.samples.rest.stocks.history.GetHistoricalOHLC" ;;
        get-historical-ohlc-stocks-java)                   echo "com.datafye.samples.java.stocks.history.GetHistoricalOHLC" ;;
        get-historical-ohlc-crypto-rest)            echo "com.datafye.samples.rest.crypto.history.GetHistoricalOHLC" ;;
        get-historical-ohlc-crypto-java)            echo "com.datafye.samples.java.crypto.history.GetHistoricalOHLC" ;;
        get-historical-top-gainers-stocks-rest)            echo "com.datafye.samples.rest.stocks.history.GetHistoricalTopGainers" ;;
        get-historical-top-gainers-stocks-java)            echo "com.datafye.samples.java.stocks.history.GetHistoricalTopGainers" ;;
        get-historical-top-gainers-crypto-rest)     echo "com.datafye.samples.rest.crypto.history.GetHistoricalTopGainers" ;;
        get-historical-top-gainers-crypto-java)     echo "com.datafye.samples.java.crypto.history.GetHistoricalTopGainers" ;;
        stream-historical-ohlc-stocks-java)                echo "com.datafye.samples.java.stocks.history.StreamHistoricalOHLC" ;;
        stream-historical-ohlc-crypto-java)         echo "com.datafye.samples.java.crypto.history.StreamHistoricalOHLC" ;;
        stream-historical-ohlc-concurrently-stocks-java)   echo "com.datafye.samples.java.stocks.history.StreamHistoricalOHLCConcurrently" ;;
        stream-historical-ohlc-concurrently-crypto-java) echo "com.datafye.samples.java.crypto.history.StreamHistoricalOHLCConcurrently" ;;
        start-tick-download-stocks-rest)                  echo "com.datafye.samples.rest.stocks.backtest.StartTickDownload" ;;
        start-tick-download-stocks-java)                  echo "com.datafye.samples.java.stocks.backtest.StartTickDownload" ;;
        start-tick-download-crypto-rest)            echo "com.datafye.samples.rest.crypto.backtest.StartTickDownload" ;;
        start-tick-download-crypto-java)            echo "com.datafye.samples.java.crypto.backtest.StartTickDownload" ;;
        is-tick-download-running-stocks-rest)              echo "com.datafye.samples.rest.stocks.backtest.IsTickDownloadRunning" ;;
        is-tick-download-running-stocks-java)              echo "com.datafye.samples.java.stocks.backtest.IsTickDownloadRunning" ;;
        is-tick-download-running-crypto-rest)       echo "com.datafye.samples.rest.crypto.backtest.IsTickDownloadRunning" ;;
        is-tick-download-running-crypto-java)       echo "com.datafye.samples.java.crypto.backtest.IsTickDownloadRunning" ;;
        cancel-tick-download-stocks-rest)                  echo "com.datafye.samples.rest.stocks.backtest.CancelTickDownload" ;;
        cancel-tick-download-stocks-java)                  echo "com.datafye.samples.java.stocks.backtest.CancelTickDownload" ;;
        cancel-tick-download-crypto-rest)           echo "com.datafye.samples.rest.crypto.backtest.CancelTickDownload" ;;
        cancel-tick-download-crypto-java)           echo "com.datafye.samples.java.crypto.backtest.CancelTickDownload" ;;
        start-trade-download-stocks-rest)                  echo "com.datafye.samples.rest.stocks.backtest.StartTradeDownload" ;;
        start-trade-download-stocks-java)                  echo "com.datafye.samples.java.stocks.backtest.StartTradeDownload" ;;
        start-trade-download-crypto-rest)           echo "com.datafye.samples.rest.crypto.backtest.StartTradeDownload" ;;
        start-trade-download-crypto-java)           echo "com.datafye.samples.java.crypto.backtest.StartTradeDownload" ;;
        is-trade-download-running-stocks-rest)             echo "com.datafye.samples.rest.stocks.backtest.IsTradeDownloadRunning" ;;
        is-trade-download-running-stocks-java)             echo "com.datafye.samples.java.stocks.backtest.IsTradeDownloadRunning" ;;
        is-trade-download-running-crypto-rest)      echo "com.datafye.samples.rest.crypto.backtest.IsTradeDownloadRunning" ;;
        is-trade-download-running-crypto-java)      echo "com.datafye.samples.java.crypto.backtest.IsTradeDownloadRunning" ;;
        cancel-trade-download-stocks-rest)                 echo "com.datafye.samples.rest.stocks.backtest.CancelTradeDownload" ;;
        cancel-trade-download-stocks-java)                 echo "com.datafye.samples.java.stocks.backtest.CancelTradeDownload" ;;
        cancel-trade-download-crypto-rest)          echo "com.datafye.samples.rest.crypto.backtest.CancelTradeDownload" ;;
        cancel-trade-download-crypto-java)          echo "com.datafye.samples.java.crypto.backtest.CancelTradeDownload" ;;
        start-quote-download-stocks-rest)                  echo "com.datafye.samples.rest.stocks.backtest.StartQuoteDownload" ;;
        start-quote-download-stocks-java)                  echo "com.datafye.samples.java.stocks.backtest.StartQuoteDownload" ;;
        start-quote-download-crypto-rest)           echo "com.datafye.samples.rest.crypto.backtest.StartQuoteDownload" ;;
        start-quote-download-crypto-java)           echo "com.datafye.samples.java.crypto.backtest.StartQuoteDownload" ;;
        is-quote-download-running-stocks-rest)             echo "com.datafye.samples.rest.stocks.backtest.IsQuoteDownloadRunning" ;;
        is-quote-download-running-stocks-java)             echo "com.datafye.samples.java.stocks.backtest.IsQuoteDownloadRunning" ;;
        is-quote-download-running-crypto-rest)      echo "com.datafye.samples.rest.crypto.backtest.IsQuoteDownloadRunning" ;;
        is-quote-download-running-crypto-java)      echo "com.datafye.samples.java.crypto.backtest.IsQuoteDownloadRunning" ;;
        cancel-quote-download-stocks-rest)                 echo "com.datafye.samples.rest.stocks.backtest.CancelQuoteDownload" ;;
        cancel-quote-download-stocks-java)                 echo "com.datafye.samples.java.stocks.backtest.CancelQuoteDownload" ;;
        cancel-quote-download-crypto-rest)          echo "com.datafye.samples.rest.crypto.backtest.CancelQuoteDownload" ;;
        cancel-quote-download-crypto-java)          echo "com.datafye.samples.java.crypto.backtest.CancelQuoteDownload" ;;
        start-ohlc-download-stocks-rest)                   echo "com.datafye.samples.rest.stocks.backtest.StartOHLCDownload" ;;
        start-ohlc-download-stocks-java)                   echo "com.datafye.samples.java.stocks.backtest.StartOHLCDownload" ;;
        start-ohlc-download-crypto-rest)            echo "com.datafye.samples.rest.crypto.backtest.StartOHLCDownload" ;;
        start-ohlc-download-crypto-java)            echo "com.datafye.samples.java.crypto.backtest.StartOHLCDownload" ;;
        is-ohlc-download-running-stocks-rest)              echo "com.datafye.samples.rest.stocks.backtest.IsOHLCDownloadRunning" ;;
        is-ohlc-download-running-stocks-java)              echo "com.datafye.samples.java.stocks.backtest.IsOHLCDownloadRunning" ;;
        is-ohlc-download-running-crypto-rest)       echo "com.datafye.samples.rest.crypto.backtest.IsOHLCDownloadRunning" ;;
        is-ohlc-download-running-crypto-java)       echo "com.datafye.samples.java.crypto.backtest.IsOHLCDownloadRunning" ;;
        cancel-ohlc-download-stocks-rest)                  echo "com.datafye.samples.rest.stocks.backtest.CancelOHLCDownload" ;;
        cancel-ohlc-download-stocks-java)                  echo "com.datafye.samples.java.stocks.backtest.CancelOHLCDownload" ;;
        cancel-ohlc-download-crypto-rest)           echo "com.datafye.samples.rest.crypto.backtest.CancelOHLCDownload" ;;
        cancel-ohlc-download-crypto-java)           echo "com.datafye.samples.java.crypto.backtest.CancelOHLCDownload" ;;
        start-tick-replay-stocks-rest)                     echo "com.datafye.samples.rest.stocks.backtest.StartTickReplay" ;;
        start-tick-replay-stocks-java)                     echo "com.datafye.samples.java.stocks.backtest.StartTickReplay" ;;
        start-tick-replay-crypto-rest)              echo "com.datafye.samples.rest.crypto.backtest.StartTickReplay" ;;
        start-tick-replay-crypto-java)              echo "com.datafye.samples.java.crypto.backtest.StartTickReplay" ;;
        is-tick-replay-running-stocks-rest)                echo "com.datafye.samples.rest.stocks.backtest.IsTickReplayRunning" ;;
        is-tick-replay-running-stocks-java)                echo "com.datafye.samples.java.stocks.backtest.IsTickReplayRunning" ;;
        is-tick-replay-running-crypto-rest)         echo "com.datafye.samples.rest.crypto.backtest.IsTickReplayRunning" ;;
        is-tick-replay-running-crypto-java)         echo "com.datafye.samples.java.crypto.backtest.IsTickReplayRunning" ;;
        stop-tick-replay-stocks-rest)                      echo "com.datafye.samples.rest.stocks.backtest.StopTickReplay" ;;
        stop-tick-replay-stocks-java)                      echo "com.datafye.samples.java.stocks.backtest.StopTickReplay" ;;
        stop-tick-replay-crypto-rest)               echo "com.datafye.samples.rest.crypto.backtest.StopTickReplay" ;;
        stop-tick-replay-crypto-java)               echo "com.datafye.samples.java.crypto.backtest.StopTickReplay" ;;
        subscribe-live-trades-ws)                   echo "com.datafye.samples.ws.SubscribeLiveTrades" ;;
        subscribe-live-top-of-book-ws)              echo "com.datafye.samples.ws.SubscribeLiveTopOfBook" ;;
        subscribe-live-ohlc-ws)                     echo "com.datafye.samples.ws.SubscribeLiveOHLC" ;;
        subscribe-live-sma-ws)                      echo "com.datafye.samples.ws.SubscribeLiveSMA" ;;
        subscribe-live-ema-ws)                      echo "com.datafye.samples.ws.SubscribeLiveEMA" ;;
        stream-historical-ohlc-ws)                  echo "com.datafye.samples.ws.StreamHistoricalOHLC" ;;
        *) return 1 ;;
    esac
}

usage() {
    echo "Usage: $(basename "$0") <sample-name> [sample-args...]"
    echo ""
    echo "Sample names follow the pattern  <operation>-<stocks|crypto>-<rest|java|ws>:"
    echo "    stocks   runs against the SIP or Synthetic dataset (pick one with -D)"
    echo "    crypto   runs against the Crypto dataset"
    echo "    rest = HTTP + JSON     java = typed Java client     ws = WebSocket stream"
    echo "Run a sample with -h for its own arguments, or '$(basename "$0") --list' for every id."
    echo ""
    echo "Sample families:"
    echo ""
    echo "  Health"
    echo "      A quick liveness check against a deployed Datafye environment."
    echo "        ping-rest"
    echo ""
    echo "  Reference"
    echo "      The securities master - the tradable symbols available in a dataset."
    echo "        get-securities-{stocks,crypto}-{rest,java}"
    echo ""
    echo "  Live ticks"
    echo "      Real-time trade prints and top-of-book quotes. Fetch the latest value on"
    echo "      demand (get-live-*), or open a continuous stream (subscribe-live-*)."
    echo "        get-live-top-of-book-{stocks,crypto}-{rest,java}"
    echo "        get-live-last-trade-{stocks,crypto}-{rest,java}"
    echo "        subscribe-live-{top-of-book,trades}-stocks-java"
    echo ""
    echo "  Live aggregates"
    echo "      OHLC candles plus SMA/EMA moving averages for the current trading day."
    echo "      Fetch a snapshot (get-live-*), or subscribe to each value as its bar"
    echo "      finalizes (subscribe-live-*)."
    echo "        get-live-{ohlc,sma,ema}-{stocks,crypto}-{rest,java}"
    echo "        subscribe-live-{ohlc,sma,ema}-{stocks,crypto}-java"
    echo ""
    echo "  History"
    echo "      Past-dated OHLC bars and derived analytics (top gainers). Fetch a date"
    echo "      range, or stream it back (optionally many symbols concurrently)."
    echo "        get-historical-ohlc-{stocks,crypto}-{rest,java}"
    echo "        get-historical-top-gainers-{stocks,crypto}-{rest,java}"
    echo "        stream-historical-ohlc-{stocks,crypto}-java"
    echo "        stream-historical-ohlc-concurrently-{stocks,crypto}-java"
    echo ""
    echo "  WebSocket streaming"
    echo "      The same live trades / quotes / bars / indicators delivered over a"
    echo "      WebSocket as untyped JSON. One endpoint per data type serves every"
    echo "      dataset; pick the dataset with -d."
    echo "        subscribe-live-{trades,top-of-book,ohlc,sma,ema}-ws"
    echo "        stream-historical-ohlc-ws"
    echo ""
    echo "  Backtesting"
    echo "      Build a historical tape and replay it through the live pipeline: download"
    echo "      a day of data into the environment, then replay it. Each download and the"
    echo "      replay expose start / is-running / cancel (stop) controls."
    echo "        start-{tick,trade,quote,ohlc}-download-{stocks,crypto}-{rest,java}"
    echo "        is-{tick,trade,quote,ohlc}-download-running-{stocks,crypto}-{rest,java}"
    echo "        cancel-{tick,trade,quote,ohlc}-download-{stocks,crypto}-{rest,java}"
    echo "        start-tick-replay-{stocks,crypto}-{rest,java}"
    echo "        is-tick-replay-running-{stocks,crypto}-{rest,java}"
    echo "        stop-tick-replay-{stocks,crypto}-{rest,java}"
    echo ""
    echo "Example:"
    echo "  $(basename "$0") get-historical-ohlc-stocks-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00"
}

if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    usage
    exit 0
fi

if [ "$1" = "--list" ]; then
    echo "cancel-ohlc-download-crypto-java"
    echo "cancel-ohlc-download-crypto-rest"
    echo "cancel-ohlc-download-stocks-java"
    echo "cancel-ohlc-download-stocks-rest"
    echo "cancel-quote-download-crypto-java"
    echo "cancel-quote-download-crypto-rest"
    echo "cancel-quote-download-stocks-java"
    echo "cancel-quote-download-stocks-rest"
    echo "cancel-tick-download-crypto-java"
    echo "cancel-tick-download-crypto-rest"
    echo "cancel-tick-download-stocks-java"
    echo "cancel-tick-download-stocks-rest"
    echo "cancel-trade-download-crypto-java"
    echo "cancel-trade-download-crypto-rest"
    echo "cancel-trade-download-stocks-java"
    echo "cancel-trade-download-stocks-rest"
    echo "get-historical-ohlc-crypto-java"
    echo "get-historical-ohlc-crypto-rest"
    echo "get-historical-ohlc-stocks-java"
    echo "get-historical-ohlc-stocks-rest"
    echo "get-historical-top-gainers-crypto-java"
    echo "get-historical-top-gainers-crypto-rest"
    echo "get-historical-top-gainers-stocks-java"
    echo "get-historical-top-gainers-stocks-rest"
    echo "get-live-ema-crypto-java"
    echo "get-live-ema-crypto-rest"
    echo "get-live-ema-stocks-java"
    echo "get-live-ema-stocks-rest"
    echo "get-live-last-trade-crypto-java"
    echo "get-live-last-trade-crypto-rest"
    echo "get-live-last-trade-stocks-java"
    echo "get-live-last-trade-stocks-rest"
    echo "get-live-ohlc-crypto-java"
    echo "get-live-ohlc-crypto-rest"
    echo "get-live-ohlc-stocks-java"
    echo "get-live-ohlc-stocks-rest"
    echo "get-live-sma-crypto-java"
    echo "get-live-sma-crypto-rest"
    echo "get-live-sma-stocks-java"
    echo "get-live-sma-stocks-rest"
    echo "get-live-top-of-book-crypto-java"
    echo "get-live-top-of-book-crypto-rest"
    echo "get-live-top-of-book-stocks-java"
    echo "get-live-top-of-book-stocks-rest"
    echo "get-securities-crypto-java"
    echo "get-securities-crypto-rest"
    echo "get-securities-stocks-java"
    echo "get-securities-stocks-rest"
    echo "is-ohlc-download-running-crypto-java"
    echo "is-ohlc-download-running-crypto-rest"
    echo "is-ohlc-download-running-stocks-java"
    echo "is-ohlc-download-running-stocks-rest"
    echo "is-quote-download-running-crypto-java"
    echo "is-quote-download-running-crypto-rest"
    echo "is-quote-download-running-stocks-java"
    echo "is-quote-download-running-stocks-rest"
    echo "is-tick-download-running-crypto-java"
    echo "is-tick-download-running-crypto-rest"
    echo "is-tick-download-running-stocks-java"
    echo "is-tick-download-running-stocks-rest"
    echo "is-tick-replay-running-crypto-java"
    echo "is-tick-replay-running-crypto-rest"
    echo "is-tick-replay-running-stocks-java"
    echo "is-tick-replay-running-stocks-rest"
    echo "is-trade-download-running-crypto-java"
    echo "is-trade-download-running-crypto-rest"
    echo "is-trade-download-running-stocks-java"
    echo "is-trade-download-running-stocks-rest"
    echo "ping-rest"
    echo "start-ohlc-download-crypto-java"
    echo "start-ohlc-download-crypto-rest"
    echo "start-ohlc-download-stocks-java"
    echo "start-ohlc-download-stocks-rest"
    echo "start-quote-download-crypto-java"
    echo "start-quote-download-crypto-rest"
    echo "start-quote-download-stocks-java"
    echo "start-quote-download-stocks-rest"
    echo "start-tick-download-crypto-java"
    echo "start-tick-download-crypto-rest"
    echo "start-tick-download-stocks-java"
    echo "start-tick-download-stocks-rest"
    echo "start-tick-replay-crypto-java"
    echo "start-tick-replay-crypto-rest"
    echo "start-tick-replay-stocks-java"
    echo "start-tick-replay-stocks-rest"
    echo "start-trade-download-crypto-java"
    echo "start-trade-download-crypto-rest"
    echo "start-trade-download-stocks-java"
    echo "start-trade-download-stocks-rest"
    echo "stop-tick-replay-crypto-java"
    echo "stop-tick-replay-crypto-rest"
    echo "stop-tick-replay-stocks-java"
    echo "stop-tick-replay-stocks-rest"
    echo "stream-historical-ohlc-concurrently-crypto-java"
    echo "stream-historical-ohlc-concurrently-stocks-java"
    echo "stream-historical-ohlc-crypto-java"
    echo "stream-historical-ohlc-stocks-java"
    echo "stream-historical-ohlc-ws"
    echo "subscribe-live-ema-crypto-java"
    echo "subscribe-live-ema-stocks-java"
    echo "subscribe-live-ema-ws"
    echo "subscribe-live-ohlc-crypto-java"
    echo "subscribe-live-ohlc-stocks-java"
    echo "subscribe-live-ohlc-ws"
    echo "subscribe-live-sma-crypto-java"
    echo "subscribe-live-sma-stocks-java"
    echo "subscribe-live-sma-ws"
    echo "subscribe-live-top-of-book-stocks-java"
    echo "subscribe-live-top-of-book-ws"
    echo "subscribe-live-trades-stocks-java"
    echo "subscribe-live-trades-ws"
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
