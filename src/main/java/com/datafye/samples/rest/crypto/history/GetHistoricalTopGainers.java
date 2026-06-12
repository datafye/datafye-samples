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
package com.datafye.samples.rest.crypto.history;

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

import com.datafye.samples.rest.domain.crypto.*;

public class GetHistoricalTopGainers {
    static {
        System.setProperty("datafye-samples.api.endpoint", "api.rest.rumi.local:7776");
    }

    final private static void printUsage() {
        System.err.println("    [{-d, --date the date to fetch top gainers for (format=YYYY-MM-DD) (required)]");
        System.err.println("    [{-g, --gainThreshold the threshold %% at or beyond which gainers are returned (required)]");
        System.err.println("    [{-m, --maxCount the maximum number of gainers to return (<=0 returns all) (default=0)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static SimpleDateFormat dateFormat() {
        final SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
        df.setTimeZone(TimeZone.getTimeZone("America/New_York"));
        return df;
    }

    final private static void run(final Date date, final double gainThreshold, final int maxCount) throws Exception {
        // create client and response mapper
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
        final ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        // perform 100 fetches
        long totalTime = 0;
        long totalCount = 0;
        for (int i = 0 ; i < 100 ; i++) {
            long start = System.currentTimeMillis();
            HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/crypto/history/top-gainers").newBuilder();
            urlBuilder.addQueryParameter("date", dateFormat().format(date));
            urlBuilder.addQueryParameter("gainThreshold", Double.toString(gainThreshold));
            urlBuilder.addQueryParameter("maxCount", Integer.toString(maxCount));
            Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
            Response response = webClient.newCall(request).execute();
            GetHistoricalCryptoTopGainersResponse gainersResponse = objectMapper.readValue(response.body().string(), GetHistoricalCryptoTopGainersResponse.class);
            long stop = System.currentTimeMillis();

            // update totals
            totalTime += (stop-start);
            totalCount += gainersResponse.getTopGainers() != null ? gainersResponse.getTopGainers().length : 0;
        }

        // average time
        System.out.println("Fetched '" + (totalCount/100) + "' top gainers in " + (totalTime/100) + " milliseconds.");
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option dateOption = parser.addStringOption('d', "date");
        final CmdLineParser.Option gainThresholdOption = parser.addDoubleOption('g', "gainThreshold");
        final CmdLineParser.Option maxCountOption = parser.addIntegerOption('m', "maxCount");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            // ...date
            final String dateStr = (String)parser.getOptionValue(dateOption, null);
            if (dateStr == null) printUsage();
            final SimpleDateFormat df = dateFormat();
            Date date = null;
            if (dateStr != null) {
                try {
                    date = df.parse(dateStr);
                }
                catch (Exception e) {
                    e.printStackTrace();
                    printUsage();
                }
            }
            // ...gainThreshold
            final Double gainThreshold = (Double)parser.getOptionValue(gainThresholdOption, null);
            if (gainThreshold == null) printUsage();
            // ...maxCount
            final int maxCount = (Integer)parser.getOptionValue(maxCountOption, 0);

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: Crypto");
            System.out.println("...Date: " + dateStr);
            System.out.println("...GainThreshold: " + gainThreshold);
            System.out.println("...MaxCount: " + maxCount);
            System.out.println("}");

            // execute
            run(date, gainThreshold != null ? gainThreshold : 0, maxCount);
        }
        else {
            printUsage();
        }
    }
}
