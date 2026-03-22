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

import jargs.gnu.CmdLineParser;

import com.datafye.roe.*;
import com.datafye.samples.client.HistoryClient;

public class CancelOHLCDownload {

    final private static void printUsage() {
        System.err.println("    [{-c, --frequency the OHLC frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-D, --dataset the dataset (Synthetic, SIP) (default=Synthetic)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run(final String dataset, final String frequency) {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0", dataset);

        // cancel the download
        String status;
        if ("Second".equals(frequency)) {
            CancelStocksSecondOHLCHistoryFetchRequestMessage request = CancelStocksSecondOHLCHistoryFetchRequestMessage.create();
            CancelStocksSecondOHLCHistoryFetchResponseMessage response = client.cancelSecondOHLCHistoryFetch(request);
            status = response.getStatus();
            response.dispose();
        }
        else if ("Hour".equals(frequency)) {
            CancelStocksHourOHLCHistoryFetchRequestMessage request = CancelStocksHourOHLCHistoryFetchRequestMessage.create();
            CancelStocksHourOHLCHistoryFetchResponseMessage response = client.cancelHourOHLCHistoryFetch(request);
            status = response.getStatus();
            response.dispose();
        }
        else if ("Day".equals(frequency)) {
            CancelStocksDayOHLCHistoryFetchRequestMessage request = CancelStocksDayOHLCHistoryFetchRequestMessage.create();
            CancelStocksDayOHLCHistoryFetchResponseMessage response = client.cancelDayOHLCHistoryFetch(request);
            status = response.getStatus();
            response.dispose();
        }
        else {
            // default: Minute
            CancelStocksMinuteOHLCHistoryFetchRequestMessage request = CancelStocksMinuteOHLCHistoryFetchRequestMessage.create();
            CancelStocksMinuteOHLCHistoryFetchResponseMessage response = client.cancelMinuteOHLCHistoryFetch(request);
            status = response.getStatus();
            response.dispose();
        }

        if (status != null) {
            System.out.println("Error: " + status);
        }
        else {
            System.out.println(frequency + " OHLC history download cancelled successfully.");
        }

        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option datasetOption = parser.addStringOption('D', "dataset");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse parameters
            final String frequency = (String)parser.getOptionValue(frequencyOption, "Minute");

            // ...dataset
            final String dataset = (String)parser.getOptionValue(datasetOption, "Synthetic");

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: " + dataset);
            System.out.println("...Frequency: " + frequency);
            System.out.println("}");

            // execute
            run(dataset, frequency);
        }
        else {
            printUsage();
        }
    }
}
