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
package com.datafye.samples.ws;

import jargs.gnu.CmdLineParser;

/**
 * Streams a historical OHLC range over a WebSocket from a Datafye Deployment.
 *
 * Connects to {@code /datafye-ws/v1/stocks/history}, starts a replay of stored OHLC bars for a single
 * symbol over a time range, and prints each bar frame as it arrives, followed by a {@code stream_end}.
 * Available for the SIP, Synthetic and Crypto datasets.
 *
 * Start request:
 * {@code {"action":"start","dataset":"SIP","symbol":"AAPL","frequency":"Minute","from":"2025-01-02T09:30:00","to":"2025-01-02T16:00:00"}}
 */
public class StreamHistoricalOHLC {
    static {
        System.setProperty("datafye-samples.ws.endpoint", "api.stream.rumi.local:7775");
    }

    final private static void printUsage() {
        System.err.println("    {-d, --dataset} dataset to stream (e.g. Synthetic, SIP, Crypto)");
        System.err.println("    {-s, --symbol} a single symbol (e.g. AAPL)");
        System.err.println("    {-f, --frequency} bar frequency (Second, Minute, Hour, Day)");
        System.err.println("    {-b, --from} range start (ISO-8601, e.g. 2025-01-02T09:30:00)");
        System.err.println("    {-e, --to} range end (ISO-8601, e.g. 2025-01-02T16:00:00)");
        System.err.println("    [{-t, --seconds} seconds to stream before exiting (default 30)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    public static void main(final String[] args) throws Exception {
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option datasetOption = parser.addStringOption('d', "dataset");
        final CmdLineParser.Option symbolOption = parser.addStringOption('s', "symbol");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('f', "frequency");
        final CmdLineParser.Option fromOption = parser.addStringOption('b', "from");
        final CmdLineParser.Option toOption = parser.addStringOption('e', "to");
        final CmdLineParser.Option secondsOption = parser.addIntegerOption('t', "seconds");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");
        parser.parse(args);

        final String dataset = (String) parser.getOptionValue(datasetOption);
        final String symbol = (String) parser.getOptionValue(symbolOption);
        final String frequency = (String) parser.getOptionValue(frequencyOption);
        final String from = (String) parser.getOptionValue(fromOption);
        final String to = (String) parser.getOptionValue(toOption);
        final int seconds = (Integer) parser.getOptionValue(secondsOption, 30);
        if ((Boolean) parser.getOptionValue(helpOption, false)
                || dataset == null || symbol == null || frequency == null || from == null || to == null) {
            printUsage();
        }

        final String start = "{\"action\":\"start\",\"dataset\":\"" + dataset + "\",\"symbol\":\"" + symbol
                + "\",\"frequency\":\"" + frequency + "\",\"from\":\"" + from + "\",\"to\":\"" + to + "\"}";
        StreamClient.stream(StreamClient.wsUrl("stocks/history"), start, seconds);
    }
}
