@echo off
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set BASE_DIR=%SCRIPT_DIR%..

set JAVA_OPTS=--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED ^
--add-opens=java.base/sun.nio.ch=ALL-UNNAMED ^
--add-opens=java.base/java.lang=ALL-UNNAMED ^
--add-opens=java.base/java.nio=ALL-UNNAMED ^
--add-opens=java.base/java.io=ALL-UNNAMED ^
--add-opens=java.management/sun.management=ALL-UNNAMED

if "%~1"=="" goto :usage
if "%~1"=="--help" goto :usage
if "%~1"=="-h" goto :usage
if "%~1"=="--list" goto :list

set SAMPLE_NAME=%~1

if "%SAMPLE_NAME%"=="ping-rest" set CLASS=com.datafye.samples.rest.health.Ping
if "%SAMPLE_NAME%"=="get-securities-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.reference.GetSecurities
if "%SAMPLE_NAME%"=="get-securities-stocks-java" set CLASS=com.datafye.samples.java.stocks.reference.GetSecurities
if "%SAMPLE_NAME%"=="get-securities-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.reference.GetSecurities
if "%SAMPLE_NAME%"=="get-securities-crypto-java" set CLASS=com.datafye.samples.java.crypto.reference.GetSecurities
if "%SAMPLE_NAME%"=="get-live-top-of-book-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.live.ticks.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-top-of-book-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.ticks.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-top-of-book-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.live.ticks.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-top-of-book-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.ticks.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-last-trade-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.live.ticks.GetLiveLastTrade
if "%SAMPLE_NAME%"=="get-live-last-trade-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.ticks.GetLiveLastTrade
if "%SAMPLE_NAME%"=="get-live-last-trade-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.live.ticks.GetLiveLastTrade
if "%SAMPLE_NAME%"=="get-live-last-trade-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.ticks.GetLiveLastTrade
if "%SAMPLE_NAME%"=="subscribe-live-top-of-book-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.ticks.SubscribeLiveTopOfBook
if "%SAMPLE_NAME%"=="subscribe-live-trades-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.ticks.SubscribeLiveTrades
if "%SAMPLE_NAME%"=="subscribe-live-ohlc-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.aggregates.SubscribeLiveOHLC
if "%SAMPLE_NAME%"=="subscribe-live-ohlc-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.aggregates.SubscribeLiveOHLC
if "%SAMPLE_NAME%"=="subscribe-live-sma-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.aggregates.SubscribeLiveSMA
if "%SAMPLE_NAME%"=="subscribe-live-sma-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.aggregates.SubscribeLiveSMA
if "%SAMPLE_NAME%"=="subscribe-live-ema-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.aggregates.SubscribeLiveEMA
if "%SAMPLE_NAME%"=="subscribe-live-ema-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.aggregates.SubscribeLiveEMA
if "%SAMPLE_NAME%"=="get-live-ohlc-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.live.aggregates.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-ohlc-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.aggregates.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-ohlc-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.live.aggregates.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-ohlc-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.aggregates.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-sma-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.live.aggregates.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-sma-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.aggregates.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-sma-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.live.aggregates.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-sma-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.aggregates.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-ema-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.live.aggregates.GetLiveEMA
if "%SAMPLE_NAME%"=="get-live-ema-stocks-java" set CLASS=com.datafye.samples.java.stocks.live.aggregates.GetLiveEMA
if "%SAMPLE_NAME%"=="get-live-ema-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.live.aggregates.GetLiveEMA
if "%SAMPLE_NAME%"=="get-live-ema-crypto-java" set CLASS=com.datafye.samples.java.crypto.live.aggregates.GetLiveEMA
if "%SAMPLE_NAME%"=="get-historical-ohlc-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.history.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-historical-ohlc-stocks-java" set CLASS=com.datafye.samples.java.stocks.history.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-historical-ohlc-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.history.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-historical-ohlc-crypto-java" set CLASS=com.datafye.samples.java.crypto.history.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-historical-top-gainers-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.history.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="get-historical-top-gainers-stocks-java" set CLASS=com.datafye.samples.java.stocks.history.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="get-historical-top-gainers-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.history.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="get-historical-top-gainers-crypto-java" set CLASS=com.datafye.samples.java.crypto.history.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="stream-historical-ohlc-stocks-java" set CLASS=com.datafye.samples.java.stocks.history.StreamHistoricalOHLC
if "%SAMPLE_NAME%"=="stream-historical-ohlc-crypto-java" set CLASS=com.datafye.samples.java.crypto.history.StreamHistoricalOHLC
if "%SAMPLE_NAME%"=="stream-historical-ohlc-concurrently-stocks-java" set CLASS=com.datafye.samples.java.stocks.history.StreamHistoricalOHLCConcurrently
if "%SAMPLE_NAME%"=="stream-historical-ohlc-concurrently-crypto-java" set CLASS=com.datafye.samples.java.crypto.history.StreamHistoricalOHLCConcurrently
if "%SAMPLE_NAME%"=="start-tick-download-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.StartTickDownload
if "%SAMPLE_NAME%"=="start-tick-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.StartTickDownload
if "%SAMPLE_NAME%"=="start-tick-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.StartTickDownload
if "%SAMPLE_NAME%"=="start-tick-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.StartTickDownload
if "%SAMPLE_NAME%"=="is-tick-download-running-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.IsTickDownloadRunning
if "%SAMPLE_NAME%"=="is-tick-download-running-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.IsTickDownloadRunning
if "%SAMPLE_NAME%"=="is-tick-download-running-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.IsTickDownloadRunning
if "%SAMPLE_NAME%"=="is-tick-download-running-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.IsTickDownloadRunning
if "%SAMPLE_NAME%"=="cancel-tick-download-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.CancelTickDownload
if "%SAMPLE_NAME%"=="cancel-tick-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.CancelTickDownload
if "%SAMPLE_NAME%"=="cancel-tick-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.CancelTickDownload
if "%SAMPLE_NAME%"=="cancel-tick-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.CancelTickDownload
if "%SAMPLE_NAME%"=="start-trade-download-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.StartTradeDownload
if "%SAMPLE_NAME%"=="start-trade-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.StartTradeDownload
if "%SAMPLE_NAME%"=="start-trade-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.StartTradeDownload
if "%SAMPLE_NAME%"=="start-trade-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.StartTradeDownload
if "%SAMPLE_NAME%"=="is-trade-download-running-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.IsTradeDownloadRunning
if "%SAMPLE_NAME%"=="is-trade-download-running-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.IsTradeDownloadRunning
if "%SAMPLE_NAME%"=="is-trade-download-running-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.IsTradeDownloadRunning
if "%SAMPLE_NAME%"=="is-trade-download-running-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.IsTradeDownloadRunning
if "%SAMPLE_NAME%"=="cancel-trade-download-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.CancelTradeDownload
if "%SAMPLE_NAME%"=="cancel-trade-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.CancelTradeDownload
if "%SAMPLE_NAME%"=="cancel-trade-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.CancelTradeDownload
if "%SAMPLE_NAME%"=="cancel-trade-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.CancelTradeDownload
if "%SAMPLE_NAME%"=="start-quote-download-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.StartQuoteDownload
if "%SAMPLE_NAME%"=="start-quote-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.StartQuoteDownload
if "%SAMPLE_NAME%"=="start-quote-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.StartQuoteDownload
if "%SAMPLE_NAME%"=="start-quote-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.StartQuoteDownload
if "%SAMPLE_NAME%"=="is-quote-download-running-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.IsQuoteDownloadRunning
if "%SAMPLE_NAME%"=="is-quote-download-running-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.IsQuoteDownloadRunning
if "%SAMPLE_NAME%"=="is-quote-download-running-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.IsQuoteDownloadRunning
if "%SAMPLE_NAME%"=="is-quote-download-running-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.IsQuoteDownloadRunning
if "%SAMPLE_NAME%"=="cancel-quote-download-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.CancelQuoteDownload
if "%SAMPLE_NAME%"=="cancel-quote-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.CancelQuoteDownload
if "%SAMPLE_NAME%"=="cancel-quote-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.CancelQuoteDownload
if "%SAMPLE_NAME%"=="cancel-quote-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.CancelQuoteDownload
if "%SAMPLE_NAME%"=="start-ohlc-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.StartOHLCDownload
if "%SAMPLE_NAME%"=="start-ohlc-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.StartOHLCDownload
if "%SAMPLE_NAME%"=="start-ohlc-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.StartOHLCDownload
if "%SAMPLE_NAME%"=="is-ohlc-download-running-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.IsOHLCDownloadRunning
if "%SAMPLE_NAME%"=="is-ohlc-download-running-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.IsOHLCDownloadRunning
if "%SAMPLE_NAME%"=="is-ohlc-download-running-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.IsOHLCDownloadRunning
if "%SAMPLE_NAME%"=="cancel-ohlc-download-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.CancelOHLCDownload
if "%SAMPLE_NAME%"=="cancel-ohlc-download-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.CancelOHLCDownload
if "%SAMPLE_NAME%"=="cancel-ohlc-download-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.CancelOHLCDownload
if "%SAMPLE_NAME%"=="start-tick-replay-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.StartTickReplay
if "%SAMPLE_NAME%"=="start-tick-replay-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.StartTickReplay
if "%SAMPLE_NAME%"=="start-tick-replay-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.StartTickReplay
if "%SAMPLE_NAME%"=="start-tick-replay-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.StartTickReplay
if "%SAMPLE_NAME%"=="is-tick-replay-running-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.IsTickReplayRunning
if "%SAMPLE_NAME%"=="is-tick-replay-running-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.IsTickReplayRunning
if "%SAMPLE_NAME%"=="is-tick-replay-running-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.IsTickReplayRunning
if "%SAMPLE_NAME%"=="is-tick-replay-running-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.IsTickReplayRunning
if "%SAMPLE_NAME%"=="stop-tick-replay-stocks-rest" set CLASS=com.datafye.samples.rest.stocks.backtest.StopTickReplay
if "%SAMPLE_NAME%"=="stop-tick-replay-stocks-java" set CLASS=com.datafye.samples.java.stocks.backtest.StopTickReplay
if "%SAMPLE_NAME%"=="stop-tick-replay-crypto-rest" set CLASS=com.datafye.samples.rest.crypto.backtest.StopTickReplay
if "%SAMPLE_NAME%"=="stop-tick-replay-crypto-java" set CLASS=com.datafye.samples.java.crypto.backtest.StopTickReplay
if "%SAMPLE_NAME%"=="subscribe-live-trades-ws" set CLASS=com.datafye.samples.ws.SubscribeLiveTrades
if "%SAMPLE_NAME%"=="subscribe-live-top-of-book-ws" set CLASS=com.datafye.samples.ws.SubscribeLiveTopOfBook
if "%SAMPLE_NAME%"=="subscribe-live-ohlc-ws" set CLASS=com.datafye.samples.ws.SubscribeLiveOHLC
if "%SAMPLE_NAME%"=="subscribe-live-sma-ws" set CLASS=com.datafye.samples.ws.SubscribeLiveSMA
if "%SAMPLE_NAME%"=="subscribe-live-ema-ws" set CLASS=com.datafye.samples.ws.SubscribeLiveEMA
if "%SAMPLE_NAME%"=="stream-historical-ohlc-ws" set CLASS=com.datafye.samples.ws.StreamHistoricalOHLC

if not defined CLASS (
    echo Error: Unknown sample '%SAMPLE_NAME%' >&2
    echo. >&2
    echo Run '%~nx0 --help' to see available samples. >&2
    exit /b 1
)

shift
java %JAVA_OPTS% -cp "%BASE_DIR%\libs\*" %CLASS% %*
exit /b %ERRORLEVEL%

:usage
echo Usage: %~nx0 ^<sample-name^> [sample-args...]
echo.
echo Sample names follow the pattern  ^<operation^>-^<stocks^|crypto^>-^<rest^|java^|ws^>:
echo     stocks   runs against the SIP or Synthetic dataset (pick one with -D)
echo     crypto   runs against the Crypto dataset
echo     rest = HTTP + JSON     java = typed Java client     ws = WebSocket stream
echo Run a sample with -h for its own arguments, or '%~nx0 --list' for every id.
echo.
echo Sample families:
echo.
echo   Health
echo       A quick liveness check against a deployed Datafye environment.
echo         ping-rest
echo.
echo   Reference
echo       The securities master - the tradable symbols available in a dataset.
echo         get-securities-{stocks,crypto}-{rest,java}
echo.
echo   Live ticks
echo       Real-time trade prints and top-of-book quotes. Fetch the latest value on
echo       demand (get-live-*), or open a continuous stream (subscribe-live-*).
echo         get-live-top-of-book-{stocks,crypto}-{rest,java}
echo         get-live-last-trade-{stocks,crypto}-{rest,java}
echo         subscribe-live-{top-of-book,trades}-stocks-java
echo.
echo   Live aggregates
echo       OHLC candles plus SMA/EMA moving averages for the current trading day.
echo       Fetch a snapshot (get-live-*), or subscribe to each value as its bar
echo       finalizes (subscribe-live-*).
echo         get-live-{ohlc,sma,ema}-{stocks,crypto}-{rest,java}
echo         subscribe-live-{ohlc,sma,ema}-{stocks,crypto}-java
echo.
echo   History
echo       Past-dated OHLC bars and derived analytics (top gainers). Fetch a date
echo       range, or stream it back (optionally many symbols concurrently).
echo         get-historical-ohlc-{stocks,crypto}-{rest,java}
echo         get-historical-top-gainers-{stocks,crypto}-{rest,java}
echo         stream-historical-ohlc-{stocks,crypto}-java
echo         stream-historical-ohlc-concurrently-{stocks,crypto}-java
echo.
echo   WebSocket streaming
echo       The same live trades / quotes / bars / indicators delivered over a
echo       WebSocket as untyped JSON. One endpoint per data type serves every
echo       dataset; pick the dataset with -d.
echo         subscribe-live-{trades,top-of-book,ohlc,sma,ema}-ws
echo         stream-historical-ohlc-ws
echo.
echo   Backtesting
echo       Build a historical tape and replay it through the live pipeline: download
echo       a day of data into the environment, then replay it. Each download and the
echo       replay expose start / is-running / cancel (stop) controls.
echo         start-{tick,trade,quote,ohlc}-download-{stocks,crypto}-{rest,java}
echo         is-{tick,trade,quote,ohlc}-download-running-{stocks,crypto}-{rest,java}
echo         cancel-{tick,trade,quote,ohlc}-download-{stocks,crypto}-{rest,java}
echo         start-tick-replay-{stocks,crypto}-{rest,java}
echo         is-tick-replay-running-{stocks,crypto}-{rest,java}
echo         stop-tick-replay-{stocks,crypto}-{rest,java}
echo.
echo Example:
echo   %~nx0 get-historical-ohlc-stocks-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
exit /b 0

:list
echo cancel-ohlc-download-crypto-java
echo cancel-ohlc-download-crypto-rest
echo cancel-ohlc-download-stocks-java
echo cancel-quote-download-crypto-java
echo cancel-quote-download-crypto-rest
echo cancel-quote-download-stocks-java
echo cancel-quote-download-stocks-rest
echo cancel-tick-download-crypto-java
echo cancel-tick-download-crypto-rest
echo cancel-tick-download-stocks-java
echo cancel-tick-download-stocks-rest
echo cancel-trade-download-crypto-java
echo cancel-trade-download-crypto-rest
echo cancel-trade-download-stocks-java
echo cancel-trade-download-stocks-rest
echo get-historical-ohlc-crypto-java
echo get-historical-ohlc-crypto-rest
echo get-historical-ohlc-stocks-java
echo get-historical-ohlc-stocks-rest
echo get-historical-top-gainers-crypto-java
echo get-historical-top-gainers-crypto-rest
echo get-historical-top-gainers-stocks-java
echo get-historical-top-gainers-stocks-rest
echo get-live-ema-crypto-java
echo get-live-ema-crypto-rest
echo get-live-ema-stocks-java
echo get-live-ema-stocks-rest
echo get-live-last-trade-crypto-java
echo get-live-last-trade-crypto-rest
echo get-live-last-trade-stocks-java
echo get-live-last-trade-stocks-rest
echo get-live-ohlc-crypto-java
echo get-live-ohlc-crypto-rest
echo get-live-ohlc-stocks-java
echo get-live-ohlc-stocks-rest
echo get-live-sma-crypto-java
echo get-live-sma-crypto-rest
echo get-live-sma-stocks-java
echo get-live-sma-stocks-rest
echo get-live-top-of-book-crypto-java
echo get-live-top-of-book-crypto-rest
echo get-live-top-of-book-stocks-java
echo get-live-top-of-book-stocks-rest
echo get-securities-crypto-java
echo get-securities-crypto-rest
echo get-securities-stocks-java
echo get-securities-stocks-rest
echo is-ohlc-download-running-crypto-java
echo is-ohlc-download-running-crypto-rest
echo is-ohlc-download-running-stocks-java
echo is-quote-download-running-crypto-java
echo is-quote-download-running-crypto-rest
echo is-quote-download-running-stocks-java
echo is-quote-download-running-stocks-rest
echo is-tick-download-running-crypto-java
echo is-tick-download-running-crypto-rest
echo is-tick-download-running-stocks-java
echo is-tick-download-running-stocks-rest
echo is-tick-replay-running-crypto-java
echo is-tick-replay-running-crypto-rest
echo is-tick-replay-running-stocks-java
echo is-tick-replay-running-stocks-rest
echo is-trade-download-running-crypto-java
echo is-trade-download-running-crypto-rest
echo is-trade-download-running-stocks-java
echo is-trade-download-running-stocks-rest
echo ping-rest
echo start-ohlc-download-crypto-java
echo start-ohlc-download-crypto-rest
echo start-ohlc-download-stocks-java
echo start-quote-download-crypto-java
echo start-quote-download-crypto-rest
echo start-quote-download-stocks-java
echo start-quote-download-stocks-rest
echo start-tick-download-crypto-java
echo start-tick-download-crypto-rest
echo start-tick-download-stocks-java
echo start-tick-download-stocks-rest
echo start-tick-replay-crypto-java
echo start-tick-replay-crypto-rest
echo start-tick-replay-stocks-java
echo start-tick-replay-stocks-rest
echo start-trade-download-crypto-java
echo start-trade-download-crypto-rest
echo start-trade-download-stocks-java
echo start-trade-download-stocks-rest
echo stop-tick-replay-crypto-java
echo stop-tick-replay-crypto-rest
echo stop-tick-replay-stocks-java
echo stop-tick-replay-stocks-rest
echo stream-historical-ohlc-concurrently-crypto-java
echo stream-historical-ohlc-concurrently-stocks-java
echo stream-historical-ohlc-crypto-java
echo stream-historical-ohlc-stocks-java
echo stream-historical-ohlc-ws
echo subscribe-live-ema-crypto-java
echo subscribe-live-ema-stocks-java
echo subscribe-live-ema-ws
echo subscribe-live-ohlc-crypto-java
echo subscribe-live-ohlc-stocks-java
echo subscribe-live-ohlc-ws
echo subscribe-live-sma-crypto-java
echo subscribe-live-sma-stocks-java
echo subscribe-live-sma-ws
echo subscribe-live-top-of-book-stocks-java
echo subscribe-live-top-of-book-ws
echo subscribe-live-trades-stocks-java
echo subscribe-live-trades-ws
exit /b 0
