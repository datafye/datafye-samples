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
package com.datafye.samples.rest.health;

import java.util.concurrent.TimeUnit;

import jargs.gnu.CmdLineParser;

import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import com.neeve.config.Config;

/**
 * Pings a Datafye Deployment to check health.
 *
 * The scope of the ping is controlled by optional parameters:
 *   - No parameters: pings all systems in the deployment
 *   - dataset: pings all services in that dataset
 *   - dataset + service: pings a specific service within a dataset
 *   - system: pings a specific system by name
 *
 * Note: dataset and system are mutually exclusive.
 */
public class Ping {
    static {
        System.setProperty("datafye-samples.api.endpoint", "api.rest.rumi.local:7776");
    }

    final private static void printUsage() {
        System.err.println("    [{-d, --dataset} dataset to ping (e.g. Synthetic, SIP, Crypto)]");
        System.err.println("    [{-v, --service} service within dataset (e.g. Reference, Feed, Agg, History)]");
        System.err.println("    [{-y, --system} system name to ping (e.g. datafye-synthetic-system)]");
        System.err.println("    [{-h, --help} print this help string]");
        System.exit(-1);
    }

    final private static void run(final String dataset, final String service, final String system) throws Exception {
        final OkHttpClient webClient = new OkHttpClient.Builder().readTimeout(300, TimeUnit.SECONDS).build();

        HttpUrl.Builder urlBuilder = HttpUrl.parse("http://" + Config.getValue("datafye-samples.api.endpoint") + "/datafye-api/v1/health/ping").newBuilder();
        if (dataset != null) urlBuilder.addQueryParameter("dataset", dataset);
        if (service != null) urlBuilder.addQueryParameter("service", service);
        if (system != null) urlBuilder.addQueryParameter("system", system);
        Request request = new Request.Builder().url(urlBuilder.build().toString()).addHeader("Accept", "application/json").build();
        Response response = webClient.newCall(request).execute();

        System.out.println("HTTP " + response.code());
        System.out.println(response.body().string());
    }

    public static void main(String args[]) throws Exception {
        final CmdLineParser parser = new CmdLineParser();
        final CmdLineParser.Option datasetOption = parser.addStringOption('d', "dataset");
        final CmdLineParser.Option serviceOption = parser.addStringOption('v', "service");
        final CmdLineParser.Option systemOption = parser.addStringOption('y', "system");
        final CmdLineParser.Option helpOption = parser.addBooleanOption('h', "help");

        parser.parse(args);
        if (!((Boolean)parser.getOptionValue(helpOption, false))) {
            final String dataset = (String)parser.getOptionValue(datasetOption);
            final String service = (String)parser.getOptionValue(serviceOption);
            final String system = (String)parser.getOptionValue(systemOption);

            System.out.println("Parameters {");
            if (dataset != null) System.out.println("...Dataset: " + dataset);
            if (service != null) System.out.println("...Service: " + service);
            if (system != null) System.out.println("...System: " + system);
            if (dataset == null && service == null && system == null) System.out.println("...(none — pinging entire deployment)");
            System.out.println("}");

            run(dataset, service, system);
        }
        else {
            printUsage();
        }
    }
}
