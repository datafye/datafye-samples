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

public class StreamLiveTopOfBook {
    static {
        System.setProperty("datafye-synthetic-feed.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-synthetic-feed");
        System.setProperty("datafye-synthetic-feed.stream.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-synthetic-feed-stream");
    }

    private int _numQuotesReceived = 0;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbols the symbols (comma separated) to stream the top-of-book quote for (required)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    /*
     * This block of code issues a synchronous request to the live feed server to start streaming top-of-book
     * quotes for the requested symbols. Quotes streamed by the feed server will be dispatched to the
     * onLiveTopOfBookQuoteDataMessage() message handler (see below). Control messages will be dispatched
     * to the message handler that has the control message type as the argument of the handler. For example,
     * if trading is halted on a symbol, then a LiveTopOfBookStocksQuoteHaltMessage message will be dispatched
     * to the onLiveTopOfBookQuoteHaltMessage() handler (see below) and, correspondingly, when the trading
     * is resumed on the symbol, then a LiveTopOfBookStocksQuoteResumeMessage message will be dispatched to the
     * onLiveTopOfBookQuoteResumeMessage message handler.
     */
    final private void subscribe(final FeedClient client, final String[] symbols) throws Exception {
        SubscribeLiveTopOfBookStocksQuotesRequestMessage request = SubscribeLiveTopOfBookStocksQuotesRequestMessage.create();
        request.setSymbols(symbols);
        SubscribeLiveTopOfBookStocksQuotesResponseMessage response = client.subscribeLiveTopOfBookQuotes(request);
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
     * This block of code issues a synchronous request to the live feed server to stop streaming top-of-book
     * quotes for the previously subscribed symbols. Note that unsubscribing to symbols does not stop the
     * flow of control messages that are not tied to particular symbols. Those messages continue to flow
     * until the stream connection is closed.
     */
    final private void unsubscribe(final FeedClient client, final String[] symbols) throws Exception {
        UnsubscribeLiveTopOfBookStocksQuotesRequestMessage request = UnsubscribeLiveTopOfBookStocksQuotesRequestMessage.create();
        request.setSymbols(symbols);
        UnsubscribeLiveTopOfBookStocksQuotesResponseMessage response = client.unsubscribeLiveTopOfBookQuotes(request);
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

            // open the quote stream
            // ...this will open the underlying messaging connection to the live feed service
            client.openStream(this);
            try {
                // we first unsubscribe from all subscribed symbols.
                // ...this is done here to clear all existing subscriptions so we only get what we have subscribed to.
                unsubscribe(client, new String[] {"*"});

                // subscribe to the symbols
                subscribe(client, symbols);

                // we sleep until 1000 messages are received
                while (_numQuotesReceived < 1000) {
                    Thread.sleep(100);
                }
            }
            finally {
                try {
                    // unsubscribe to the symbols
                    unsubscribe(client, symbols);
                }
                finally {
                    // close the quote stream
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
     * This is the handler of the top of book quote messages. The handler is invoked as and when
     * the live feed client receives top-of-book quotes for the subscribed symbols
     */
    @EventHandler
    final public void onLiveTopOfBookQuoteDataMessage(final LiveTopOfBookStocksQuoteDataMessage message) {
        // print the message
        StringBuilder sb = new StringBuilder("<-- LiveTopOfBookStocksQuoteDataMessage {");
        sb.append(message.getMarket()).append(",");
        sb.append(message.getSymbol()).append(",");
        sb.append(message.getExchangeTimestamp()).append(",");
        sb.append(message.getBidExchangeID()).append(",");
        sb.append(message.getBidPrice()).append(",");
        sb.append(message.getBidSize()).append(",");
        sb.append(message.getAskExchangeID()).append(",");
        sb.append(message.getAskPrice()).append(",");
        sb.append(message.getAskSize()).append("}");
        System.out.println(sb.toString());

        // update the receive count
        _numQuotesReceived++;
    }

    /*
     * This is the handler of the trading halt message and is invoked when trading is halted on a symbol
     */
    @EventHandler
    final public void onLiveTopOfBookQuoteHaltMessage(final LiveTopOfBookStocksQuoteHaltMessage message) {
        System.out.println(message.toString());
    }

    /*
     * This is the handler of the trading resume message and is invoked when trading is resumed on a symbol
     */
    @EventHandler
    final public void onLiveTopOfBookQuoteResumeMessage(final LiveTopOfBookStocksQuoteResumeMessage message) {
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
            new StreamLiveTopOfBook().run(symbols);
        }
        else {
            printUsage();
        }
    }
}
