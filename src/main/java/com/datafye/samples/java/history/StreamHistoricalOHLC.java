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

import com.neeve.aep.annotations.EventHandler;
import com.neeve.lang.XStringDeserializer;

import com.datafye.roe.*;
import com.datafye.samples.client.HistoryClient;
import com.datafye.samples.client.HistoryClient.HistoricalOHLCStream;

import com.datafye.samples.rest.domain.OHLC;

/**
 * Streams historical OHLC bars using the History client.
 */
public class StreamHistoricalOHLC {

    final private class OHLCPopulator extends StocksMinuteOHLCMessage.Deserializer.AbstractCallbackImpl {
        private OHLC _ohlc;

        void populate(OHLC ohlc, StocksMinuteOHLCMessage message) {
            _ohlc = ohlc;
            message.deserializer().run(this);
        }

        @Override
        public void handleTimestamp(long val) {
            _ohlc.setDatetime(val);
        }

        @Override
        public void handleOpen(double val) {
            _ohlc.setOpen(val);
        }

        @Override
        public void handleHigh(double val) {
            _ohlc.setHigh(val);
        }

        @Override
        public void handleLow(double val) {
            _ohlc.setLow(val);
        }

        @Override
        public void handleClose(double val) {
            _ohlc.setClose(val);
        }

        @Override
        public void handleVolume(long val) {
            _ohlc.setVolume(val);
        }

        @Override
        public void handleSymbol(XStringDeserializer val) {
            _ohlc.setSymbol(val.toASCIIString());
        }
    }

    private OHLC _ohlc = new OHLC();
    private OHLCPopulator _ohlcPopulator = new OHLCPopulator();
    private boolean _done;

    final private static void printUsage() {
        System.err.println("    [{-s, --symbol the symbol to stream OHLC bars for (not specified means all symbols)]");
        System.err.println("    [{-f, --from the lower bound of the time window to fetch OHLC bars for (format=YYYY-MM-DDTHH:mm:ss)]");
        System.err.println("    [{-t, --to the upper bound of the time window to fetch OHLC bars for (format=YYYY-MM-DDTHH:mm:ss))]");
        System.err.println("    [{-r, --rate the maximum rate at which the server should stream the data)]");
        System.err.println("    [{-D, --dataset the dataset (Synthetic, SIP) (default=Synthetic)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private void run(final String dataset, final String symbol, final Date from, final Date to, final int rate) throws Exception {
        // create the client
        HistoryClient client = new HistoryClient("samples", "0", dataset);

        // streaming historical OHLCs is a three step process
        //  1. open the stream on the server side
        //  2. use the information returned by the server to open the stream on the client side
        //  3. start the stream
        // the maximum time lapse between the time the server opens the stream and the stream is
        // opened on the client is returned by the server. a stream error will be surfaced if
        // the stream is not opened on the client side within the allotted time

        // step 1: open the stream on the server side
        OpenHistoricalStocksOHLCStreamRequestMessage request = OpenHistoricalStocksOHLCStreamRequestMessage.create();
        request.setFrequency(OHLCFrequency.Minute);
        request.setSymbol(symbol);
        request.setFromAsTimestamp(from.getTime());
        request.setToAsTimestamp(to.getTime());
        OpenHistoricalStocksOHLCStreamResponseMessage response = client.openHistoricalOHLCStream(request);

        // step 2: unpack the response and open the stream on the client side
        long streamId = response.getStreamId();
        String connectionDescriptor = response.getStreamConnectionDescriptor();
        response.dispose();
        HistoricalOHLCStream stream = client.openStream(streamId, connectionDescriptor, this);

        // step 3: start the stream
        stream.start(rate);

        // wait for stream to be done
        synchronized(this) {
            while (!_done) {
                wait();
            }
        }

        // close the stream
        stream.close();

        // close the client
        client.close();
    }

    /**
     * This method handles the "Stream start" message i.e. the message sent by
     * the server as the first message of a stream to indicate the start of the
     * stream
     */
    @EventHandler
    final public void onStreamStart(final HistoricalOHLCStreamStartMessage message) {
        System.out.println(System.currentTimeMillis() + ": Stream " + message.getStreamId() + " has started");
    }

    /**
     * This method handles the "Stream data" message i.e. the a data message
     * containing the OHLC data
     */
    @EventHandler
    final public void onStreamData(final StocksMinuteOHLCMessage message) {
        _ohlcPopulator.populate(_ohlc, message);
    }

    /**
     * This method handles the "Stream end" message i.e. the message sent by
     * the server as the last message of a stream to indicate the end of the
     * stream
     */
    @EventHandler
    final public void onStreamEnd(final HistoricalOHLCStreamEndMessage message) {
        System.out.println(System.currentTimeMillis() + ": Stream  " + message.getStreamId() + " has ended (count=" + message.getCount() + ")");
        synchronized(this) {
            _done = true;
            notifyAll();
        }
    }

    @EventHandler
    final public void onStreamError(final HistoricalOHLCStreamErrorMessage message) {
        System.out.println(System.currentTimeMillis() + ": Stream has encountered an error [" + message.getError() + "]");
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolOption = parser.addStringOption('s', "symbol");
        final CmdLineParser.Option fromOption = parser.addStringOption('f', "from");
        final CmdLineParser.Option toOption = parser.addStringOption('t', "to");
        final CmdLineParser.Option rateOption = parser.addIntegerOption('r', "rate");
        final CmdLineParser.Option datasetOption = parser.addStringOption('D', "dataset");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbol
            final String symbol = (String)parser.getOptionValue(symbolOption, null);
            // ...from
            final String fromStr = (String)parser.getOptionValue(fromOption, null);
            if (fromStr == null) printUsage();
            final SimpleDateFormat fromDateFormat = dateFormat();
            Date from = null;
            if (fromStr != null) {
                try {
                    from = fromDateFormat.parse(fromStr);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    printUsage();
                }
            }
            // ...to
            final String toStr = (String)parser.getOptionValue(toOption, null);
            if (toStr == null) printUsage();
            final SimpleDateFormat toDateFormat = dateFormat();
            Date to = null;
            if (toStr != null) {
                try {
                    to = toDateFormat.parse(toStr);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    printUsage();
                }
            }

            // ...rate
            final int rate = (Integer)parser.getOptionValue(rateOption, 0);

            // ...dataset
            final String dataset = (String)parser.getOptionValue(datasetOption, "Synthetic");

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: " + dataset);
            System.out.println("...Symbol: " + symbol);
            System.out.println("...From: " + fromStr);
            System.out.println("...To: " + toStr);
            System.out.println("...Rate: " + rate);
            System.out.println("}");

            // execute
            new StreamHistoricalOHLC().run(dataset, symbol, from, to, rate);
        }
        else {
            printUsage();
        }
    }
}
