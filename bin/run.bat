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

if "%SAMPLE_NAME%"=="get-historical-ohlc-rest" set CLASS=com.datafye.samples.rest.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-live-ohlc-rest" set CLASS=com.datafye.samples.rest.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-top-of-book-rest" set CLASS=com.datafye.samples.rest.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-ohlc-concurrently-rest" set CLASS=com.datafye.samples.rest.GetLiveOHLCConcurrently
if "%SAMPLE_NAME%"=="get-historical-ohlc-java" set CLASS=com.datafye.samples.java.GetHistoricalOHLC
if "%SAMPLE_NAME%"=="get-live-ohlc-java" set CLASS=com.datafye.samples.java.GetLiveOHLC
if "%SAMPLE_NAME%"=="get-live-top-of-book-java" set CLASS=com.datafye.samples.java.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="stream-historical-ohlc-java" set CLASS=com.datafye.samples.java.StreamHistoricalOHLC
if "%SAMPLE_NAME%"=="stream-historical-ohlc-concurrently-java" set CLASS=com.datafye.samples.java.StreamHistoricalOHLCConcurrently
if "%SAMPLE_NAME%"=="subscribe-live-top-of-book-java" set CLASS=com.datafye.samples.java.SubscribeLiveTopOfBook
if "%SAMPLE_NAME%"=="subscribe-live-trades-java" set CLASS=com.datafye.samples.java.SubscribeLiveTrades
if "%SAMPLE_NAME%"=="get-historical-top-gainers-rest" set CLASS=com.datafye.samples.rest.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="get-historical-top-gainers-java" set CLASS=com.datafye.samples.java.GetHistoricalTopGainers
if "%SAMPLE_NAME%"=="get-live-last-trade-rest" set CLASS=com.datafye.samples.rest.GetLiveLastTrade
if "%SAMPLE_NAME%"=="get-live-last-trade-java" set CLASS=com.datafye.samples.java.GetLiveLastTrade
if "%SAMPLE_NAME%"=="get-live-sma-rest" set CLASS=com.datafye.samples.rest.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-sma-java" set CLASS=com.datafye.samples.java.GetLiveSMA
if "%SAMPLE_NAME%"=="get-live-ema-rest" set CLASS=com.datafye.samples.rest.GetLiveEMA
if "%SAMPLE_NAME%"=="get-live-ema-java" set CLASS=com.datafye.samples.java.GetLiveEMA

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
echo   REST API:
echo     get-historical-ohlc-rest             Fetch historical OHLC bars
echo     get-historical-top-gainers-rest       Fetch historical top gainers
echo     get-live-ohlc-rest                   Fetch current trading day OHLC bars
echo     get-live-ohlc-concurrently-rest       Fetch live OHLC bars concurrently
echo     get-live-top-of-book-rest             Fetch live top-of-book quotes
echo     get-live-last-trade-rest                   Fetch last trade for symbols
echo     get-live-sma-rest                     Fetch live SMA values
echo     get-live-ema-rest                     Fetch live EMA values
echo.
echo   Java Client:
echo     get-historical-ohlc-java             Fetch historical OHLC bars
echo     get-historical-top-gainers-java       Fetch historical top gainers
echo     get-live-ohlc-java                   Fetch current trading day OHLC bars
echo     get-live-top-of-book-java             Fetch live top-of-book quotes
echo     get-live-last-trade-java                   Fetch last trade for symbols
echo     get-live-sma-java                     Fetch live SMA values
echo     get-live-ema-java                     Fetch live EMA values
echo     stream-historical-ohlc-java              Stream historical OHLC bars
echo     stream-historical-ohlc-concurrently-java
echo                                                Stream historical OHLC bars concurrently
echo     subscribe-live-top-of-book-java            Subscribe to live top-of-book quotes
echo     subscribe-live-trades-java                 Subscribe to live trades
echo.
echo Example:
echo   %~nx0 get-historical-ohlc-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
exit /b 0

:list
echo get-historical-ohlc-java
echo get-historical-ohlc-rest
echo get-historical-top-gainers-java
echo get-historical-top-gainers-rest
echo get-live-last-trade-java
echo get-live-last-trade-rest
echo get-live-ema-java
echo get-live-ema-rest
echo get-live-ohlc-concurrently-rest
echo get-live-ohlc-java
echo get-live-ohlc-rest
echo get-live-sma-java
echo get-live-sma-rest
echo get-live-top-of-book-java
echo get-live-top-of-book-rest
echo stream-historical-ohlc-concurrently-java
echo stream-historical-ohlc-java
echo subscribe-live-top-of-book-java
echo subscribe-live-trades-java
exit /b 0
