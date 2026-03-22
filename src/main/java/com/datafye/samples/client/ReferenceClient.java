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
 * Dataset-agnostic ReferenceClient adapter.
 *
 * Delegates to the SIP or Synthetic ReferenceClient based on the dataset
 * parameter. The underlying clients have identical APIs — this adapter
 * provides a single type that works with either dataset.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class ReferenceClient {
    private final com.datafye.client.synthetic.ReferenceClient syntheticClient;
    private final com.datafye.client.sip.ReferenceClient sipClient;

    public ReferenceClient(String name, String id, String dataset) {
        String prefix = "SIP".equalsIgnoreCase(dataset) ? "datafye-sip" : "datafye-synthetic";
        System.setProperty(prefix + "-reference.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-reference");

        if ("SIP".equalsIgnoreCase(dataset)) {
            sipClient = new com.datafye.client.sip.ReferenceClient(name, id);
            syntheticClient = null;
        } else {
            syntheticClient = new com.datafye.client.synthetic.ReferenceClient(name, id);
            sipClient = null;
        }
    }

    public GetStocksSecurityMasterResponseMessage getSecurityMaster(GetStocksSecurityMasterRequestMessage request) {
        if (sipClient != null) return sipClient.getSecurityMaster(request);
        return syntheticClient.getSecurityMaster(request);
    }

    public void close() {
        if (sipClient != null) sipClient.close();
        if (syntheticClient != null) syntheticClient.close();
    }
}
