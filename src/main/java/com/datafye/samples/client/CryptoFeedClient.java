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
 * Crypto FeedClient adapter.
 *
 * Wraps the Crypto FeedClient. Crypto is a single dataset, so unlike the
 * dataset-agnostic stocks adapter this takes no dataset parameter.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class CryptoFeedClient {
    private final com.datafye.client.crypto.FeedClient cryptoClient;

    public CryptoFeedClient(String name, String id) {
        // request-reply over the messaging backbone (host port 55554 -> container 55555); overridable via -D
        if (System.getProperty("datafye-crypto-feed.client." + name + ".connectionDescriptor") == null)
            System.setProperty("datafye-crypto-feed.client." + name + ".connectionDescriptor",
                "solace://solace.rumi.local:55554&client_name=" + name + "-feed");
        // live tick/quote stream over the crypto feed-stream ether bus; overridable via -D
        if (System.getProperty("datafye-crypto-feed.stream." + name + ".connectionDescriptor") == null)
            System.setProperty("datafye-crypto-feed.stream." + name + ".connectionDescriptor",
                "ether://.&ifaddr=crypto.feed.rumi.local&port=44447&client_name=" + name + "-feed-stream");

        cryptoClient = new com.datafye.client.crypto.FeedClient(name, id);
    }

    // --- Live ticks ---

    public GetLiveLastCryptoTradesResponseMessage getLiveLastTrades(GetLiveLastCryptoTradesRequestMessage request) {
        return cryptoClient.getLiveLastTrades(request);
    }

    public GetLiveTopOfBookCryptoQuotesResponseMessage getLiveTopOfBookQuotes(GetLiveTopOfBookCryptoQuotesRequestMessage request) {
        return cryptoClient.getLiveTopOfBookQuotes(request);
    }

    // --- Replay ---

    public StartHistoricalCryptoTickReplayResponseMessage startHistoricalTickReplay(StartHistoricalCryptoTickReplayRequestMessage request) {
        return cryptoClient.startHistoricalReplay(request);
    }

    public IsHistoricalCryptoTickReplayRunningResponsetMessage isHistoricalTickReplayRunning(IsHistoricalCryptoTickReplayRunningRequestMessage request) {
        return cryptoClient.isHistoricalReplayRunning(request);
    }

    public StopHistoricalCryptoTickReplayResponseMessage stopHistoricalTickReplay(StopHistoricalCryptoTickReplayRequestMessage request) {
        return cryptoClient.stopHistoricalReplay(request);
    }

    // --- Lifecycle ---

    public void close() {
        cryptoClient.close();
    }
}
