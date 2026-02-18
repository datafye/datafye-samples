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

if "%SAMPLE_NAME%"=="get-historical-candles-rest" set CLASS=com.datafye.samples.rest.GetHistoricalCandles
if "%SAMPLE_NAME%"=="get-live-candles-rest" set CLASS=com.datafye.samples.rest.GetLiveCandles
if "%SAMPLE_NAME%"=="get-live-top-of-book-rest" set CLASS=com.datafye.samples.rest.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="get-live-candles-concurrently-rest" set CLASS=com.datafye.samples.rest.GetLiveCandlesConcurrently
if "%SAMPLE_NAME%"=="get-historical-candles-java" set CLASS=com.datafye.samples.java.GetHistoricalCandles
if "%SAMPLE_NAME%"=="get-live-candles-java" set CLASS=com.datafye.samples.java.GetLiveCandles
if "%SAMPLE_NAME%"=="get-live-top-of-book-java" set CLASS=com.datafye.samples.java.GetLiveTopOfBook
if "%SAMPLE_NAME%"=="stream-historical-candles-java" set CLASS=com.datafye.samples.java.StreamHistoricalCandles
if "%SAMPLE_NAME%"=="stream-historical-candles-concurrently-java" set CLASS=com.datafye.samples.java.StreamHistoricalCandlesConcurrently
if "%SAMPLE_NAME%"=="stream-live-top-of-book-java" set CLASS=com.datafye.samples.java.StreamLiveTopOfBook
if "%SAMPLE_NAME%"=="stream-live-trades-java" set CLASS=com.datafye.samples.java.StreamLiveTrades

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
echo     get-historical-candles-rest        Fetch historical OHLC candles
echo     get-live-candles-rest              Fetch current trading day candles
echo     get-live-top-of-book-rest          Fetch live top-of-book quotes
echo     get-live-candles-concurrently-rest Fetch live candles concurrently
echo.
echo   Java Client:
echo     get-historical-candles-java        Fetch historical OHLC candles
echo     get-live-candles-java              Fetch current trading day candles
echo     get-live-top-of-book-java          Fetch live top-of-book quotes
echo     stream-historical-candles-java     Stream historical candles
echo     stream-historical-candles-concurrently-java
echo                                        Stream historical candles concurrently
echo     stream-live-top-of-book-java       Stream live top-of-book quotes
echo     stream-live-trades-java            Stream live trades
echo.
echo Example:
echo   %~nx0 get-historical-candles-rest -s AAPL -f 2024-01-15T09:00:00 -t 2024-01-15T18:00:00
exit /b 0

:list
echo get-historical-candles-java
echo get-historical-candles-rest
echo get-live-candles-concurrently-rest
echo get-live-candles-java
echo get-live-candles-rest
echo get-live-top-of-book-java
echo get-live-top-of-book-rest
echo stream-historical-candles-concurrently-java
echo stream-historical-candles-java
echo stream-live-top-of-book-java
echo stream-live-trades-java
exit /b 0
