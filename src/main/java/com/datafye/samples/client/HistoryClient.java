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
 * Dataset-agnostic HistoryClient adapter.
 *
 * Delegates to the SIP or Synthetic HistoryClient based on the dataset
 * parameter. The underlying clients have identical APIs — this adapter
 * provides a single type that works with either dataset.
 *
 * For streaming, use {@link #openHistoricalOHLCStream} to open a stream
 * on the server side, then {@link #openStream} to open it on the client
 * side. The returned {@link HistoricalOHLCStream} wraps the dataset-specific
 * Stream implementation.
 */
package com.datafye.samples.client;

import com.datafye.roe.*;

public class HistoryClient {
    private final com.datafye.client.synthetic.HistoryClient syntheticClient;
    private final com.datafye.client.sip.HistoryClient sipClient;

    public HistoryClient(String name, String id, String dataset) {
        String prefix = "SIP".equalsIgnoreCase(dataset) ? "datafye-sip" : "datafye-synthetic";
        System.setProperty(prefix + "-history.client." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=" + name + "-history");
        System.setProperty(prefix + "-history.stream." + name + ".connectionDescriptor",
            "solace://solace.rumi.local:55555&client_name=" + name + "-history-stream");

        if ("SIP".equalsIgnoreCase(dataset)) {
            sipClient = new com.datafye.client.sip.HistoryClient(name, id);
            syntheticClient = null;
        } else {
            syntheticClient = new com.datafye.client.synthetic.HistoryClient(name, id);
            sipClient = null;
        }
    }

    // --- Historical queries ---

    public GetHistoricalStocksOHLCsResponseMessage getHistoricalOHLCs(GetHistoricalStocksOHLCsRequestMessage request) {
        if (sipClient != null) return sipClient.getHistoricalOHLCs(request);
        return syntheticClient.getHistoricalOHLCs(request);
    }

    public GetTopGainerStocksResponseMessage getTopGainers(GetTopGainerStocksRequestMessage request) {
        if (sipClient != null) return sipClient.getTopGainers(request);
        return syntheticClient.getTopGainers(request);
    }

    // --- OHLC history fetch (download) ---

    public StartStocksSecondOHLCHistoryFetchResponseMessage startSecondOHLCHistoryFetch(StartStocksSecondOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startSecondOHLCHistoryFetch(request);
        return syntheticClient.startSecondOHLCHistoryFetch(request);
    }

    public StartStocksMinuteOHLCHistoryFetchResponseMessage startMinuteOHLCHistoryFetch(StartStocksMinuteOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startMinuteOHLCHistoryFetch(request);
        return syntheticClient.startMinuteOHLCHistoryFetch(request);
    }

    public StartStocksHourOHLCHistoryFetchResponseMessage startHourOHLCHistoryFetch(StartStocksHourOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startHourOHLCHistoryFetch(request);
        return syntheticClient.startHourOHLCHistoryFetch(request);
    }

    public StartStocksDayOHLCHistoryFetchResponseMessage startDayOHLCHistoryFetch(StartStocksDayOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startDayOHLCHistoryFetch(request);
        return syntheticClient.startDayOHLCHistoryFetch(request);
    }

    public IsStocksSecondOHLCHistoryFetchRunningResponseMessage isSecondOHLCHistoryFetchRunning(IsStocksSecondOHLCHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isSecondOHLCHistoryFetchRunning(request);
        return syntheticClient.isSecondOHLCHistoryFetchRunning(request);
    }

    public IsStocksMinuteOHLCHistoryFetchRunningResponseMessage isMinuteOHLCHistoryFetchRunning(IsStocksMinuteOHLCHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isMinuteOHLCHistoryFetchRunning(request);
        return syntheticClient.isMinuteOHLCHistoryFetchRunning(request);
    }

    public IsStocksHourOHLCHistoryFetchRunningResponseMessage isHourOHLCHistoryFetchRunning(IsStocksHourOHLCHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isHourOHLCHistoryFetchRunning(request);
        return syntheticClient.isHourOHLCHistoryFetchRunning(request);
    }

    public IsStocksDayOHLCHistoryFetchRunningResponseMessage isDayOHLCHistoryFetchRunning(IsStocksDayOHLCHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isDayOHLCHistoryFetchRunning(request);
        return syntheticClient.isDayOHLCHistoryFetchRunning(request);
    }

    public CancelStocksSecondOHLCHistoryFetchResponseMessage cancelSecondOHLCHistoryFetch(CancelStocksSecondOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelSecondOHLCHistoryFetch(request);
        return syntheticClient.cancelSecondOHLCHistoryFetch(request);
    }

    public CancelStocksMinuteOHLCHistoryFetchResponseMessage cancelMinuteOHLCHistoryFetch(CancelStocksMinuteOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelMinuteOHLCHistoryFetch(request);
        return syntheticClient.cancelMinuteOHLCHistoryFetch(request);
    }

    public CancelStocksHourOHLCHistoryFetchResponseMessage cancelHourOHLCHistoryFetch(CancelStocksHourOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelHourOHLCHistoryFetch(request);
        return syntheticClient.cancelHourOHLCHistoryFetch(request);
    }

    public CancelStocksDayOHLCHistoryFetchResponseMessage cancelDayOHLCHistoryFetch(CancelStocksDayOHLCHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelDayOHLCHistoryFetch(request);
        return syntheticClient.cancelDayOHLCHistoryFetch(request);
    }

    // --- Tick history fetch (download) ---

    public StartStocksTickHistoryFetchResponseMessage startTickHistoryFetch(StartStocksTickHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startTickHistoryFetch(request);
        return syntheticClient.startTickHistoryFetch(request);
    }

    public IsStocksTickHistoryFetchRunningResponseMessage isTickHistoryFetchRunning(IsStocksTickHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isTickHistoryFetchRunning(request);
        return syntheticClient.isTickHistoryFetchRunning(request);
    }

    public CancelStocksTickHistoryFetchResponseMessage cancelTickHistoryFetch(CancelStocksTickHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelTickHistoryFetch(request);
        return syntheticClient.cancelTickHistoryFetch(request);
    }

    // --- Trade history fetch (download) ---

    public StartStocksTradeHistoryFetchResponseMessage startTradeHistoryFetch(StartStocksTradeHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startTradeHistoryFetch(request);
        return syntheticClient.startTradeHistoryFetch(request);
    }

    public IsStocksTradeHistoryFetchRunningResponseMessage isTradeHistoryFetchRunning(IsStocksTradeHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isTradeHistoryFetchRunning(request);
        return syntheticClient.isTradeHistoryFetchRunning(request);
    }

    public CancelStocksTradeHistoryFetchResponseMessage cancelTradeHistoryFetch(CancelStocksTradeHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelTradeHistoryFetch(request);
        return syntheticClient.cancelTradeHistoryFetch(request);
    }

    // --- Quote history fetch (download) ---

    public StartStocksQuoteHistoryFetchResponseMessage startQuoteHistoryFetch(StartStocksQuoteHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.startQuoteHistoryFetch(request);
        return syntheticClient.startQuoteHistoryFetch(request);
    }

    public IsStocksQuoteHistoryFetchRunningResponseMessage isQuoteHistoryFetchRunning(IsStocksQuoteHistoryFetchRunningRequestMessage request) {
        if (sipClient != null) return sipClient.isQuoteHistoryFetchRunning(request);
        return syntheticClient.isQuoteHistoryFetchRunning(request);
    }

    public CancelStocksQuoteHistoryFetchResponseMessage cancelQuoteHistoryFetch(CancelStocksQuoteHistoryFetchRequestMessage request) {
        if (sipClient != null) return sipClient.cancelQuoteHistoryFetch(request);
        return syntheticClient.cancelQuoteHistoryFetch(request);
    }

    // --- Streaming ---

    public OpenHistoricalStocksOHLCStreamResponseMessage openHistoricalOHLCStream(OpenHistoricalStocksOHLCStreamRequestMessage request) {
        if (sipClient != null) return sipClient.openHistoricalOHLCStream(request);
        return syntheticClient.openHistoricalOHLCStream(request);
    }

    /**
     * Opens a stream on the client side. Returns a {@link HistoricalOHLCStream}
     * wrapper that provides {@code start()} and {@code close()} regardless of
     * which dataset-specific client is in use.
     */
    public HistoricalOHLCStream openStream(long streamId, String connectionDescriptor, Object handler) throws Exception {
        if (sipClient != null) {
            return new HistoricalOHLCStream(sipClient.openStream(streamId, connectionDescriptor, handler));
        }
        return new HistoricalOHLCStream(syntheticClient.openStream(streamId, connectionDescriptor, handler));
    }

    // --- Lifecycle ---

    public void close() {
        if (sipClient != null) sipClient.close();
        if (syntheticClient != null) syntheticClient.close();
    }

    // --- Stream wrapper ---

    public static class HistoricalOHLCStream {
        private final com.datafye.sip.history.Client.Stream sipStream;
        private final com.datafye.synthetic.history.Client.Stream syntheticStream;

        HistoricalOHLCStream(com.datafye.sip.history.Client.Stream stream) {
            this.sipStream = stream;
            this.syntheticStream = null;
        }

        HistoricalOHLCStream(com.datafye.synthetic.history.Client.Stream stream) {
            this.syntheticStream = stream;
            this.sipStream = null;
        }

        public void start(int rate) throws Exception {
            if (sipStream != null) sipStream.start(rate);
            else syntheticStream.start(rate);
        }

        public void close() throws Exception {
            if (sipStream != null) sipStream.close();
            else syntheticStream.close();
        }
    }
}
