/**
 * Copyright 2022 N5 Technologies, Inc
 *
 * This product includes software developed at N5 Technologies, Inc
 * (http://www.n5corp.com/) as well as software licenced to N5 Technologies,
 * Inc under one or more contributor license agreements. See the NOTICE
 * file distributed with this work for additional information regarding
 * copyright ownership.
 *
 * N5 Technologies licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at:
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.datafye.samples.java;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import jargs.gnu.CmdLineParser;

import com.datafye.roe.*;
import com.datafye.client.synthetic.HistoryClient;

public class GetHistoricalCandles {
    static {
        System.setProperty("datafye-synthetic-history.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-synthetic-history");
    }

    final private static void printUsage() {
        System.err.println("    [{-s, --symbol the symbol to fetch the candles for (required)]");
        System.err.println("    [{-c, --frequency the candle frequency to fetch for]");
        System.err.println("    [{-f, --from the lower bound of the time window to fetch candles for (format=YYYY-MM-DDTHH:mm:ss)]");
        System.err.println("    [{-t, --to the upper bound of the time window to fetch candles for (format=YYYY-MM-DDTHH:mm:ss))]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private static void run(final String symbol, final String frequency, final Date from, final Date to) {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0");

        // perform 100 fetches
        long totalTime = 0;
        long totalCount = 0;
        for (int i = 0 ; i < 100 ; i++) {
            // run and benchmark
            long start = System.currentTimeMillis();
            GetHistoricalStocksOHLCsRequestMessage request = GetHistoricalStocksOHLCsRequestMessage.create();
            request.setFrequency(OHLCFrequency.valueOf(frequency));
            request.setSymbol(symbol);
            request.setFromAsTimestamp(from.getTime());
            request.setToAsTimestamp(to.getTime());
            GetHistoricalStocksOHLCsResponseMessage response = client.getHistoricalOHLCs(request);
            final int candlesCount = response.getCandlesCount();
            long stop = System.currentTimeMillis();

            // update totals
            totalTime += (stop-start);
            totalCount += candlesCount;

            // dispose the response
            response.dispose();
        }

        // average time
        System.out.println("Fetched '" + (totalCount/100) + "' candles for '" + symbol + "' in " + (totalTime/100) + " milliseconds.");

        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolOption = parser.addStringOption('s', "symbol");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option fromOption = parser.addStringOption('f', "from");
        final CmdLineParser.Option toOption = parser.addStringOption('t', "to");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbol
            final String symbol = (String)parser.getOptionValue(symbolOption, null);
            if (symbol == null) printUsage();
            // ...frequency
            final String frequency = (String)parser.getOptionValue(frequencyOption, "Minute");
            // ...from
            final String fromStr = (String)parser.getOptionValue(fromOption, null);
            if (fromStr == null) printUsage();
            final SimpleDateFormat fromDateFormat = dateFormat();
            Date from = null;
            if (fromStr != null) {
                try {
                    from = fromDateFormat.parse(fromStr);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    printUsage();
                }
            }
            // ...to
            final String toStr = (String)parser.getOptionValue(toOption, null);
            if (toStr == null) printUsage();
            final SimpleDateFormat toDateFormat = dateFormat();
            Date to = null;
            if (toStr != null) {
                try {
                    to = toDateFormat.parse(toStr);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    printUsage();
                }
            }

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Symbol: " + symbol);
            System.out.println("...Frequency: " + frequency);
            System.out.println("...From: " + fromStr);
            System.out.println("...To: " + toStr);
            System.out.println("}");

            // execute
            run(symbol, frequency, from, to);
        }
        else {
            printUsage();
        }
    }
}
