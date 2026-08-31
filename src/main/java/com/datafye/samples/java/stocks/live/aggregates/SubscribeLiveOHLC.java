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

public class SubscribeLiveOHLC {

    private int _numBarsReceived = 0;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbols the symbols (comma separated) to stream the OHLC bars for (required)]");
        System.err.println("    [{-c, --frequency the bar frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-D, --dataset the dataset (Synthetic, SIP) (default=Synthetic)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    /*
     * Issues a synchronous request to the live aggregate server to start streaming OHLC bars for the
     * requested symbols. Bars streamed by the server will be dispatched to the onLiveOHLCDataMessage()
     * message handler (see below).
     */
    final private void subscribe(final AggClient client, final OHLCFrequency frequency, final String[] symbols) throws Exception {
        SubscribeLiveStocksOHLCRequestMessage request = SubscribeLiveStocksOHLCRequestMessage.create();
        request.setFrequency(frequency);
        request.setSymbols(symbols);
        SubscribeLiveStocksOHLCResponseMessage response = client.subscribeLiveOHLC(request);
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
     * Issues a synchronous request to the live aggregate server to stop streaming OHLC bars for the
     * previously subscribed symbols.
     */
    final private void unsubscribe(final AggClient client, final OHLCFrequency frequency, final String[] symbols) throws Exception {
        UnsubscribeLiveStocksOHLCRequestMessage request = UnsubscribeLiveStocksOHLCRequestMessage.create();
        request.setFrequency(frequency);
        request.setSymbols(symbols);
        UnsubscribeLiveStocksOHLCResponseMessage response = client.unsubscribeLiveOHLC(request);
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

                // we sleep until 1000 bars are received
                while (_numBarsReceived < 1000) {
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
     * This is the handler of the OHLC bar messages. The handler is invoked as and when
     * the live aggregate client receives bars for the subscribed symbols
     */
    /*
     * One @EventHandler per frequency: the live aggregate service streams the per-frequency typed bar
     * (StocksSecondOHLCMessage / StocksMinuteOHLCMessage / StocksHourOHLCMessage), so a client just adds
     * a handler for the frequency it cares about and the engine's type-based dispatch does the filtering.
     */
    /*
     * (!) The prices are passed as Double, not double, because a bar can legitimately have NONE.
     *
     * Volume eligibility and price eligibility are decided separately: an odd lot contributes its
     * shares and no price. A bucket in which every print was volume-only therefore carries real
     * volume with no last-sale price behind it, and the price fields come back ABSENT. Reading them
     * with getOpen() alone would render that as 0.0 -- a price no trade ever happened at, and a
     * spike to zero in anything you go on to plot. Test hasOpen() and friends first.
     *
     * This is most visible at Second frequency and rare at Minute and above.
     */
    private void onBar(final String frequency, final String symbol, final long timestamp,
                       final Double open, final Double high, final Double low, final Double close, final long volume) {
        System.out.println("<-- StocksOHLC[" + frequency + "] {" + symbol + "," + timestamp + ","
                           + price(open) + "," + price(high) + "," + price(low) + "," + price(close) + ","
                           + volume + "}");
        _numBarsReceived++;
    }

    /** Renders an absent price as "-" rather than inventing a number for it. */
    private static String price(final Double value) {
        return value == null ? "-" : value.toString();
    }

    @EventHandler
    final public void onStocksSecondOHLC(final StocksSecondOHLCMessage m) {
        onBar("Second", m.getSymbol(), m.getTimestamp(),
              m.hasOpen() ? m.getOpen() : null, m.hasHigh() ? m.getHigh() : null,
              m.hasLow() ? m.getLow() : null, m.hasClose() ? m.getClose() : null, m.getVolume());
    }

    @EventHandler
    final public void onStocksMinuteOHLC(final StocksMinuteOHLCMessage m) {
        onBar("Minute", m.getSymbol(), m.getTimestamp(),
              m.hasOpen() ? m.getOpen() : null, m.hasHigh() ? m.getHigh() : null,
              m.hasLow() ? m.getLow() : null, m.hasClose() ? m.getClose() : null, m.getVolume());
    }

    @EventHandler
    final public void onStocksHourOHLC(final StocksHourOHLCMessage m) {
        onBar("Hour", m.getSymbol(), m.getTimestamp(),
              m.hasOpen() ? m.getOpen() : null, m.hasHigh() ? m.getHigh() : null,
              m.hasLow() ? m.getLow() : null, m.hasClose() ? m.getClose() : null, m.getVolume());
    }

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
            new SubscribeLiveOHLC().run(dataset, frequency, symbols);
        }
        else {
            printUsage();
        }
    }
}
