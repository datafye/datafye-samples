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
/**
 * Dataset-agnostic AggClient adapter.
 *
 * Delegates to the SIP or Synthetic AggClient based on the dataset
 * parameter. The underlying clients have identical APIs — this adapter
 * provides a single type that works with either dataset.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class AggClient {
    private final com.datafye.client.synthetic.AggClient syntheticClient;
    private final com.datafye.client.sip.AggClient sipClient;

    public AggClient(String name, String id, String dataset) {
        String prefix = "SIP".equalsIgnoreCase(dataset) ? "datafye-sip" : "datafye-synthetic";
        System.setProperty(prefix + "-agg.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-agg");

        if ("SIP".equalsIgnoreCase(dataset)) {
            sipClient = new com.datafye.client.sip.AggClient(name, id);
            syntheticClient = null;
        } else {
            syntheticClient = new com.datafye.client.synthetic.AggClient(name, id);
            sipClient = null;
        }
    }

    public GetLiveStocksOHLCsResponseMessage getLiveOHLCs(GetLiveStocksOHLCsRequestMessage request) {
        if (sipClient != null) return sipClient.getLiveOHLCs(request);
        return syntheticClient.getLiveOHLCs(request);
    }

    public GetLiveStocksSMAsResponseMessage getLiveSMAs(GetLiveStocksSMAsRequestMessage request) {
        if (sipClient != null) return sipClient.getLiveSMAs(request);
        return syntheticClient.getLiveSMAs(request);
    }

    public GetLiveStocksEMAsResponseMessage getLiveEMAs(GetLiveStocksEMAsRequestMessage request) {
        if (sipClient != null) return sipClient.getLiveEMAs(request);
        return syntheticClient.getLiveEMAs(request);
    }

    public void close() {
        if (sipClient != null) sipClient.close();
        if (syntheticClient != null) syntheticClient.close();
    }
}
