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
 * Streams live SMA (simple moving average) values over a WebSocket from a Datafye Deployment.
 *
 * Connects to {@code /datafye-ws/v1/stocks/live/sma}, subscribes to the given symbols at a frequency, and
 * prints each computed SMA frame as it arrives. Available for the SIP, Synthetic and Crypto datasets.
 *
 * Note: an SMA only streams when that frequency's OHLC {@code publish} and SMA {@code process} are enabled
 * on the aggregation service, so the indicator is computed.
 *
 * Subscribe request: {@code {"action":"subscribe","dataset":"SIP","symbols":["AAPL"],"frequency":"Minute"}}
 */
public class SubscribeLiveSMA {
    static {
        System.setProperty("datafye-samples.ws.endpoint", "api.stream.rumi.local:7775");
    }

    final private static void printUsage() {
        System.err.println("    {-d, --dataset} dataset to stream (e.g. Synthetic, SIP, Crypto)");
        System.err.println("    {-s, --symbols} comma-separated symbols (e.g. AAPL,MSFT)");
        System.err.println("    {-f, --frequency} bar frequency (Second, Minute, Hour, Day)");
        System.err.println("    [{-t, --seconds} seconds to stream before exiting (default 30)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    public static void main(final String[] args) throws Exception {
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option datasetOption = parser.addStringOption('d', "dataset");
        final CmdLineParser.Option symbolsOption = parser.addStringOption('s', "symbols");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('f', "frequency");
        final CmdLineParser.Option secondsOption = parser.addIntegerOption('t', "seconds");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");
        parser.parse(args);

        final String dataset = (String) parser.getOptionValue(datasetOption);
        final String symbols = (String) parser.getOptionValue(symbolsOption);
        final String frequency = (String) parser.getOptionValue(frequencyOption);
        final int seconds = (Integer) parser.getOptionValue(secondsOption, 30);
        if ((Boolean) parser.getOptionValue(helpOption, false) || dataset == null || symbols == null || frequency == null) {
            printUsage();
        }

        final String subscribe = "{\"action\":\"subscribe\",\"dataset\":\"" + dataset
                + "\",\"symbols\":" + StreamClient.symbolsArray(symbols) + ",\"frequency\":\"" + frequency + "\"}";
        StreamClient.stream(StreamClient.wsUrl("stocks/live/sma"), subscribe, seconds);
    }
}
