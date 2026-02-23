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

import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.TimeUnit;

import jargs.gnu.CmdLineParser;

import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import com.neeve.config.Config;

import com.datafye.samples.rest.domain.*;

public class GetLiveOHLCConcurrently {
    static {
        System.setProperty("datafye-samples.api.endpoint", "api.rest.rumi.local:7776");
    }

    final private static class Fetcher implements Runnable {
        final private Set<String> _symbols;

        Fetcher(Set<String> symbols) {
            _symbols = symbols;
        }

        @Override
        final public void run() {
            try {
                // create client and response mapper
                final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
                final ObjectMapper objectMapper = new ObjectMapper();
                objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

                // perform fetches
                long totalTime = 0;
                long totalCount = 0;
                for (String symbol: _symbols) {
                    long start = System.currentTimeMillis();
                    HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/stocks/live/agg/ohlc").newBuilder();
                    urlBuilder.addQueryParameter("dataset", "Synthetic");
                    urlBuilder.addQueryParameter("frequency", "Minute");
                    urlBuilder.addQueryParameter("symbol", symbol);
                    Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
                    Response response = webClient.newCall(request).execute();
                    GetLiveOHLCResponse ohlcResponse = objectMapper.readValue(response.body().string(), GetLiveOHLCResponse.class);
                    long stop = System.currentTimeMillis();

                    // update totals
                    totalTime += (stop-start);
                    totalCount += ohlcResponse.getCandles() != null ? ohlcResponse.getCandles().length : 0;
                }

                // total time
                System.out.println("Fetched '" + totalCount + "' OHLC bars for " + _symbols.size() + " symbols in " + totalTime + " milliseconds.");
            }
            catch (Throwable e) {
                e.printStackTrace();
            }
        }
    }

    final private static void printUsage() {
        System.err.println("    [{-c, --concurrency the concurrency factor (default=1)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static Set<String> getSymbols() throws Exception {
        // fetch symbols from the reference service via REST
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
        final ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/stocks/reference/securities").newBuilder();
        urlBuilder.addQueryParameter("dataset", "Synthetic");
        Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
        Response response = webClient.newCall(request).execute();

        final HashSet<String> ret = new HashSet<>();
        JsonNode root = objectMapper.readTree(response.body().string());
        JsonNode securities = root.get("securities");
        if (securities != null && securities.isArray()) {
            for (JsonNode security : securities) {
                JsonNode symbolNode = security.get("symbol");
                if (symbolNode != null) {
                    ret.add(symbolNode.asText());
                }
            }
        }
        System.out.println("Fetched '" + ret.size() + "' symbols.");
        return ret;
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option concurrencyOption = parser.addIntegerOption('c', "concurrency");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...concurrency
            final int concurrency = (Integer)parser.getOptionValue(concurrencyOption, 1);

            // get symbols
            final Set<String> symbols = getSymbols();

            // do concurrent fetch
            final Thread[] threads = new Thread[concurrency];
            for (int i = 0 ; i < concurrency ; i++) {
                (threads[i] = new Thread(new Fetcher(symbols))).start();
            }

            // wait
            for (int i = 0 ; i < concurrency ; i++) {
                threads[i].join();
            }
        }
        else {
            printUsage();
        }
    }
}
