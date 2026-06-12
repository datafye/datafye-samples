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
 * Crypto ReferenceClient adapter.
 *
 * Wraps the Crypto ReferenceClient. Crypto is a single dataset, so unlike
 * the dataset-agnostic stocks adapter this takes no dataset parameter.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class CryptoReferenceClient {
    private final com.datafye.client.crypto.ReferenceClient cryptoClient;

    public CryptoReferenceClient(String name, String id) {
        System.setProperty("datafye-crypto-reference.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-reference");

        cryptoClient = new com.datafye.client.crypto.ReferenceClient(name, id);
    }

    public GetCryptoSecurityMasterResponseMessage getSecurityMaster(GetCryptoSecurityMasterRequestMessage request) {
        return cryptoClient.getSecurityMaster(request);
    }

    public void close() {
        cryptoClient.close();
    }
}
