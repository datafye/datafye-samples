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
package com.datafye.samples.java.crypto.live.aggregates;

import jargs.gnu.CmdLineParser;

import com.neeve.aep.annotations.EventHandler;

import com.datafye.roe.*;
import com.datafye.samples.client.CryptoAggClient;

public class SubscribeLiveOHLC {

    private int _numBarsReceived = 0;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbols the symbols (comma separated) to stream the OHLC bars for (required)]");
        System.err.println("    [{-c, --frequency the bar frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    /*
     * Issues a synchronous request to the live aggregate server to start streaming OHLC bars for the
     * requested symbols. Bars streamed by the server will be dispatched to the onLiveOHLCDataMessage()
     * message handler (see below).
     */
    final private void subscribe(final CryptoAggClient client, final OHLCFrequency frequency, final String[] symbols) throws Exception {
        SubscribeLiveCryptoOHLCRequestMessage request = SubscribeLiveCryptoOHLCRequestMessage.create();
        request.setFrequency(frequency);
        request.setSymbols(symbols);
        SubscribeLiveCryptoOHLCResponseMessage response = client.subscribeLiveOHLC(request);
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
    final private void unsubscribe(final CryptoAggClient client, final OHLCFrequency frequency, final String[] symbols) throws Exception {
        UnsubscribeLiveCryptoOHLCRequestMessage request = UnsubscribeLiveCryptoOHLCRequestMessage.create();
        request.setFrequency(frequency);
        request.setSymbols(symbols);
        UnsubscribeLiveCryptoOHLCResponseMessage response = client.unsubscribeLiveOHLC(request);
        try {
            if (response.getStatus() != null) {
                throw new Exception(response.getStatus());
            }
        }
        finally {
            response.dispose();
        }
    }

    final private void run(final OHLCFrequency frequency, final String commaSeparatedSymbols) throws Exception {
        // create the live aggregate client
        final CryptoAggClient client = new CryptoAggClient("samples", "0");
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
     * (CryptoSecondOHLCMessage / CryptoMinuteOHLCMessage / CryptoHourOHLCMessage), so a client just adds
     * a handler for the frequency it cares about. (Crypto volume is a double.)
     */
    private void onBar(final String frequency, final String symbol, final long timestamp,
                       final double open, final double high, final double low, final double close, final double volume) {
        System.out.println("<-- CryptoOHLC[" + frequency + "] {" + symbol + "," + timestamp + ","
                           + open + "," + high + "," + low + "," + close + "," + volume + "}");
        _numBarsReceived++;
    }

    @EventHandler
    final public void onCryptoSecondOHLC(final CryptoSecondOHLCMessage m) {
        onBar("Second", m.getSymbol(), m.getTimestamp(), m.getOpen(), m.getHigh(), m.getLow(), m.getClose(), m.getVolume());
    }

    @EventHandler
    final public void onCryptoMinuteOHLC(final CryptoMinuteOHLCMessage m) {
        onBar("Minute", m.getSymbol(), m.getTimestamp(), m.getOpen(), m.getHigh(), m.getLow(), m.getClose(), m.getVolume());
    }

    @EventHandler
    final public void onCryptoHourOHLC(final CryptoHourOHLCMessage m) {
        onBar("Hour", m.getSymbol(), m.getTimestamp(), m.getOpen(), m.getHigh(), m.getLow(), m.getClose(), m.getVolume());
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolsOption = parser.addStringOption('s', "symbols");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbols
            final String symbols = (String)parser.getOptionValue(symbolsOption, null);
            if (symbols == null) printUsage();

            // ...frequency
            final OHLCFrequency frequency = OHLCFrequency.valueOf((String)parser.getOptionValue(frequencyOption, "Minute"));

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Frequency: " + frequency);
            System.out.println("...Symbols: " + symbols);
            System.out.println("}");

            // execute
            new SubscribeLiveOHLC().run(frequency, symbols);
        }
        else {
            printUsage();
        }
    }
}
