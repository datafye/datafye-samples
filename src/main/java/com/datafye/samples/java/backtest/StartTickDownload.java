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
import com.datafye.samples.client.HistoryClient;

public class StartTickDownload {

    final private static void printUsage() {
        System.err.println("    [{-d, --date the date to download tick history for (format=YYYY-MM-DD) (required)]");
        System.err.println("    [{-s, --symbols the symbols (comma separated) to download tick history for (optional)]");
        System.err.println("    [{-w, --wait wait for download to complete]");
        System.err.println("    [{-D, --dataset the dataset (Synthetic, SIP) (default=Synthetic)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private static void run(final String dataset, final Date date, final String[] symbols, final boolean wait) throws Exception {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0", dataset);

        // start the download
        StartStocksTickHistoryFetchRequestMessage request = StartStocksTickHistoryFetchRequestMessage.create();
        request.serializer().startDate(date.getTime()).numDays(1).symbols(symbols).format(FileFormat.Binary).done();
        StartStocksTickHistoryFetchResponseMessage response = client.startTickHistoryFetch(request);

        String status = response.getStatus();
        response.dispose();

        if (status != null) {
            System.out.println("Error: " + status);
            client.close();
            return;
        }

        System.out.println("Tick history download started successfully.");

        // wait for completion if requested
        if (wait) {
            long startTime = System.currentTimeMillis();
            while (true) {
                Thread.sleep(5000);
                long elapsed = (System.currentTimeMillis() - startTime) / 1000;
                System.out.println("Downloading tick history... (" + elapsed + "s elapsed)");

                IsStocksTickHistoryFetchRunningRequestMessage statusRequest = IsStocksTickHistoryFetchRunningRequestMessage.create();
                IsStocksTickHistoryFetchRunningResponseMessage statusResponse = client.isTickHistoryFetchRunning(statusRequest);
                boolean isRunning = statusResponse.getIsRunning();
                statusResponse.dispose();

                if (!isRunning) {
                    System.out.println("Tick history download completed. (" + elapsed + "s)");
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
        final CmdLineParser.Option waitOption = parser.addBooleanOption('w', "wait");
        final CmdLineParser.Option datasetOption = parser.addStringOption('D', "dataset");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            final String dateStr = (String)parser.getOptionValue(dateOption, null);
            if (dateStr == null) printUsage();
            final Date date = dateFormat().parse(dateStr);
            final String symbolsStr = (String)parser.getOptionValue(symbolsOption, null);
            final String[] symbols = symbolsStr != null ? symbolsStr.split(",") : null;
            final boolean wait = (Boolean)parser.getOptionValue(waitOption, false);

            // ...dataset
            final String dataset = (String)parser.getOptionValue(datasetOption, "Synthetic");

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: " + dataset);
            System.out.println("...Date: " + dateStr);
            System.out.println("...Symbols: " + (symbolsStr != null ? symbolsStr : "(all)"));
            System.out.println("...Wait: " + wait);
            System.out.println("}");

            // execute
            run(dataset, date, symbols, wait);
        }
        else {
            printUsage();
        }
    }
}
