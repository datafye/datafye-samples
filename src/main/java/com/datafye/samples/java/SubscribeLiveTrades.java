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

import com.neeve.aep.annotations.EventHandler;

import com.datafye.roe.*;
import com.datafye.client.synthetic.FeedClient;

public class SubscribeLiveTrades {
    static {
        System.setProperty("datafye-synthetic-feed.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-synthetic-feed");
        System.setProperty("datafye-synthetic-feed.stream.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-synthetic-feed-stream");
    }

    private int _numTradesReceived = 0;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbols the symbols (comma separated) to stream the trades for (required)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    /*
     * This block of code issues a synchronous request to the live feed server to start streaming
     * trades for the requested symbols. Trades streamed by the feed server will be dispatched to the
     * onLiveTradeDataMessage() message handler (see below). Control messages will be dispatched
     * to the message handler that has the control message type as the argument of the handler. For example,
     * if trading is halted on a symbol, then a LiveStocksTradeHaltMessage message will be dispatched
     * to the onLiveTradeHaltMessage() handler (see below) and, correspondingly, when the trading
     * is resumed on the symbol, then a LiveStocksTradeResumeMessage message will be dispatched to the
     * onLiveTradeResumeMessage message handler.
     */
    final private void subscribe(final FeedClient client, final String[] symbols) throws Exception {
        SubscribeLiveStocksTradesRequestMessage request = SubscribeLiveStocksTradesRequestMessage.create();
        request.setSymbols(symbols);
        SubscribeLiveStocksTradesResponseMessage response = client.subscribeLiveTrades(request);
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
     * This block of code issues a synchronous request to the live feed server to stop streaming
     * trades for the previously subscribed symbols. Note that unsubscribing to symbols does not stop the
     * flow of control messages that are not tied to particular symbols. Those messages continue to flow
     * until the stream connection is closed.
     */
    final private void unsubscribe(final FeedClient client, final String[] symbols) throws Exception {
        UnsubscribeLiveStocksTradesRequestMessage request = UnsubscribeLiveStocksTradesRequestMessage.create();
        request.setSymbols(symbols);
        UnsubscribeLiveStocksTradesResponseMessage response = client.unsubscribeLiveTrades(request);
        try {
            if (response.getStatus() != null) {
                throw new Exception(response.getStatus());
            }
        }
        finally {
            response.dispose();
        }
    }

    final private void run(final String commaSeparatedSymbols) throws Exception {
        // create the live feed client
        final FeedClient client = new FeedClient("samples", "0");
        try {
            // split into individual symbols
            final String[] symbols = commaSeparatedSymbols.split(",");

            // open the trade stream
            // ...this will open the underlying messaging connection to the live feed service
            client.openStream(this);
            try {
                // we first unsubscribe from all subscribed symbols.
                // ...this is done here to clear all existing subscriptions so we only get what we have subscribed to.
                unsubscribe(client, new String[] {"*"});

                // subscribe to the symbols
                subscribe(client, symbols);

                // we sleep until 1000 trades are received
                while (_numTradesReceived < 1000) {
                    Thread.sleep(100);
                }
            }
            finally {
                try {
                    // unsubscribe to the symbols
                    unsubscribe(client, symbols);
                }
                finally {
                    // close the trade stream
                    // ...this will close the underlying messaging connection to the live feed service
                    client.closeStream();
                }
            }
        }
        finally {
            client.close();
        }
    }

    /*
     * This is the handler of the trade messages. The handler is invoked as and when
     * the live feed client receives trades for the subscribed symbols
     */
    @EventHandler
    final public void onLiveTradeDataMessage(final LiveStocksTradeDataMessage message) {
        // print the message
        StringBuilder sb = new StringBuilder("<-- LiveStocksTradeDataMessage {");
        sb.append(message.getMarket()).append(",");
        sb.append(message.getSymbol()).append(",");
        sb.append(message.getExchangeTimestamp()).append(",");
        sb.append(message.getExchangeID()).append(",");
        sb.append(message.getTradePrice()).append(",");
        sb.append(message.getTradeSize()).append("}");
        System.out.println(sb.toString());

        // update the receive count
        _numTradesReceived++;
    }

    /*
     * This is the handler of the trading halt message and is invoked when trading is halted on a symbol
     */
    @EventHandler
    final public void onLiveTradeHaltMessage(final LiveStocksTradeHaltMessage message) {
        System.out.println(message.toString());
    }

    /*
     * This is the handler of the trading resume message and is invoked when trading is resumed on a symbol
     */
    @EventHandler
    final public void onLiveTradeResumeMessage(final LiveStocksTradeResumeMessage message) {
        System.out.println(message.toString());
    }

    /*
     * Note: The above two handlers are examples of control message handlers. You should implement
     *       a handler for each control message type that you are interested in.
     */


    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolsOption = parser.addStringOption('s', "symbols");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbols
            final String symbols = (String)parser.getOptionValue(symbolsOption, null);
            if (symbols == null) printUsage();

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Symbols: " + symbols);
            System.out.println("}");

            // execute
            new SubscribeLiveTrades().run(symbols);
        }
        else {
            printUsage();
        }
    }
}
