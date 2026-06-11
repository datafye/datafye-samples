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
package com.datafye.samples.ws;

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.WebSocket;
import okhttp3.WebSocketListener;

import com.neeve.config.Config;

/**
 * Shared helper for the WebSocket streaming samples.
 *
 * Connects to a Datafye WebSocket endpoint, sends a single open message (a subscribe or start request),
 * prints every server frame as it arrives, and runs for a fixed number of seconds before closing. All of
 * the live/historical streaming samples are thin wrappers that build the endpoint path + open message and
 * delegate the socket plumbing here.
 *
 * The WebSocket endpoint host:port is read from the {@code datafye-samples.ws.endpoint} config value
 * (default {@code api.stream.rumi.local:7775}).
 */
public final class StreamClient {
    private StreamClient() {}

    /** Builds a full {@code ws://host:port/datafye-ws/v1/...} URL for the given endpoint path. */
    public static String wsUrl(final String path) {
        return "ws://" + Config.getValue("datafye-samples.ws.endpoint", "api.stream.rumi.local:7775")
                + "/datafye-ws/v1/" + path;
    }

    /** Renders a comma-separated symbol list as a JSON array, e.g. {@code AAPL,MSFT -> ["AAPL","MSFT"]}. */
    public static String symbolsArray(final String csv) {
        final String[] parts = csv.split(",");
        final StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < parts.length; i++) {
            if (i > 0) sb.append(",");
            sb.append("\"").append(parts[i].trim()).append("\"");
        }
        return sb.append("]").toString();
    }

    /**
     * Opens the socket, sends {@code openMessage}, prints frames for {@code seconds} seconds, then closes.
     */
    public static void stream(final String url, final String openMessage, final int seconds) throws Exception {
        System.out.println("Connecting to " + url);
        final OkHttpClient client = new OkHttpClient.Builder()
                .readTimeout(0, TimeUnit.MILLISECONDS) // no read timeout - a live stream is long-lived
                .build();
        final CountDownLatch closed = new CountDownLatch(1);
        final Request request = new Request.Builder().url(url).build();
        final WebSocket socket = client.newWebSocket(request, new WebSocketListener() {
            @Override
            public void onOpen(final WebSocket ws, final Response response) {
                System.out.println("--> " + openMessage);
                ws.send(openMessage);
            }

            @Override
            public void onMessage(final WebSocket ws, final String text) {
                System.out.println("<-- " + text);
            }

            @Override
            public void onClosing(final WebSocket ws, final int code, final String reason) {
                ws.close(code, reason);
            }

            @Override
            public void onClosed(final WebSocket ws, final int code, final String reason) {
                System.out.println("[closed " + code + " " + reason + "]");
                closed.countDown();
            }

            @Override
            public void onFailure(final WebSocket ws, final Throwable t, final Response response) {
                System.err.println("[error] " + t.getMessage());
                closed.countDown();
            }
        });

        // run for the requested duration, then close cleanly
        if (!closed.await(seconds, TimeUnit.SECONDS)) {
            socket.close(1000, "done");
            closed.await(2, TimeUnit.SECONDS);
        }
        client.dispatcher().executorService().shutdown(); // let the JVM exit
    }
}
