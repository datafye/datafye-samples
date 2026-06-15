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
package com.datafye.samples.java.stocks.live.aggregates;

import jargs.gnu.CmdLineParser;

import com.neeve.aep.annotations.EventHandler;

import com.datafye.roe.*;
import com.datafye.samples.client.AggClient;

public class SubscribeLiveEMA {

    private int _numValuesReceived = 0;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbols the symbols (comma separated) to stream the EMA values for (required)]");
        System.err.println("    [{-c, --frequency the bar frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-D, --dataset the dataset (Synthetic, SIP) (default=Synthetic)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    /*
     * Issues a synchronous request to the live aggregate server to start streaming EMA values for the
     * requested symbols. Values streamed by the server will be dispatched to the onLiveEMADataMessage()
     * message handler (see below).
     */
    final private void subscribe(final AggClient client, final OHLCFrequency frequency, final String[] symbols) throws Exception {
        SubscribeLiveEMARequestMessage request = SubscribeLiveEMARequestMessage.create();
        request.setFrequency(frequency);
        request.setSymbols(symbols);
        SubscribeLiveEMAResponseMessage response = client.subscribeLiveEMA(request);
        try {
            if (response.getStatus() != null) {
                throw new Exception(response.getStatus());
            }
        }
        finally {
            response.dispose();
        }
    }

    /*
     * Issues a synchronous request to the live aggregate server to stop streaming EMA values for the
     * previously subscribed symbols.
     */
    final private void unsubscribe(final AggClient client, final OHLCFrequency frequency, final String[] symbols) throws Exception {
        UnsubscribeLiveEMARequestMessage request = UnsubscribeLiveEMARequestMessage.create();
        request.setFrequency(frequency);
        request.setSymbols(symbols);
        UnsubscribeLiveEMAResponseMessage response = client.unsubscribeLiveEMA(request);
        try {
            if (response.getStatus() != null) {
                throw new Exception(response.getStatus());
            }
        }
        finally {
            response.dispose();
        }
    }

    final private void run(final String dataset, final OHLCFrequency frequency, final String commaSeparatedSymbols) throws Exception {
        // create the live aggregate client
        final AggClient client = new AggClient("samples", "0", dataset);
        try {
            // split into individual symbols
            final String[] symbols = commaSeparatedSymbols.split(",");

            // open the aggregate stream
            // ...this will open the underlying messaging connection to the live aggregate service
            client.openStream(this);
            try {
                // we first unsubscribe from all subscribed symbols.
                // ...this is done here to clear all existing subscriptions so we only get what we have subscribed to.
                unsubscribe(client, frequency, new String[] {"*"});

                // subscribe to the symbols
                subscribe(client, frequency, symbols);

                // we sleep until 1000 values are received
                while (_numValuesReceived < 1000) {
                    Thread.sleep(100);
                }
            }
            finally {
                try {
                    // unsubscribe to the symbols
                    unsubscribe(client, frequency, symbols);
                }
                finally {
                    // close the aggregate stream
                    client.closeStream();
                }
            }
        }
        finally {
            client.close();
        }
    }

    /*
     * This is the handler of the EMA value messages. The handler is invoked as and when
     * the live aggregate client receives values for the subscribed symbols
     */
    private void onEMA(final String frequency, final String symbol, final long timestamp, final double price, final double macd) {
        System.out.println("<-- StocksEMA[" + frequency + "] {" + symbol + "," + timestamp + "," + price + "," + macd + "}");
        _numValuesReceived++;
    }

    @EventHandler
    final public void onStocksSecondEMA(final StocksSecondEMAMessage m) { onEMA("Second", m.getSymbol(), m.getTimestamp(), m.getPrice(), m.getMacd()); }

    @EventHandler
    final public void onStocksMinuteEMA(final StocksMinuteEMAMessage m) { onEMA("Minute", m.getSymbol(), m.getTimestamp(), m.getPrice(), m.getMacd()); }

    @EventHandler
    final public void onStocksHourEMA(final StocksHourEMAMessage m) { onEMA("Hour", m.getSymbol(), m.getTimestamp(), m.getPrice(), m.getMacd()); }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolsOption = parser.addStringOption('s', "symbols");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option datasetOption = parser.addStringOption('D', "dataset");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbols
            final String symbols = (String)parser.getOptionValue(symbolsOption, null);
            if (symbols == null) printUsage();

            // ...frequency
            final OHLCFrequency frequency = OHLCFrequency.valueOf((String)parser.getOptionValue(frequencyOption, "Minute"));

            // ...dataset
            final String dataset = (String)parser.getOptionValue(datasetOption, "Synthetic");

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: " + dataset);
            System.out.println("...Frequency: " + frequency);
            System.out.println("...Symbols: " + symbols);
            System.out.println("}");

            // execute
            new SubscribeLiveEMA().run(dataset, frequency, symbols);
        }
        else {
            printUsage();
        }
    }
}
