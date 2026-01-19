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
package com.datafye.gbpoc.client;

import java.util.Date;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

import jargs.gnu.CmdLineParser;

import com.neeve.aep.annotations.EventHandler;
import com.neeve.config.Config;
import com.neeve.trace.Tracer;

import com.nv.datafye.roe.*;

import com.datafye.trade.live.Client;

public class StreamLiveTrades {
    private int _numTradesReceived = 0;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbols the symbols (comma separated) to stream the trades for (required)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    /* 
     * This block of code issues a synchronous request to the live trade server to start streaming 
     * trades for the requested symbols. Trades streamed by the trade server will be dispatched to the
     * onLiveTradeDataMessage() message handler (see below). Control messages will be dispatched 
     * to the message handler that has the control message type as the argument of the handler. For example,
     * if trading is halted on a symbol, then a LiveTradeHaltMessage message will be dispatched
     * to the onLiveTradeHaltMessage() handler (see below) and, correspondingly, when the trading 
     * is resumed on the symbol, then a LiveTradeResumeMessage message will be dispatched to the 
     * onLiveTradeResumeMessage message handler.
     */
    final private void subscribe(final Client client, final String[] symbols) throws Exception {
        SubscribeLiveTradesRequestMessage request = SubscribeLiveTradesRequestMessage.create();
        request.setMarket(Market.SIP);
        request.setSymbols(symbols);
        SubscribeLiveTradesResponseMessage response = client.subscribeLiveTrades(request);
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
     * This block of code issues a synchronous request to the live trade server to stop streaming 
     * trades for the previously subscribed symbols. Note that unsubscribing to symbols does not stop the 
     * flow of control messages that are not tied to particular symbols. Those messages continue to flow
     * until the stream connection is closed.
     */
    final private void unsubscribe(final Client client, final String[] symbols) throws Exception {
        UnsubscribeLiveTradesRequestMessage request = UnsubscribeLiveTradesRequestMessage.create();
        request.setMarket(Market.SIP);
        request.setSymbols(symbols);
        UnsubscribeLiveTradesResponseMessage response = client.unsubscribeLiveTrades(request);
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
        // create the live trades client
        // ...this is the same client one uses to synchronously fetch live candles too (see the GetLiveCandles.java sample program)
        final Client client = new Client("gbpoc", "0");
        try {
            // split into individual symbols
            final String[] symbols = commaSeparatedSymbols.split(",");

            // open the trade stream
            // ...this will open the underlying messaging connection to the live trade service
            client.openStream(this);
            try {
                // we firs unsubscribe from all subscribed symbols. 
                // ...this is done here to clear all existing subscriptions so we only get what we have subscribed to.
                unsubscribe(client, new String[] {"*"});

                // subscribe to the symbols
                subscribe(client, symbols);

                // we sleep until a 1000 trades are received
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
                    // ...this will close the underlying messaging connection to the live trade service
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
     * the live trade client receives trades and trade events for the subscribed symbols 
     */
    @EventHandler
    final public void onLiveTradeDataMessage(final LiveTradeDataMessage message) {
        /***** 
         * Note: Live trade data messages is currently not supported. When supported 
         *       and subscribed to, then they would arrive in this handler 
         ******/

        // update the receive count
        _numTradesReceived++;
    }

    /*
     * This is the handler of the trading halt message and is invoked when trading is halted on a symbol
     */
    @EventHandler
    final public void onLiveTradeHaltMessage(final LiveTradeHaltMessage message) {
        System.out.println(message.toString());
    }

    /*
     * This is the handler of the trading resume message and is invoked when trading is resumed on a symbol
     */
    @EventHandler
    final public void onLiveTradeResumeMessage(final LiveTradeResumeMessage message) {
        /***** 
         * Note: Live trade resume messages is currently not supported. When supported 
         *       and subscribed to, then they would arrive in this handler 
         ******/
        System.out.println(message.toString());
    }

    /* 
     * Note: The above two handlers are examples of control message handlers. You should implement 
     *       a handler for each control message type that you are interested in.  
     */


    public static void main(String args[]) throws Exception {
        // set default Rumi trace level
        System.setProperty("nv.trace.defaultLevel", "warn");

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
            new StreamLiveTrades().run(symbols);
        }
        else {
            printUsage();
        }
    }
}
