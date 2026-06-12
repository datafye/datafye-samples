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
package com.datafye.samples.java.crypto.backtest;

import jargs.gnu.CmdLineParser;

import com.datafye.roe.*;
import com.datafye.samples.client.CryptoHistoryClient;

public class IsQuoteDownloadRunning {

    final private static void printUsage() {
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run() {
        // create the client
        CryptoHistoryClient client = new CryptoHistoryClient("samples", "0");

        // check if download is running
        IsCryptoQuoteHistoryFetchRunningRequestMessage request = IsCryptoQuoteHistoryFetchRunningRequestMessage.create();
        IsCryptoQuoteHistoryFetchRunningResponseMessage response = client.isQuoteHistoryFetchRunning(request);
        boolean isRunning = response.getIsRunning();
        response.dispose();

        System.out.println("Quote history download is running: " + isRunning);

        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // dump parameters
            System.out.println("Parameters {");
            System.out.println("}");

            // execute
            run();
        }
        else {
            printUsage();
        }
    }
}
