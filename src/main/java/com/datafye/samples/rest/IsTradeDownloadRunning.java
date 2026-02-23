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

public class IsTradeDownloadRunning {
    static {
        System.setProperty("datafye-samples.api.endpoint", "api.rest.rumi.local:7776");
    }

    final private static void printUsage() {
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run() throws Exception {
        // create client and response mapper
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();
        final ObjectMapper objectMapper = new ObjectMapper();
        objectMapper.configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

        // check if download is running
        HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/backtest/history/trades/fetch/status").newBuilder();
        urlBuilder.addQueryParameter("dataset", "Synthetic");
        Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
        Response response = webClient.newCall(request).execute();
        IsRunningResponse isRunningResponse = objectMapper.readValue(response.body().string(), IsRunningResponse.class);

        System.out.println("Trade history download is running: " + isRunningResponse.getIsRunning());
    }

    public static void main(String args[]) throws Exception {
        // parse command line
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            // dump parameters
            System.out.println("Parameters {");
            System.out.println("...Dataset: Synthetic");
            System.out.println("}");

            // execute
            run();
        }
        else {
            printUsage();
        }
    }
}
