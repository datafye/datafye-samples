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
package com.datafye.samples.rest.backtest;

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

import com.datafye.samples.rest.domain.*;

public class StartOHLCDownload {
    static {
        System.setProperty("datafye-samples.api.endpoint", "api.rest.rumi.local:7776");
    }

    final private static void printUsage() {
        System.err.println("    [{-d, --date the date to download OHLC history for (format=YYYY-MM-DD) (required)]");
        System.err.println("    [{-s, --symbols the symbols (comma separated) to download OHLC history for (optional)]");
        System.err.println("    [{-c, --frequency the OHLC frequency (Second, Minute, Hour, Day) (default=Minute)]");
        System.err.println("    [{-w, --wait wait for download to complete]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run(final String date, final String symbols, final String frequency, final boolean wait) throws Exception {
        // create client and response mapper
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
        final ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        // build JSON request body
        StringBuilder json = new StringBuilder("{");
        json.append("\"dataset\":\"Synthetic\"");
        json.append(",\"date\":\"").append(date).append("\"");
        json.append(",\"frequency\":\"").append(frequency).append("\"");
        json.append(",\"numDays\":1");
        json.append(",\"adjusted\":false");
        if (symbols != null) json.append(",\"symbols\":\"").append(symbols).append("\"");
        json.append("}");

        // start the download
        HttpUrl url = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/stocks/backtest/history/ohlcs");
        Request request = new Request.Builder().url(url)
            .addHeader("Accept", "application/json")
            .addHeader("Content-Type", "application/json")
            .post(RequestBody.create(json.toString(), MediaType.parse("application/json")))
            .build();
        Response response = webClient.newCall(request).execute();
        StatusResponse statusResponse = objectMapper.readValue(response.body().string(), StatusResponse.class);

        if (statusResponse.getStatus() != null) {
            System.out.println("Error: " + statusResponse.getStatus());
            return;
        }

        System.out.println(frequency + " OHLC history download started successfully.");

        // wait for completion if requested
        if (wait) {
            long startTime = System.currentTimeMillis();
            while (true) {
                Thread.sleep(5000);
                long elapsed = (System.currentTimeMillis() - startTime) / 1000;
                System.out.println("Downloading " + frequency + " OHLC history... (" + elapsed + "s elapsed)");

                HttpUrl.Builder statusUrlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/stocks/backtest/history/ohlcs").newBuilder();
                statusUrlBuilder.addQueryParameter("dataset", "Synthetic");
                statusUrlBuilder.addQueryParameter("frequency", frequency);
                Request statusRequest = new Request.Builder().url(statusUrlBuilder.build().toString()).addHeader("Accept", "application/json").build();
                Response statusResp = webClient.newCall(statusRequest).execute();
                IsRunningResponse isRunningResponse = objectMapper.readValue(statusResp.body().string(), IsRunningResponse.class);

                if (!Boolean.TRUE.equals(isRunningResponse.getIsRunning())) {
                    System.out.println(frequency + " OHLC history download completed. (" + elapsed + "s)");
                    break;
                }
            }
        }
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option dateOption = parser.addStringOption('d', "date");
        final CmdLineParser.Option symbolsOption = parser.addStringOption('s', "symbols");
        final CmdLineParser.Option frequencyOption = parser.addStringOption('c', "frequency");
        final CmdLineParser.Option waitOption = parser.addBooleanOption('w', "wait");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // parse and validate parameters
            final String date = (String)parser.getOptionValue(dateOption, null);
            if (date == null) printUsage();
            final String symbols = (String)parser.getOptionValue(symbolsOption, null);
            final String frequency = (String)parser.getOptionValue(frequencyOption, "Minute");
            final boolean wait = (Boolean)parser.getOptionValue(waitOption, false);

            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: Synthetic");
            System.out.println("...Date: " + date);
            System.out.println("...Symbols: " + (symbols != null ? symbols : "(all)"));
            System.out.println("...Frequency: " + frequency);
            System.out.println("...Wait: " + wait);
            System.out.println("}");

            // execute
            run(date, symbols, frequency, wait);
        }
        else {
            printUsage();
        }
    }
}
