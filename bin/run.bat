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

if "%SAMPLE_NAME%"=="ping-reference-rest" set CLASS=com.datafye.samples.rest.health.PingReference
if "%SAMPLE_NAME%"=="ping-live-feed-rest" set CLASS=com.datafye.samples.rest.health.PingLiveFeed
if "%SAMPLE_NAME%"=="ping-live-aggregates-rest" set CLASS=com.datafye.samples.rest.health.PingLiveAggregates
if "%SAMPLE_NAME%"=="ping-history-rest" set CLASS=com.datafye.samples.rest.health.PingHistory
if "%SAMPLE_NAME%"=="get-securities-rest" set CLASS=com.datafye.samples.rest.reference.GetSecurities
if "%SAMPLE_NAME%"=="get-securities-java" set CLASS=com.datafye.samples.java.reference.GetSecurities
if "%SAMPLE_NAME%"=="get-live-top-of-book-rest" set CLASS=com.datafye.samples.rest.live.ticks.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-top-of-book-java" set CLASS=com.datafye.samples.java.live.ticks.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-last-trade-rest" set CLASS=com.datafye.samples.rest.live.ticks.GetLiveLastTrade
if "%SAMPLE_NAME%"=="get-live-last-trade-java" set CLASS=com.datafye.samples.java.live.ticks.GetLiveLastTrade
if "%SAMPLE_NAME%"=="subscribe-live-top-of-book-java" set CLASS=com.datafye.samples.java.live.ticks.SubscribeLiveTopOfBook
if "%SAMPLE_NAME%"=="subscribe-live-trades-java" set CLASS=com.datafye.samples.java.live.ticks.SubscribeLiveTrades
if "%SAMPLE_NAME%"=="get-live-ohlc-rest" set CLASS=com.datafye.samples.rest.live.aggregates.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-ohlc-java" set CLASS=com.datafye.samples.java.live.aggregates.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-sma-rest" set CLASS=com.datafye.samples.rest.live.aggregates.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-sma-java" set CLASS=com.datafye.samples.java.live.aggregates.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-ema-rest" set CLASS=com.datafye.samples.rest.live.aggregates.GetLiveEMA
if "%SAMPLE_NAME%"=="get-live-ema-java" set CLASS=com.datafye.samples.java.live.aggregates.GetLiveEMA
if "%SAMPLE_NAME%"=="get-historical-ohlc-rest" set CLASS=com.datafye.samples.rest.history.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-historical-ohlc-java" set CLASS=com.datafye.samples.java.history.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-historical-top-gainers-rest" set CLASS=com.datafye.samples.rest.history.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="get-historical-top-gainers-java" set CLASS=com.datafye.samples.java.history.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="stream-historical-ohlc-java" set CLASS=com.datafye.samples.java.history.StreamHistoricalOHLC
if "%SAMPLE_NAME%"=="stream-historical-ohlc-concurrently-java" set CLASS=com.datafye.samples.java.history.StreamHistoricalOHLCConcurrently
if "%SAMPLE_NAME%"=="download-tick-history-rest" set CLASS=com.datafye.samples.rest.backtest.DownloadTickHistory
if "%SAMPLE_NAME%"=="download-tick-history-java" set CLASS=com.datafye.samples.java.backtest.DownloadTickHistory
if "%SAMPLE_NAME%"=="is-tick-download-running-rest" set CLASS=com.datafye.samples.rest.backtest.IsTickDownloadRunning
if "%SAMPLE_NAME%"=="is-tick-download-running-java" set CLASS=com.datafye.samples.java.backtest.IsTickDownloadRunning
if "%SAMPLE_NAME%"=="cancel-tick-download-rest" set CLASS=com.datafye.samples.rest.backtest.CancelTickDownload
if "%SAMPLE_NAME%"=="cancel-tick-download-java" set CLASS=com.datafye.samples.java.backtest.CancelTickDownload
if "%SAMPLE_NAME%"=="download-trade-history-rest" set CLASS=com.datafye.samples.rest.backtest.DownloadTradeHistory
if "%SAMPLE_NAME%"=="download-trade-history-java" set CLASS=com.datafye.samples.java.backtest.DownloadTradeHistory
if "%SAMPLE_NAME%"=="is-trade-download-running-rest" set CLASS=com.datafye.samples.rest.backtest.IsTradeDownloadRunning
if "%SAMPLE_NAME%"=="is-trade-download-running-java" set CLASS=com.datafye.samples.java.backtest.IsTradeDownloadRunning
if "%SAMPLE_NAME%"=="cancel-trade-download-rest" set CLASS=com.datafye.samples.rest.backtest.CancelTradeDownload
if "%SAMPLE_NAME%"=="cancel-trade-download-java" set CLASS=com.datafye.samples.java.backtest.CancelTradeDownload
if "%SAMPLE_NAME%"=="download-quote-history-rest" set CLASS=com.datafye.samples.rest.backtest.DownloadQuoteHistory
if "%SAMPLE_NAME%"=="download-quote-history-java" set CLASS=com.datafye.samples.java.backtest.DownloadQuoteHistory
if "%SAMPLE_NAME%"=="is-quote-download-running-rest" set CLASS=com.datafye.samples.rest.backtest.IsQuoteDownloadRunning
if "%SAMPLE_NAME%"=="is-quote-download-running-java" set CLASS=com.datafye.samples.java.backtest.IsQuoteDownloadRunning
if "%SAMPLE_NAME%"=="cancel-quote-download-rest" set CLASS=com.datafye.samples.rest.backtest.CancelQuoteDownload
if "%SAMPLE_NAME%"=="cancel-quote-download-java" set CLASS=com.datafye.samples.java.backtest.CancelQuoteDownload
if "%SAMPLE_NAME%"=="download-ohlc-history-java" set CLASS=com.datafye.samples.java.backtest.DownloadOHLCHistory
if "%SAMPLE_NAME%"=="is-ohlc-download-running-java" set CLASS=com.datafye.samples.java.backtest.IsOHLCDownloadRunning
if "%SAMPLE_NAME%"=="cancel-ohlc-download-java" set CLASS=com.datafye.samples.java.backtest.CancelOHLCDownload
if "%SAMPLE_NAME%"=="replay-ticks-rest" set CLASS=com.datafye.samples.rest.backtest.ReplayTicks
if "%SAMPLE_NAME%"=="replay-ticks-java" set CLASS=com.datafye.samples.java.backtest.ReplayTicks
if "%SAMPLE_NAME%"=="is-tick-replay-running-rest" set CLASS=com.datafye.samples.rest.backtest.IsTickReplayRunning
if "%SAMPLE_NAME%"=="is-tick-replay-running-java" set CLASS=com.datafye.samples.java.backtest.IsTickReplayRunning
if "%SAMPLE_NAME%"=="stop-tick-replay-rest" set CLASS=com.datafye.samples.rest.backtest.StopTickReplay
if "%SAMPLE_NAME%"=="stop-tick-replay-java" set CLASS=com.datafye.samples.java.backtest.StopTickReplay

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
echo     ping-reference-rest                    Ping reference subsystem
echo     ping-live-feed-rest                    Ping live feed subsystem
echo     ping-live-aggregates-rest              Ping live aggregates subsystem
echo     ping-history-rest                      Ping history subsystem
echo.
echo   Reference:
echo     get-securities-rest                    Fetch securities reference data
echo     get-securities-java                    Fetch securities reference data
echo.
echo   Live - Ticks:
echo     get-live-top-of-book-rest              Fetch live top-of-book quotes
echo     get-live-top-of-book-java              Fetch live top-of-book quotes
echo     get-live-last-trade-rest               Fetch last trade for symbols
echo     get-live-last-trade-java               Fetch last trade for symbols
echo     subscribe-live-top-of-book-java        Subscribe to live top-of-book quotes
echo     subscribe-live-trades-java             Subscribe to live trades
echo.
echo   Live - Aggregates:
echo     get-live-ohlc-rest                     Fetch current trading day OHLC bars
echo     get-live-ohlc-java                     Fetch current trading day OHLC bars
echo     get-live-sma-rest                      Fetch live SMA values
echo     get-live-sma-java                      Fetch live SMA values
echo     get-live-ema-rest                      Fetch live EMA values
echo     get-live-ema-java                      Fetch live EMA values
echo.
echo   History:
echo     get-historical-ohlc-rest               Fetch historical OHLC bars
echo     get-historical-ohlc-java               Fetch historical OHLC bars
echo     get-historical-top-gainers-rest         Fetch historical top gainers
echo     get-historical-top-gainers-java         Fetch historical top gainers
echo     stream-historical-ohlc-java            Stream historical OHLC bars
echo     stream-historical-ohlc-concurrently-java
echo                                            Stream historical OHLC bars concurrently
echo.
echo   Backtesting (REST):
echo     download-tick-history-rest              Download tick history
echo     is-tick-download-running-rest           Check if tick download is running
echo     cancel-tick-download-rest               Cancel tick history download
echo     download-trade-history-rest             Download trade history
echo     is-trade-download-running-rest          Check if trade download is running
echo     cancel-trade-download-rest              Cancel trade history download
echo     download-quote-history-rest             Download quote history
echo     is-quote-download-running-rest          Check if quote download is running
echo     cancel-quote-download-rest              Cancel quote history download
echo     replay-ticks-rest                       Replay historical ticks
echo     is-tick-replay-running-rest             Check if tick replay is running
echo     stop-tick-replay-rest                   Stop tick replay
echo.
echo   Backtesting (Java Client):
echo     download-tick-history-java              Download tick history
echo     is-tick-download-running-java           Check if tick download is running
echo     cancel-tick-download-java               Cancel tick history download
echo     download-trade-history-java             Download trade history
echo     is-trade-download-running-java          Check if trade download is running
echo     cancel-trade-download-java              Cancel trade history download
echo     download-quote-history-java             Download quote history
echo     is-quote-download-running-java          Check if quote download is running
echo     cancel-quote-download-java              Cancel quote history download
echo     download-ohlc-history-java              Download OHLC history
echo     is-ohlc-download-running-java           Check if OHLC download is running
echo     cancel-ohlc-download-java               Cancel OHLC history download
echo     replay-ticks-java                       Replay historical ticks
echo     is-tick-replay-running-java             Check if tick replay is running
echo     stop-tick-replay-java                   Stop tick replay
echo.
echo Example:
echo   %~nx0 get-historical-ohlc-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
exit /b 0

:list
echo cancel-ohlc-download-java
echo cancel-quote-download-java
echo cancel-quote-download-rest
echo cancel-tick-download-java
echo cancel-tick-download-rest
echo cancel-trade-download-java
echo cancel-trade-download-rest
echo download-ohlc-history-java
echo download-quote-history-java
echo download-quote-history-rest
echo download-tick-history-java
echo download-tick-history-rest
echo download-trade-history-java
echo download-trade-history-rest
echo get-historical-ohlc-java
echo get-historical-ohlc-rest
echo get-historical-top-gainers-java
echo get-historical-top-gainers-rest
echo get-live-ema-java
echo get-live-ema-rest
echo get-live-last-trade-java
echo get-live-last-trade-rest
echo get-live-ohlc-java
echo get-live-ohlc-rest
echo get-live-sma-java
echo get-live-sma-rest
echo get-live-top-of-book-java
echo get-live-top-of-book-rest
echo get-securities-java
echo get-securities-rest
echo is-ohlc-download-running-java
echo is-quote-download-running-java
echo is-quote-download-running-rest
echo is-tick-download-running-java
echo is-tick-download-running-rest
echo is-tick-replay-running-java
echo is-tick-replay-running-rest
echo is-trade-download-running-java
echo is-trade-download-running-rest
echo ping-history-rest
echo ping-live-aggregates-rest
echo ping-live-feed-rest
echo ping-reference-rest
echo replay-ticks-java
echo replay-ticks-rest
echo stop-tick-replay-java
echo stop-tick-replay-rest
echo stream-historical-ohlc-concurrently-java
echo stream-historical-ohlc-java
echo subscribe-live-top-of-book-java
echo subscribe-live-trades-java
exit /b 0
