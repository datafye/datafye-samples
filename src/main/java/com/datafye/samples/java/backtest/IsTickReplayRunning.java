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
import com.datafye.samples.client.FeedClient;

public class IsTickReplayRunning {

    final private static void printUsage() {
        System.err.println("    [{-D, --dataset the dataset (Synthetic, SIP) (default=Synthetic)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run(final String dataset) {
        // create the client
        FeedClient client = new FeedClient("samples", "0", dataset);

        // check if replay is running (note: response class has typo in library)
        IsHistoricalStocksTickReplayRunningRequestMessage request = IsHistoricalStocksTickReplayRunningRequestMessage.create();
        IsHistoricalStocksTickReplayRunningResponsetMessage response = client.isHistoricalTickReplayRunning(request);
        boolean isRunning = response.getIsRunning();
        response.dispose();

        System.out.println("Tick replay is running: " + isRunning);

        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option datasetOption = parser.addStringOption('D', "dataset");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // ...dataset
            final String dataset = (String)parser.getOptionValue(datasetOption, "Synthetic");

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: " + dataset);
            System.out.println("}");

            // execute
            run(dataset);
        }
        else {
            printUsage();
        }
    }
}
