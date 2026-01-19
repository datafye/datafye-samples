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

import okhttp3.HttpUrl;
import okhttp3.MediaType;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.RequestBody;
import okhttp3.Response;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.neeve.config.Config;

import com.nv.datafye.roe.*;

import com.datafye.gbpoc.client.domain.*;

public class GetLiveCandles {
    final private static void printUsage() {
        System.err.println("    [{-s, --symbol the symbol to fetch the candles for (required)]");
        System.err.println("    [{-j, --java use the Java client]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void runLiveREST(final String symbol) throws Exception {
        // create client and response mapper
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
        final ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        // perform 100 fetches
        long totalTime = 0;
        long totalCount = 0;
        for (int i = 0 ; i < 100 ; i++) {
            long start = System.currentTimeMillis();
            HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("gb-poc.datafye.ohlc.apiep") + "/datafye-ohlc-api/candles/live").newBuilder();
            urlBuilder.addQueryParameter("market", "SIP");
            urlBuilder.addQueryParameter("frequency", "Minute");
            urlBuilder.addQueryParameter("symbol", symbol);
            Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
            Response response = webClient.newCall(request).execute();
            GetLiveCandlesResponse candlesResponse = objectMapper.readValue(response.body().string(), GetLiveCandlesResponse.class);
            long stop = System.currentTimeMillis();

            // update totals
            totalTime += (stop-start);
            totalCount += candlesResponse.getCandles() != null ? candlesResponse.getCandles().length : 0;
        }

        // average time
        System.out.println("Fetched '" + (totalCount/100) + "' candles for '" + symbol + "' in " + (totalTime/100) + " milliseconds.");
    }

    final private static void runLiveJava(final String symbol) {
        // create the client
        com.datafye.ohlc.live.Client client = new com.datafye.ohlc.live.Client("gbpoc", "0");
        
        // perform 100 fetches
        long totalTime = 0;
        long totalCount = 0;
        for (int i = 0 ; i < 100 ; i++) {
            // run and benchmark
            long start = System.currentTimeMillis();
            GetLiveOHLCsRequestMessage request = GetLiveOHLCsRequestMessage.create();
            request.setMarket(Market.SIP);
            request.setFrequency(OHLCFrequency.Minute);
            request.setSymbol(symbol);
            GetLiveOHLCsResponseMessage response = client.getLiveOHLCs(request);
            final int candlesCount = response.getCandlesCount();
            long stop = System.currentTimeMillis();

            // update total
            totalTime += (stop-start);
            totalCount += candlesCount;

            // dispose the response
            response.dispose();
        }

        // average time
        System.out.println("Fetched '" + (totalCount/100) + "' candles for '" + symbol + "' in " + (totalTime/100) + " milliseconds.");
        
        // close the client
        client.close();
    }

    public static void main(String args[]) throws Exception {
        // set default Rumi trace level
        System.setProperty("nv.trace.defaultLevel", "warn");

        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option symbolOption = parser.addStringOption('s', "symbol");
        final CmdLineParser.Option javaOption = parser.addBooleanOption('j', "java");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...symbol
            final String symbol = (String)parser.getOptionValue(symbolOption, null);
            if (symbol == null) printUsage();
            // ...java or rest client?
            final boolean useJava = (Boolean)parser.getOptionValue(javaOption, false);

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Symbol: " + symbol);
            System.out.println("...Use Java Client: " + (useJava ? "yes" : "no"));
            System.out.println("}");

            // execute
            if (useJava) {
                runLiveJava(symbol);
            }
            else {
                runLiveREST(symbol);
            }
        }
        else {
            printUsage();
        }
    }
}
