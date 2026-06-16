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
echo Available samples:
echo.
echo   Health:
echo     ping-rest                              Ping deployment health
echo.
echo   Reference:
echo     get-securities-stocks-rest                    Fetch securities reference data
echo     get-securities-stocks-java                    Fetch securities reference data
echo     get-securities-crypto-rest             Fetch securities reference data (crypto)
echo     get-securities-crypto-java             Fetch securities reference data (crypto)
echo.
echo   Live - Ticks:
echo     get-live-top-of-book-stocks-rest              Fetch live top-of-book quotes
echo     get-live-top-of-book-stocks-java              Fetch live top-of-book quotes
echo     get-live-top-of-book-crypto-rest       Fetch live top-of-book quotes (crypto)
echo     get-live-top-of-book-crypto-java       Fetch live top-of-book quotes (crypto)
echo     get-live-last-trade-stocks-rest               Fetch last trade for symbols
echo     get-live-last-trade-stocks-java               Fetch last trade for symbols
echo     get-live-last-trade-crypto-rest        Fetch last trade for symbols (crypto)
echo     get-live-last-trade-crypto-java        Fetch last trade for symbols (crypto)
echo     subscribe-live-top-of-book-stocks-java        Subscribe to live top-of-book quotes
echo     subscribe-live-trades-stocks-java             Subscribe to live trades
echo.
echo   Live - Aggregates:
echo     get-live-ohlc-stocks-rest                     Fetch current trading day OHLC bars
echo     get-live-ohlc-stocks-java                     Fetch current trading day OHLC bars
echo     get-live-ohlc-crypto-rest              Fetch current trading day OHLC bars (crypto)
echo     get-live-ohlc-crypto-java              Fetch current trading day OHLC bars (crypto)
echo     get-live-sma-stocks-rest                      Fetch live SMA values
echo     get-live-sma-stocks-java                      Fetch live SMA values
echo     get-live-sma-crypto-rest               Fetch live SMA values (crypto)
echo     get-live-sma-crypto-java               Fetch live SMA values (crypto)
echo     get-live-ema-stocks-rest                      Fetch live EMA values
echo     get-live-ema-stocks-java                      Fetch live EMA values
echo     get-live-ema-crypto-rest               Fetch live EMA values (crypto)
echo     get-live-ema-crypto-java               Fetch live EMA values (crypto)
echo     subscribe-live-ohlc-stocks-java               Subscribe to live OHLC bars
echo     subscribe-live-ohlc-crypto-java        Subscribe to live OHLC bars (crypto)
echo     subscribe-live-sma-stocks-java                Subscribe to live SMA values
echo     subscribe-live-sma-crypto-java         Subscribe to live SMA values (crypto)
echo     subscribe-live-ema-stocks-java                Subscribe to live EMA values
echo     subscribe-live-ema-crypto-java         Subscribe to live EMA values (crypto)
echo.
echo   History:
echo     get-historical-ohlc-stocks-rest               Fetch historical OHLC bars
echo     get-historical-ohlc-stocks-java               Fetch historical OHLC bars
echo     get-historical-ohlc-crypto-rest        Fetch historical OHLC bars (crypto)
echo     get-historical-ohlc-crypto-java        Fetch historical OHLC bars (crypto)
echo     get-historical-top-gainers-stocks-rest         Fetch historical top gainers
echo     get-historical-top-gainers-stocks-java         Fetch historical top gainers
echo     get-historical-top-gainers-crypto-rest  Fetch historical top gainers (crypto)
echo     get-historical-top-gainers-crypto-java  Fetch historical top gainers (crypto)
echo     stream-historical-ohlc-stocks-java            Stream historical OHLC bars
echo     stream-historical-ohlc-crypto-java     Stream historical OHLC bars (crypto)
echo     stream-historical-ohlc-concurrently-stocks-java
echo                                            Stream historical OHLC bars concurrently
echo     stream-historical-ohlc-concurrently-crypto-java
echo                                            Stream historical OHLC bars concurrently (crypto)
echo.
echo   WebSocket Streaming:
echo     subscribe-live-trades-ws               Stream live trades over a WebSocket
echo     subscribe-live-top-of-book-ws          Stream live top-of-book quotes over a WebSocket
echo     subscribe-live-ohlc-ws                 Stream live OHLC bars over a WebSocket
echo     subscribe-live-sma-ws                  Stream live SMA values over a WebSocket
echo     subscribe-live-ema-ws                  Stream live EMA values over a WebSocket
echo     stream-historical-ohlc-ws              Stream a historical OHLC range over a WebSocket
echo.
echo   Backtesting (REST):
echo     start-tick-download-stocks-rest                Start tick history download
echo     is-tick-download-running-stocks-rest           Check if tick download is running
echo     cancel-tick-download-stocks-rest               Cancel tick history download
echo     start-trade-download-stocks-rest               Start trade history download
echo     is-trade-download-running-stocks-rest          Check if trade download is running
echo     cancel-trade-download-stocks-rest              Cancel trade history download
echo     start-quote-download-stocks-rest               Start quote history download
echo     is-quote-download-running-stocks-rest          Check if quote download is running
echo     cancel-quote-download-stocks-rest              Cancel quote history download
echo     start-tick-replay-stocks-rest                  Start tick replay
echo     is-tick-replay-running-stocks-rest             Check if tick replay is running
echo     stop-tick-replay-stocks-rest                   Stop tick replay
echo.
echo   Backtesting (REST, Crypto):
echo     start-tick-download-crypto-rest         Start tick history download (crypto)
echo     is-tick-download-running-crypto-rest    Check if tick download is running (crypto)
echo     cancel-tick-download-crypto-rest        Cancel tick history download (crypto)
echo     start-trade-download-crypto-rest        Start trade history download (crypto)
echo     is-trade-download-running-crypto-rest   Check if trade download is running (crypto)
echo     cancel-trade-download-crypto-rest       Cancel trade history download (crypto)
echo     start-quote-download-crypto-rest        Start quote history download (crypto)
echo     is-quote-download-running-crypto-rest   Check if quote download is running (crypto)
echo     cancel-quote-download-crypto-rest       Cancel quote history download (crypto)
echo     start-ohlc-download-crypto-rest         Start OHLC history download (crypto)
echo     is-ohlc-download-running-crypto-rest    Check if OHLC download is running (crypto)
echo     cancel-ohlc-download-crypto-rest        Cancel OHLC history download (crypto)
echo     start-tick-replay-crypto-rest           Start tick replay (crypto)
echo     is-tick-replay-running-crypto-rest      Check if tick replay is running (crypto)
echo     stop-tick-replay-crypto-rest            Stop tick replay (crypto)
echo.
echo   Backtesting (Java Client):
echo     start-tick-download-stocks-java                Start tick history download
echo     is-tick-download-running-stocks-java           Check if tick download is running
echo     cancel-tick-download-stocks-java               Cancel tick history download
echo     start-trade-download-stocks-java               Start trade history download
echo     is-trade-download-running-stocks-java          Check if trade download is running
echo     cancel-trade-download-stocks-java              Cancel trade history download
echo     start-quote-download-stocks-java               Start quote history download
echo     is-quote-download-running-stocks-java          Check if quote download is running
echo     cancel-quote-download-stocks-java              Cancel quote history download
echo     start-ohlc-download-stocks-java                Start OHLC history download
echo     is-ohlc-download-running-stocks-java           Check if OHLC download is running
echo     cancel-ohlc-download-stocks-java               Cancel OHLC history download
echo     start-tick-replay-stocks-java                  Start tick replay
echo     is-tick-replay-running-stocks-java             Check if tick replay is running
echo     stop-tick-replay-stocks-java                   Stop tick replay
echo.
echo   Backtesting (Java Client, Crypto):
echo     start-tick-download-crypto-java         Start tick history download (crypto)
echo     is-tick-download-running-crypto-java    Check if tick download is running (crypto)
echo     cancel-tick-download-crypto-java        Cancel tick history download (crypto)
echo     start-trade-download-crypto-java        Start trade history download (crypto)
echo     is-trade-download-running-crypto-java   Check if trade download is running (crypto)
echo     cancel-trade-download-crypto-java       Cancel trade history download (crypto)
echo     start-quote-download-crypto-java        Start quote history download (crypto)
echo     is-quote-download-running-crypto-java   Check if quote download is running (crypto)
echo     cancel-quote-download-crypto-java       Cancel quote history download (crypto)
echo     start-ohlc-download-crypto-java         Start OHLC history download (crypto)
echo     is-ohlc-download-running-crypto-java    Check if OHLC download is running (crypto)
echo     cancel-ohlc-download-crypto-java        Cancel OHLC history download (crypto)
echo     start-tick-replay-crypto-java           Start tick replay (crypto)
echo     is-tick-replay-running-crypto-java      Check if tick replay is running (crypto)
echo     stop-tick-replay-crypto-java            Stop tick replay (crypto)
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
