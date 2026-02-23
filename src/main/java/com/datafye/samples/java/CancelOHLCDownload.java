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

import jargs.gnu.CmdLineParser;

import com.datafye.roe.*;
import com.datafye.client.sip.HistoryClient;

public class CancelOHLCDownload {
    static {
        System.setProperty("datafye-sip-history.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-sip-history");
    }

    final private static void printUsage() {
        System.err.println("    [{-c, --frequency the OHLC frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run(final String frequency) {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0");

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
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse parameters
            final String frequency = (String)parser.getOptionValue(frequencyOption, "Minute");

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: Synthetic");
            System.out.println("...Frequency: " + frequency);
            System.out.println("}");

            // execute
            run(frequency);
        }
        else {
            printUsage();
        }
    }
}
