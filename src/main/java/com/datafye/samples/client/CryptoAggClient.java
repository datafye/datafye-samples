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
 * Crypto AggClient adapter.
 *
 * Wraps the Crypto AggClient. Crypto is a single dataset, so unlike the
 * dataset-agnostic stocks adapter this takes no dataset parameter. In addition
 * to the request-reply fetch operations, this adapter exposes the live
 * aggregate stream: openStream() then subscribeLive{OHLC,SMA,EMA}().
 *
 * Both the request-reply and the agg-stream connection descriptors default to
 * the foundry's host-published endpoints and can be overridden via the
 * corresponding "...connectionDescriptor" system property (-D).
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class CryptoAggClient {
    private final com.datafye.client.crypto.AggClient cryptoClient;

    private static void setIfAbsent(final String key, final String value) {
        if (System.getProperty(key) == null) System.setProperty(key, value);
    }

    public CryptoAggClient(String name, String id) {
        // request-reply over the messaging backbone (host port 55554 -> container 55555)
        setIfAbsent("datafye-crypto-agg.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-agg");
        // live aggregate stream over the crypto agg-stream ether bus
        setIfAbsent("datafye-crypto-agg.stream." + name + ".connectionDescriptor",
            "ether://.&ifaddr=crypto.agg.rumi.local&port=44471&client_name=" + name + "-agg-stream");

        cryptoClient = new com.datafye.client.crypto.AggClient(name, id);
    }

    // --- Fetch (request-reply) ---

    public GetLiveCryptoOHLCsResponseMessage getLiveOHLCs(GetLiveCryptoOHLCsRequestMessage request) {
        return cryptoClient.getLiveOHLCs(request);
    }

    public GetLiveCryptoSMAsResponseMessage getLiveSMAs(GetLiveCryptoSMAsRequestMessage request) {
        return cryptoClient.getLiveSMAs(request);
    }

    public GetLiveCryptoEMAsResponseMessage getLiveEMAs(GetLiveCryptoEMAsRequestMessage request) {
        return cryptoClient.getLiveEMAs(request);
    }

    // --- Stream (subscription) ---

    public void openStream(Object handler) throws Exception {
        cryptoClient.openStream(handler);
    }

    public void closeStream() {
        cryptoClient.closeStream();
    }

    public SubscribeLiveCryptoOHLCResponseMessage subscribeLiveOHLC(SubscribeLiveCryptoOHLCRequestMessage request) throws Exception {
        return cryptoClient.subscribeLiveOHLC(request);
    }

    public UnsubscribeLiveCryptoOHLCResponseMessage unsubscribeLiveOHLC(UnsubscribeLiveCryptoOHLCRequestMessage request) throws Exception {
        return cryptoClient.unsubscribeLiveOHLC(request);
    }

    public SubscribeLiveSMAResponseMessage subscribeLiveSMA(SubscribeLiveSMARequestMessage request) throws Exception {
        return cryptoClient.subscribeLiveSMA(request);
    }

    public UnsubscribeLiveSMAResponseMessage unsubscribeLiveSMA(UnsubscribeLiveSMARequestMessage request) throws Exception {
        return cryptoClient.unsubscribeLiveSMA(request);
    }

    public SubscribeLiveEMAResponseMessage subscribeLiveEMA(SubscribeLiveEMARequestMessage request) throws Exception {
        return cryptoClient.subscribeLiveEMA(request);
    }

    public UnsubscribeLiveEMAResponseMessage unsubscribeLiveEMA(UnsubscribeLiveEMARequestMessage request) throws Exception {
        return cryptoClient.unsubscribeLiveEMA(request);
    }

    public void close() {
        cryptoClient.close();
    }
}
