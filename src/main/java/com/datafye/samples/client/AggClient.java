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
 * Delegates to the SIP or Synthetic AggClient based on the dataset parameter.
 * In addition to the request-reply fetch operations, this adapter exposes the
 * live aggregate stream: openStream() then subscribeLive{OHLC,SMA,EMA}().
 *
 * Both the request-reply connection (Solace messaging backbone) and the live
 * stream connection (per-dataset agg-stream ether bus) default to the foundry's
 * host-published endpoints but can be overridden via the corresponding
 * "...connectionDescriptor" system property (-D) without rebuilding — useful
 * when running from inside the deployment network rather than the host.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class AggClient {
    private final com.datafye.client.synthetic.AggClient syntheticClient;
    private final com.datafye.client.sip.AggClient sipClient;

    private static void setIfAbsent(final String key, final String value) {
        if (System.getProperty(key) == null) System.setProperty(key, value);
    }

    public AggClient(String name, String id, String dataset) {
        final boolean sip = "SIP".equalsIgnoreCase(dataset);
        final String prefix = sip ? "datafye-sip" : "datafye-synthetic";
        final String etherHost = sip ? "sip" : "synthetic";
        final int aggStreamPort = sip ? 44470 : 44472;

        // request-reply over the messaging backbone (host port 55554 -> container 55555)
        setIfAbsent(prefix + "-agg.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-agg");
        // live aggregate stream over the agg-stream ether bus
        setIfAbsent(prefix + "-agg.stream." + name + ".connectionDescriptor",
            "ether://.&ifaddr=" + etherHost + ".agg.rumi.local&port=" + aggStreamPort + "&client_name=" + name + "-agg-stream");

        if (sip) {
            sipClient = new com.datafye.client.sip.AggClient(name, id);
            syntheticClient = null;
        } else {
            syntheticClient = new com.datafye.client.synthetic.AggClient(name, id);
            sipClient = null;
        }
    }

    // --- Fetch (request-reply) ---

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

    // --- Stream (subscription) ---

    public void openStream(Object handler) throws Exception {
        if (sipClient != null) sipClient.openStream(handler);
        else syntheticClient.openStream(handler);
    }

    public void closeStream() {
        if (sipClient != null) sipClient.closeStream();
        else syntheticClient.closeStream();
    }

    public SubscribeLiveStocksOHLCResponseMessage subscribeLiveOHLC(SubscribeLiveStocksOHLCRequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.subscribeLiveOHLC(request);
        return syntheticClient.subscribeLiveOHLC(request);
    }

    public UnsubscribeLiveStocksOHLCResponseMessage unsubscribeLiveOHLC(UnsubscribeLiveStocksOHLCRequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.unsubscribeLiveOHLC(request);
        return syntheticClient.unsubscribeLiveOHLC(request);
    }

    public SubscribeLiveSMAResponseMessage subscribeLiveSMA(SubscribeLiveSMARequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.subscribeLiveSMA(request);
        return syntheticClient.subscribeLiveSMA(request);
    }

    public UnsubscribeLiveSMAResponseMessage unsubscribeLiveSMA(UnsubscribeLiveSMARequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.unsubscribeLiveSMA(request);
        return syntheticClient.unsubscribeLiveSMA(request);
    }

    public SubscribeLiveEMAResponseMessage subscribeLiveEMA(SubscribeLiveEMARequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.subscribeLiveEMA(request);
        return syntheticClient.subscribeLiveEMA(request);
    }

    public UnsubscribeLiveEMAResponseMessage unsubscribeLiveEMA(UnsubscribeLiveEMARequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.unsubscribeLiveEMA(request);
        return syntheticClient.unsubscribeLiveEMA(request);
    }

    public void close() {
        if (sipClient != null) sipClient.close();
        if (syntheticClient != null) syntheticClient.close();
    }
}
