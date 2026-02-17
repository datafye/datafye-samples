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
package com.datafye.samples.rest;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.TimeZone;
import java.util.concurrent.TimeUnit;

import jargs.gnu.CmdLineParser;

import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.neeve.config.Config;

import com.datafye.samples.rest.domain.*;

public class GetHistoricalCandles {
    final private static void printUsage() {
        System.err.println("    [{-s, --symbol the symbol to fetch the candles for (required)]");
        System.err.println("    [{-c, --frequency the candle frequency to fetch for]");
        System.err.println("    [{-f, --from the lower bound of the time window to fetch candles for (format=YYYY-MM-DDTHH:mm:ss)]");
        System.err.println("    [{-t, --to the upper bound of the time window to fetch candles for (format=YYYY-MM-DDTHH:mm:ss))]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private static void run(final String symbol, final String frequency, final Date from, final Date to) throws Exception {
        // create client and response mapper
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
        final ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        // perform 100 fetches
        long totalTime = 0;
        long totalCount = 0;
        for (int i = 0 ; i < 100 ; i++) {
            long start = System.currentTimeMillis();
            HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/stocks/history/ohlc").newBuilder();
            urlBuilder.addQueryParameter("dataset", "Synthetic");
            urlBuilder.addQueryParameter("frequency", frequency);
            urlBuilder.addQueryParameter("symbols", symbol);
            urlBuilder.addQueryParameter("from", dateFormat().format(from));
            urlBuilder.addQueryParameter("to", dateFormat().format(to));
            Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
            Response response = webClient.newCall(request).execute();
            GetHistoricalCandlesResponse candlesResponse = objectMapper.readValue(response.body().string(), GetHistoricalCandlesResponse.class);
            long stop = System.currentTimeMillis();

            // update totals
            totalTime += (stop-start);
            totalCount += candlesResponse.getCandles() != null ? candlesResponse.getCandles().length : 0;
        }

        // average time
        System.out.println("Fetched '" + (totalCount/100) + "' candles for '" + symbol + "' in " + (totalTime/100) + " milliseconds.");
    }

    public static void main(String args[]) throws Exception {
        // set default Rumi trace level
        System.setProperty("nv.trace.defaultLevel", "warn");

        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolOption = parser.addStringOption('s', "symbol");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option fromOption = parser.addStringOption('f', "from");
        final CmdLineParser.Option toOption = parser.addStringOption('t', "to");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbol
            final String symbol = (String)parser.getOptionValue(symbolOption, null);
            if (symbol == null) printUsage();
            // ...frequency
            final String frequency = (String)parser.getOptionValue(frequencyOption, "Minute");
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

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Symbol: " + symbol);
            System.out.println("...Frequency: " + frequency);
            System.out.println("...From: " + fromStr);
            System.out.println("...To: " + toStr);
            System.out.println("}");

            // execute
            run(symbol, frequency, from, to);
        }
        else {
            printUsage();
        }
    }
}
