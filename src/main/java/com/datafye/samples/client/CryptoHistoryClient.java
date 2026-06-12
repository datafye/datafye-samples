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
 * Crypto HistoryClient adapter.
 *
 * Wraps the Crypto HistoryClient. Crypto is a single dataset, so unlike the
 * dataset-agnostic stocks adapter this takes no dataset parameter.
 *
 * For streaming, use {@link #openHistoricalOHLCStream} to open a stream on
 * the server side, then {@link #openStream} to open it on the client side.
 * The returned {@link HistoricalOHLCStream} wraps the Crypto Stream.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class CryptoHistoryClient {
    private final com.datafye.client.crypto.HistoryClient cryptoClient;

    public CryptoHistoryClient(String name, String id) {
        System.setProperty("datafye-crypto-history.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-history");
        System.setProperty("datafye-crypto-history.stream." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55554&client_name=" + name + "-history-stream");

        cryptoClient = new com.datafye.client.crypto.HistoryClient(name, id);
    }

    // --- Historical queries ---

    public GetHistoricalCryptoOHLCsResponseMessage getHistoricalOHLCs(GetHistoricalCryptoOHLCsRequestMessage request) {
        return cryptoClient.getHistoricalOHLCs(request);
    }

    public GetTopGainerCryptoResponseMessage getTopGainers(GetTopGainerCryptoRequestMessage request) {
        return cryptoClient.getTopGainers(request);
    }

    // --- OHLC history fetch (download) ---

    public StartCryptoSecondOHLCHistoryFetchResponseMessage startSecondOHLCHistoryFetch(StartCryptoSecondOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.startSecondOHLCHistoryFetch(request);
    }

    public StartCryptoMinuteOHLCHistoryFetchResponseMessage startMinuteOHLCHistoryFetch(StartCryptoMinuteOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.startMinuteOHLCHistoryFetch(request);
    }

    public StartCryptoHourOHLCHistoryFetchResponseMessage startHourOHLCHistoryFetch(StartCryptoHourOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.startHourOHLCHistoryFetch(request);
    }

    public StartCryptoDayOHLCHistoryFetchResponseMessage startDayOHLCHistoryFetch(StartCryptoDayOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.startDayOHLCHistoryFetch(request);
    }

    public IsCryptoSecondOHLCHistoryFetchRunningResponseMessage isSecondOHLCHistoryFetchRunning(IsCryptoSecondOHLCHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isSecondOHLCHistoryFetchRunning(request);
    }

    public IsCryptoMinuteOHLCHistoryFetchRunningResponseMessage isMinuteOHLCHistoryFetchRunning(IsCryptoMinuteOHLCHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isMinuteOHLCHistoryFetchRunning(request);
    }

    public IsCryptoHourOHLCHistoryFetchRunningResponseMessage isHourOHLCHistoryFetchRunning(IsCryptoHourOHLCHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isHourOHLCHistoryFetchRunning(request);
    }

    public IsCryptoDayOHLCHistoryFetchRunningResponseMessage isDayOHLCHistoryFetchRunning(IsCryptoDayOHLCHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isDayOHLCHistoryFetchRunning(request);
    }

    public CancelCryptoSecondOHLCHistoryFetchResponseMessage cancelSecondOHLCHistoryFetch(CancelCryptoSecondOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.cancelSecondOHLCHistoryFetch(request);
    }

    public CancelCryptoMinuteOHLCHistoryFetchResponseMessage cancelMinuteOHLCHistoryFetch(CancelCryptoMinuteOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.cancelMinuteOHLCHistoryFetch(request);
    }

    public CancelCryptoHourOHLCHistoryFetchResponseMessage cancelHourOHLCHistoryFetch(CancelCryptoHourOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.cancelHourOHLCHistoryFetch(request);
    }

    public CancelCryptoDayOHLCHistoryFetchResponseMessage cancelDayOHLCHistoryFetch(CancelCryptoDayOHLCHistoryFetchRequestMessage request) {
        return cryptoClient.cancelDayOHLCHistoryFetch(request);
    }

    // --- Tick history fetch (download) ---

    public StartCryptoTickHistoryFetchResponseMessage startTickHistoryFetch(StartCryptoTickHistoryFetchRequestMessage request) {
        return cryptoClient.startTickHistoryFetch(request);
    }

    public IsCryptoTickHistoryFetchRunningResponseMessage isTickHistoryFetchRunning(IsCryptoTickHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isTickHistoryFetchRunning(request);
    }

    public CancelCryptoTickHistoryFetchResponseMessage cancelTickHistoryFetch(CancelCryptoTickHistoryFetchRequestMessage request) {
        return cryptoClient.cancelTickHistoryFetch(request);
    }

    // --- Trade history fetch (download) ---

    public StartCryptoTradeHistoryFetchResponseMessage startTradeHistoryFetch(StartCryptoTradeHistoryFetchRequestMessage request) {
        return cryptoClient.startTradeHistoryFetch(request);
    }

    public IsCryptoTradeHistoryFetchRunningResponseMessage isTradeHistoryFetchRunning(IsCryptoTradeHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isTradeHistoryFetchRunning(request);
    }

    public CancelCryptoTradeHistoryFetchResponseMessage cancelTradeHistoryFetch(CancelCryptoTradeHistoryFetchRequestMessage request) {
        return cryptoClient.cancelTradeHistoryFetch(request);
    }

    // --- Quote history fetch (download) ---

    public StartCryptoQuoteHistoryFetchResponseMessage startQuoteHistoryFetch(StartCryptoQuoteHistoryFetchRequestMessage request) {
        return cryptoClient.startQuoteHistoryFetch(request);
    }

    public IsCryptoQuoteHistoryFetchRunningResponseMessage isQuoteHistoryFetchRunning(IsCryptoQuoteHistoryFetchRunningRequestMessage request) {
        return cryptoClient.isQuoteHistoryFetchRunning(request);
    }

    public CancelCryptoQuoteHistoryFetchResponseMessage cancelQuoteHistoryFetch(CancelCryptoQuoteHistoryFetchRequestMessage request) {
        return cryptoClient.cancelQuoteHistoryFetch(request);
    }

    // --- Streaming ---

    public OpenHistoricalCryptoOHLCStreamResponseMessage openHistoricalOHLCStream(OpenHistoricalCryptoOHLCStreamRequestMessage request) {
        return cryptoClient.openHistoricalOHLCStream(request);
    }

    /**
     * Opens a stream on the client side. Returns a {@link HistoricalOHLCStream}
     * wrapper that provides {@code start()} and {@code close()}.
     */
    public HistoricalOHLCStream openStream(long streamId, String connectionDescriptor, Object handler) throws Exception {
        return new HistoricalOHLCStream(cryptoClient.openStream(streamId, connectionDescriptor, handler));
    }

    // --- Lifecycle ---

    public void close() {
        cryptoClient.close();
    }

    // --- Stream wrapper ---

    public static class HistoricalOHLCStream {
        private final com.datafye.crypto.history.Client.Stream cryptoStream;

        HistoricalOHLCStream(com.datafye.crypto.history.Client.Stream stream) {
            this.cryptoStream = stream;
        }

        public void start(int rate) throws Exception {
            cryptoStream.start(rate);
        }

        public void close() throws Exception {
            cryptoStream.close();
        }
    }
}
