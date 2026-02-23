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
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.TimeZone;

import jargs.gnu.CmdLineParser;

import com.neeve.aep.annotations.EventHandler;
import com.neeve.lang.XStringDeserializer;

import com.datafye.roe.*;
import com.datafye.client.sip.HistoryClient;
import com.datafye.sip.history.Client.Stream;

import com.datafye.samples.rest.domain.OHLC;

/**
 * Streams multiple historical OHLC streams concurrently using the SIP History client.
 *
 * Note: Streaming requires the SIP History client which provides
 * the Stream class and openStream method. The Synthetic History
 * client does not yet support streaming.
 */
public class StreamHistoricalOHLCConcurrently {
    static {
        System.setProperty("datafye-sip-history.client.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-sip-history");
        System.setProperty("datafye-sip-history.stream.samples.connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=samples-sip-history-stream");
    }

    final private static class Streamer implements Runnable {
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

        final private HistoryClient _client;
        final private Date _from;
        final private int _rate;
        final private OHLC _ohlc;
        final private OHLCPopulator _ohlcPopulator;
        final private GregorianCalendar _calendar;
        private boolean _done;

        Streamer(final HistoryClient client, final Date from, final int rate) {
            _client = client;
            _from = from;
            _rate = rate;
            _ohlc = new OHLC();
            _ohlcPopulator = new OHLCPopulator();
            _calendar = new GregorianCalendar(TimeZone.getTimeZone("America/New_York"));
        }

        final private OpenHistoricalStocksOHLCStreamResponseMessage openStream(final OpenHistoricalStocksOHLCStreamRequestMessage request) {
            synchronized(_client) {
                return _client.openHistoricalOHLCStream(request);
            }
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

        @Override
        final public void run() {
            try {
                // step 1: open the stream on the server side
                _calendar.clear();
                _calendar.setTime(_from);
                OpenHistoricalStocksOHLCStreamRequestMessage request = OpenHistoricalStocksOHLCStreamRequestMessage.create();
                request.setFrequency(OHLCFrequency.Minute);
                _calendar.set(Calendar.HOUR, 4);
                request.setFromAsTimestamp(_calendar.getTimeInMillis());
                _calendar.set(Calendar.HOUR, 20);
                request.setToAsTimestamp(_calendar.getTimeInMillis());
                OpenHistoricalStocksOHLCStreamResponseMessage response = openStream(request);

                // step 2: unpack the response and open the stream on the client side
                long streamId = response.getStreamId();
                String connectionDescriptor = response.getStreamConnectionDescriptor();
                response.dispose();
                Stream stream = _client.openStream(streamId, connectionDescriptor, this);

                // step 3: start the stream
                stream.start(_rate);

                // wait for stream to be done
                synchronized(this) {
                    while (!_done) {
                        wait();
                    }
                }

                // close the stream
                stream.close();
            }
            catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }

    final private static void printUsage() {
        System.err.println("    [{-i, --client instance id (default=0)]");
        System.err.println("    [{-f, --from the lower bound of the time window to fetch OHLC bars for (format=YYYY-MM-DD)]");
        System.err.println("    [{-r, --rate the maximum rate at which the server should stream the data)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option instanceOption = parser.addIntegerOption('i', "instance");
        final CmdLineParser.Option concurrencyOption = parser.addIntegerOption('c', "concurrency");
        final CmdLineParser.Option fromOption = parser.addStringOption('f', "from");
        final CmdLineParser.Option rateOption = parser.addIntegerOption('r', "rate");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...instance
            final int instance = (Integer)parser.getOptionValue(instanceOption, 0);

            // ...concurrency
            final int concurrency = (Integer)parser.getOptionValue(concurrencyOption, 1);

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

            // ...rate
            final int rate = (Integer)parser.getOptionValue(rateOption, 0);

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Instance: " + instance);
            System.out.println("...Concurrency: " + concurrency);
            System.out.println("...From: " + fromStr);
            System.out.println("...Rate: " + rate);
            System.out.println("}");

            // create the client
            final HistoryClient client = new HistoryClient("samples", String.valueOf(instance));

            // run the streams
            final Thread streamers[] = new Thread[concurrency];
            long ts = from.getTime();
            for (int i = 0 ; i < concurrency ; i++) {
                (streamers[i] = new Thread(new Streamer(client, new Date(ts), rate))).start();
                ts -= (24 * 3600 * 1000l);
            }

            // wait for streams to complete
            for (int i = 0 ; i < concurrency ; i++) {
                streamers[i].join();
            }

            // close the client
            client.close();
        }
        else {
            printUsage();
        }
    }
}
