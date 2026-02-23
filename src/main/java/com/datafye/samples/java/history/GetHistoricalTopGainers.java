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
package com.datafye.samples.java.history;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;

import jargs.gnu.CmdLineParser;

import com.datafye.roe.*;
import com.datafye.client.synthetic.HistoryClient;

public class GetHistoricalTopGainers {
    static {
        System.setProperty("datafye-synthetic-history.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-synthetic-history");
    }

    final private static void printUsage() {
        System.err.println("    [{-d, --date the date to fetch top gainers for (format=YYYY-MM-DD) (required)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private static void run(final Date date) {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0");

        // perform 100 fetches
        long totalTime = 0;
        long totalCount = 0;
        for (int i = 0 ; i < 100 ; i++) {
            // run and benchmark
            long start = System.currentTimeMillis();
            GetTopGainerStocksRequestMessage request = GetTopGainerStocksRequestMessage.create();
            request.setDate(date);
            GetTopGainerStocksResponseMessage response = client.getTopGainers(request);
            final int gainersCount = response.getTopGainersCount();
            long stop = System.currentTimeMillis();

            // update totals
            totalTime += (stop-start);
            totalCount += gainersCount;

            // dispose the response
            response.dispose();
        }

        // average time
        System.out.println("Fetched '" + (totalCount/100) + "' top gainers in " + (totalTime/100) + " milliseconds.");

        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option dateOption = parser.addStringOption('d', "date");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...date
            final String dateStr = (String)parser.getOptionValue(dateOption, null);
            if (dateStr == null) printUsage();
            final SimpleDateFormat df = dateFormat();
            Date date = null;
            if (dateStr != null) {
                try {
                    date = df.parse(dateStr);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    printUsage();
                }
            }

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Date: " + dateStr);
            System.out.println("}");

            // execute
            run(date);
        }
        else {
            printUsage();
        }
    }
}
