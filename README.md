# Introduction
This repository contains sample code used to access the Datafye services in the Private Cloud deployed for GainBox

# What's in the Repo
The repository contains the following programs
| Name | Description| Program |
|---|---|---|
|Get Historical Candles | Sample code on how to fetch historical non-live (prior to current trading day) candles | com.datafye.gbpoc.client.GetHistoricalCandles |
|Get Live Candles | Sample code on how to fetch historical live (current trading day) candles | com.datafye.gbpoc.client.GetLiveCandles |
|Get Live Top-Of-Book | Sample code on how to fetch live (current trading day) top-of-book quotes | com.datafye.gbpoc.client.GetLiveTopOfBookQuotes |
|Stream Live Top-Of-Book | Sample code on how to stream live (current trading day) top-of-book quotes | com.datafye.gbpoc.client.StreamLiveTopOfBookQuotes |

# Prerequsites
## Maven
You will need Maven to build the code in this repo. Please download and install Maven v3.5.4 (the build has not been tested with later versions). 
> You can download Maven from [here](https://maven.apache.org/index.html)

## Java
You will need Java 11 or above (not later than Java 17) to build and run the code.

### Running with Java 11/17
To run the code in this repo using Java 11 and beyond, certain additional Java modules need to be opened. The following JVM params open the additional needed Java modules

```
--add-opens=java.base/jdk.internal.ref=ALL-UNNAMED --add-opens=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/java.io=ALL-UNNAMED --add-opens=java.management/sun.management=ALL-UNNAMED --illegal-access=warn
```

# Build
Execute the following from the root directory of the repository
```
mvn clean install
```
This will produce a `tar.gz` distribution named as `gb-poc-<version>-dist.tar.gz`. Unarchive the distribution in a directory of your choice

## rumi.conf
You will notice a configuration file, named `rumi.conf` in the `conf` folder. This contains config information, such as endpoint addresses for use by the REST and Java clients. 

# Run
## Get Historical Candles Sample Program
### REST Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.GetHistoricalCandles -s <symbol> -f <yyyy-MM-dd'T'HH:mm:ss> -t <yyyy-MM-dd'T'HH:mm:ss>`
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above

Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.HistoricalCandles -s AAPL -f 2014-11-17T09:00:00 -t 2014-11-17T18:00:00`

The above will use the Datafye OHLC REST client to fetch the _second_ frequency candles for the AAPL stock that were generated between 9am and 6pm on 2014-11-17. 

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbol: AAPL
...Use Java Client: no
...From: 2014-11-17T09:00:00
...To: 2014-11-17T18:00:00
}
Fetched '17650' candles for 'AAPL' in 30 milliseconds.
```

### Java Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.GetHistoricalCandles -s <symbol> -f <yyyy-MM-dd'T'HH:mm:ss> -t <yyyy-MM-dd'T'HH:mm:ss> -j`
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above
 
Note the -j option at the end of the above command. That is what toggles the client to use the Java client.

Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.HistoricalCandles -s AAPL -f 2014-11-17T09:00:00 -t 2014-11-17T18:00:00 -j`

The above will use the Datafye OHLC Java client to fetch the _second_ frequency candles for the AAPL stock that were generated between 9am and 6pm on 2014-11-17. 

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbol: AAPL
...Use Java Client: yes
...From: 2014-11-17T09:00:00
...To: 2014-11-17T18:00:00
}
Fetched '17650' candles for 'AAPL' in 118 milliseconds.
```

## Get Live Candles Sample Program
### REST Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.LiveCandles -s <symbol> `
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above

Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.GetLiveCandles -s AAPL`

The above will use the Datafye OHLC REST client to fetch the _minute_ frequency candles for the AAPL stock that were generated between the beginning of trading 
(including extended trading hours) and the current time on the current trading day

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbol: AAPL
...Use Java Client: no
}
Fetched '956' candles for 'AAPL' in 24 milliseconds.
```

### Java Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.GetLiveCandles -s <symbol> -j`
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above
 
Note the -j option at the end of the above command. That is what toggles the client to use the Java client.

Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.HistoricalCandles -s AAPL -j`

The above will use the Datafye OHLC REST client to fetch the _minute_ frequency candles for the AAPL stock that were generated between the beginning of trading 
(including extended trading hours) and the current time on the current trading day

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbol: AAPL
...Use Java Client: yes
}
Fetched '956' candles for 'AAPL' in 9 milliseconds.
```

## Get Live Top-Of-Book Quotes Sample Program
### REST Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.GetLiveTopOfBookQuotes -s <comma separated symbols> `
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above

Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.LiveTopOfBookQuotes -s AAPL,AMZN,GOOG,MSFT`

The above will use the Datafye Quote REST client to fetch the latest top-of-book quote for AAPL, AMZN, GOOG and MSFT

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbols: AAPL,AMZN,GOOG,MSFT
...Use Java Client: no
}
Fetched '4' quotes for [AAPL,AMZN,GOOG,MSFT] in 9 milliseconds.
```

### Java Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.GetLiveTopOfBookQuotes -s <comma separated symbols> -j`
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above
 
Note the -j option at the end of the above command. That is what toggles the client to use the Java client.

Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.LiveTopOfBookQuotes -s AAPL,AMZN,GOOG,MSFT -j`

The above will use the Datafye Quote Java client to fetch the latest top-of-book quote for AAPL, AMZN, GOOG and MSFT

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbol: AAPL,AMZN,GOOG,MSFT
...Use Java Client: yes
}
Fetched '4' quotes for [AAPL,AMZN,GOOG,MSFT] in 9 milliseconds.
```

## Stream Live Top-Of-Book Quotes Sample Program
### REST Client
```
Not available
```

### Java Client
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.StreamLiveTopOfBookQuotes -s <comma separated symbols>`
> The `JAVA_11_OPTS` in the above command refers to the JVM options in the `Running with Java 11/17` section above
 
Example:
`$JAVA_HOME/bin/java $JAVA_11_OPTS -cp "libs/*" com.datafye.gbpoc.client.StreamLiveTopOfBookQuotes -s TSLA,IBM,NFLX,AMZN,GOOG,GOOGL,AAPL

The above will use the Datafye Quote Java client to stream the latest top-of-book quote for AAPL, AMZN, GOOG, TSLA and others listed in the anove command line

A successful run of the above should produce an output as follows:

```
Parameters {
...Symbols: TSLA,IBM,NFLX,AMZN,GOOG,GOOGL,AAPL
}
<-- LiveTopOfBookQuoteDataMessage {SIP,GOOGL,1705491686065,0,12,141.81,100,11,141.9,200}
<-- LiveTopOfBookQuoteDataMessage {SIP,AAPL,1705491686098,0,11,182.01,100,12,182.14,400}
<-- LiveTopOfBookQuoteDataMessage {SIP,AMZN,1705491686625,0,11,152.15,100,11,152.31,100}
<-- LiveTopOfBookQuoteDataMessage {SIP,AMZN,1705491687855,0,11,152.15,100,12,152.36,200}
<-- LiveTopOfBookQuoteDataMessage {SIP,AMZN,1705491688160,0,11,152.15,100,11,152.31,100}
```

