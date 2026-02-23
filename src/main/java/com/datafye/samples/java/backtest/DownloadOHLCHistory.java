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
package com.datafye.samples.java.backtest;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import jargs.gnu.CmdLineParser;

import com.datafye.roe.*;
import com.datafye.client.sip.HistoryClient;

public class DownloadOHLCHistory {
    static {
        System.setProperty("datafye-sip-history.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-sip-history");
    }

    final private static void printUsage() {
        System.err.println("    [{-d, --date the date to download OHLC history for (format=YYYY-MM-DD) (required)]");
        System.err.println("    [{-s, --symbols the symbols (comma separated) to download OHLC history for (optional)]");
        System.err.println("    [{-c, --frequency the OHLC frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-w, --wait wait for download to complete]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private static String startDownload(final HistoryClient client, final String frequency, final Date date, final String[] symbols) {
        if ("Second".equals(frequency)) {
            StartStocksSecondOHLCHistoryFetchRequestMessage request = StartStocksSecondOHLCHistoryFetchRequestMessage.create();
            request.serializer().startDate(date.getTime()).numDays(1).symbols(symbols).adjusted(false).done();
            StartStocksSecondOHLCHistoryFetchResponseMessage response = client.startSecondOHLCHistoryFetch(request);
            String status = response.getStatus();
            response.dispose();
            return status;
        }
        else if ("Hour".equals(frequency)) {
            StartStocksHourOHLCHistoryFetchRequestMessage request = StartStocksHourOHLCHistoryFetchRequestMessage.create();
            request.serializer().startDate(date.getTime()).numDays(1).symbols(symbols).adjusted(false).done();
            StartStocksHourOHLCHistoryFetchResponseMessage response = client.startHourOHLCHistoryFetch(request);
            String status = response.getStatus();
            response.dispose();
            return status;
        }
        else if ("Day".equals(frequency)) {
            StartStocksDayOHLCHistoryFetchRequestMessage request = StartStocksDayOHLCHistoryFetchRequestMessage.create();
            request.serializer().startDate(date.getTime()).numDays(1).symbols(symbols).adjusted(false).done();
            StartStocksDayOHLCHistoryFetchResponseMessage response = client.startDayOHLCHistoryFetch(request);
            String status = response.getStatus();
            response.dispose();
            return status;
        }
        else {
            // default: Minute
            StartStocksMinuteOHLCHistoryFetchRequestMessage request = StartStocksMinuteOHLCHistoryFetchRequestMessage.create();
            request.serializer().startDate(date.getTime()).numDays(1).symbols(symbols).adjusted(false).done();
            StartStocksMinuteOHLCHistoryFetchResponseMessage response = client.startMinuteOHLCHistoryFetch(request);
            String status = response.getStatus();
            response.dispose();
            return status;
        }
    }

    final private static boolean isDownloadRunning(final HistoryClient client, final String frequency) {
        if ("Second".equals(frequency)) {
            IsStocksSecondOHLCHistoryFetchRunningRequestMessage request = IsStocksSecondOHLCHistoryFetchRunningRequestMessage.create();
            IsStocksSecondOHLCHistoryFetchRunningResponseMessage response = client.isSecondOHLCHistoryFetchRunning(request);
            boolean isRunning = response.getIsRunning();
            response.dispose();
            return isRunning;
        }
        else if ("Hour".equals(frequency)) {
            IsStocksHourOHLCHistoryFetchRunningRequestMessage request = IsStocksHourOHLCHistoryFetchRunningRequestMessage.create();
            IsStocksHourOHLCHistoryFetchRunningResponseMessage response = client.isHourOHLCHistoryFetchRunning(request);
            boolean isRunning = response.getIsRunning();
            response.dispose();
            return isRunning;
        }
        else if ("Day".equals(frequency)) {
            IsStocksDayOHLCHistoryFetchRunningRequestMessage request = IsStocksDayOHLCHistoryFetchRunningRequestMessage.create();
            IsStocksDayOHLCHistoryFetchRunningResponseMessage response = client.isDayOHLCHistoryFetchRunning(request);
            boolean isRunning = response.getIsRunning();
            response.dispose();
            return isRunning;
        }
        else {
            // default: Minute
            IsStocksMinuteOHLCHistoryFetchRunningRequestMessage request = IsStocksMinuteOHLCHistoryFetchRunningRequestMessage.create();
            IsStocksMinuteOHLCHistoryFetchRunningResponseMessage response = client.isMinuteOHLCHistoryFetchRunning(request);
            boolean isRunning = response.getIsRunning();
            response.dispose();
            return isRunning;
        }
    }

    final private static void run(final String frequency, final Date date, final String[] symbols, final boolean wait) throws Exception {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0");

        // start the download
        String status = startDownload(client, frequency, date, symbols);

        if (status != null) {
            System.out.println("Error: " + status);
            client.close();
            return;
        }

        System.out.println(frequency + " OHLC history download started successfully.");

        // wait for completion if requested
        if (wait) {
            long startTime = System.currentTimeMillis();
            while (true) {
                Thread.sleep(5000);
                long elapsed = (System.currentTimeMillis() - startTime) / 1000;
                System.out.println("Downloading " + frequency + " OHLC history... (" + elapsed + "s elapsed)");

                if (!isDownloadRunning(client, frequency)) {
                    System.out.println(frequency + " OHLC history download completed. (" + elapsed + "s)");
                    break;
                }
            }
        }

        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option dateOption = parser.addStringOption('d', "date");
        final CmdLineParser.Option symbolsOption = parser.addStringOption('s', "symbols");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option waitOption = parser.addBooleanOption('w', "wait");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            final String dateStr = (String)parser.getOptionValue(dateOption, null);
            if (dateStr == null) printUsage();
            final Date date = dateFormat().parse(dateStr);
            final String symbolsStr = (String)parser.getOptionValue(symbolsOption, null);
            final String[] symbols = symbolsStr != null ? symbolsStr.split(",") : null;
            final String frequency = (String)parser.getOptionValue(frequencyOption, "Minute");
            final boolean wait = (Boolean)parser.getOptionValue(waitOption, false);

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: Synthetic");
            System.out.println("...Date: " + dateStr);
            System.out.println("...Symbols: " + (symbolsStr != null ? symbolsStr : "(all)"));
            System.out.println("...Frequency: " + frequency);
            System.out.println("...Wait: " + wait);
            System.out.println("}");

            // execute
            run(frequency, date, symbols, wait);
        }
        else {
            printUsage();
        }
    }
}
