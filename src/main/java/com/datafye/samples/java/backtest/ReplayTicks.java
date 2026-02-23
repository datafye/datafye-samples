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
import com.datafye.client.sip.FeedClient;

public class ReplayTicks {
    static {
        System.setProperty("datafye-sip-feed.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-sip-feed");
    }

    final private static void printUsage() {
        System.err.println("    [{-d, --date the date to replay ticks for (format=YYYY-MM-DD) (required)]");
        System.err.println("    [{-w, --wait wait for replay to complete]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run(final String date, final boolean wait) throws Exception {
        // create the client
        FeedClient client = new FeedClient("samples", "0");

        // start the replay
        StartHistoricalStocksTickReplayRequestMessage request = StartHistoricalStocksTickReplayRequestMessage.create();
        request.serializer().date(date).rateType(HistoricalFeedRateType.Exact).done();
        StartHistoricalStocksTickReplayResponseMessage response = client.startHistoricalTickReplay(request);
        response.dispose();

        System.out.println("Tick replay started successfully.");

        // wait for completion if requested
        if (wait) {
            long startTime = System.currentTimeMillis();
            while (true) {
                Thread.sleep(5000);
                long elapsed = (System.currentTimeMillis() - startTime) / 1000;
                System.out.println("Replaying ticks... (" + elapsed + "s elapsed)");

                IsHistoricalStocksTickReplayRunningRequestMessage statusRequest = IsHistoricalStocksTickReplayRunningRequestMessage.create();
                IsHistoricalStocksTickReplayRunningResponsetMessage statusResponse = client.isHistoricalTickReplayRunning(statusRequest);
                boolean isRunning = statusResponse.getIsRunning();
                statusResponse.dispose();

                if (!isRunning) {
                    System.out.println("Tick replay completed. (" + elapsed + "s)");
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
        final CmdLineParser.Option waitOption = parser.addBooleanOption('w', "wait");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            final String date = (String)parser.getOptionValue(dateOption, null);
            if (date == null) printUsage();
            final boolean wait = (Boolean)parser.getOptionValue(waitOption, false);

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: Synthetic");
            System.out.println("...Date: " + date);
            System.out.println("...Wait: " + wait);
            System.out.println("}");

            // execute
            run(date, wait);
        }
        else {
            printUsage();
        }
    }
}
