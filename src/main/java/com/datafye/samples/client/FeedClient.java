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
 * Dataset-agnostic FeedClient adapter.
 *
 * Delegates to the SIP or Synthetic FeedClient based on the dataset
 * parameter. The underlying clients have identical APIs — this adapter
 * provides a single type that works with either dataset.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class FeedClient {
    private final com.datafye.client.synthetic.FeedClient syntheticClient;
    private final com.datafye.client.sip.FeedClient sipClient;

    public FeedClient(String name, String id, String dataset) {
        String prefix = "SIP".equalsIgnoreCase(dataset) ? "datafye-sip" : "datafye-synthetic";
        System.setProperty(prefix + "-feed.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=" + name + "-feed");
        System.setProperty(prefix + "-feed.stream." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=" + name + "-feed-stream");

        if ("SIP".equalsIgnoreCase(dataset)) {
            sipClient = new com.datafye.client.sip.FeedClient(name, id);
            syntheticClient = null;
        } else {
            syntheticClient = new com.datafye.client.synthetic.FeedClient(name, id);
            sipClient = null;
        }
    }

    // --- Live ticks ---

    public GetLiveLastStocksTradesResponseMessage getLiveLastTrades(GetLiveLastStocksTradesRequestMessage request) {
        if (sipClient != null) return sipClient.getLiveLastTrades(request);
        return syntheticClient.getLiveLastTrades(request);
    }

    public GetLiveTopOfBookStocksQuotesResponseMessage getLiveTopOfBookQuotes(GetLiveTopOfBookStocksQuotesRequestMessage request) {
        if (sipClient != null) return sipClient.getLiveTopOfBookQuotes(request);
        return syntheticClient.getLiveTopOfBookQuotes(request);
    }

    // --- Subscriptions ---

    public SubscribeLiveStocksTradesResponseMessage subscribeLiveTrades(SubscribeLiveStocksTradesRequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.subscribeLiveTrades(request);
        return syntheticClient.subscribeLiveTrades(request);
    }

    public UnsubscribeLiveStocksTradesResponseMessage unsubscribeLiveTrades(UnsubscribeLiveStocksTradesRequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.unsubscribeLiveTrades(request);
        return syntheticClient.unsubscribeLiveTrades(request);
    }

    public SubscribeLiveTopOfBookStocksQuotesResponseMessage subscribeLiveTopOfBookQuotes(SubscribeLiveTopOfBookStocksQuotesRequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.subscribeLiveTopOfBookQuotes(request);
        return syntheticClient.subscribeLiveTopOfBookQuotes(request);
    }

    public UnsubscribeLiveTopOfBookStocksQuotesResponseMessage unsubscribeLiveTopOfBookQuotes(UnsubscribeLiveTopOfBookStocksQuotesRequestMessage request) throws Exception {
        if (sipClient != null) return sipClient.unsubscribeLiveTopOfBookQuotes(request);
        return syntheticClient.unsubscribeLiveTopOfBookQuotes(request);
    }

    // --- Stream ---

    public void openStream(Object handler) throws Exception {
        if (sipClient != null) sipClient.openStream(handler);
        else syntheticClient.openStream(handler);
    }

    public void closeStream() throws Exception {
        if (sipClient != null) sipClient.closeStream();
        else syntheticClient.closeStream();
    }

    // --- Replay ---

    public StartHistoricalStocksTickReplayResponseMessage startHistoricalTickReplay(StartHistoricalStocksTickReplayRequestMessage request) {
        if (sipClient != null) return sipClient.startHistoricalTickReplay(request);
        return syntheticClient.startHistoricalTickReplay(request);
    }

    public IsHistoricalStocksTickReplayRunningResponsetMessage isHistoricalTickReplayRunning(IsHistoricalStocksTickReplayRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isHistoricalTickReplayRunning(request);
        return syntheticClient.isHistoricalTickReplayRunning(request);
    }

    public StopHistoricalStocksTickReplayResponseMessage stopHistoricalTickReplay(StopHistoricalStocksTickReplayRequestMessage request) {
        if (sipClient != null) return sipClient.stopHistoricalTickReplay(request);
        return syntheticClient.stopHistoricalTickReplay(request);
    }

    // --- Lifecycle ---

    public void close() {
        if (sipClient != null) sipClient.close();
        if (syntheticClient != null) syntheticClient.close();
    }
}
