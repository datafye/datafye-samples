# Datafye Samples

Sample code for working with [Datafye](https://developer.datafye.io) deployments. The same operations are implemented three ways (REST, WebSocket, and the Java Client) across both asset classes (stocks, crypto) and all datasets (SIP, Synthetic, Crypto).

> **📖 Documentation.** The full sample catalog (what each sample does, the access-mode matrix, and how to run them) lives in the Datafye docs: **[Code Samples](https://docs.datafye.io/guides/data/code-samples)**. This README covers building the repo and running the certification.

## Build

### Prerequisites

- **Java 17+**
- **Maven 3.8+** ([download](https://maven.apache.org/index.html))

### Build the Project

```bash
mvn clean install
```

This produces a distribution archive in `target/`. Extract it:

```bash
cd target
tar -xzf datafye-samples-2.0-SNAPSHOT-distribution.tar.gz
cd datafye-samples-2.0-SNAPSHOT
```

The extracted distribution contains:
- `bin/` — run scripts (`run.sh` for Linux/macOS, `run.bat` for Windows)
- `libs/` — all JARs (application + dependencies)
- `conf/rumi.conf` — optional Rumi runtime tuning (trace levels, etc.)

To provision an environment and run individual samples, see [Code Samples](https://docs.datafye.io/guides/data/code-samples) in the docs.

## Certification

`sanity-test.sh` is the shipping certification. It provisions a local foundry, exercises **every** sample (every combination of asset class, dataset, schema, access mode, and protocol), cycling datasets via `apply`, and asserts that every registered sample ran.

```bash
sudo -E bash sanity-test.sh     # full cert: Synthetic, then SIP, then Crypto (needs a crypto-entitled POLYGON_API_KEY)
sudo bash sanity-test.sh        # Synthetic only (no key); SIP/Crypto reported NOT CERTIFIED
```

It uses the `datafye` CLI (2.0+, for `apply`) and the `rumi` CLI (for single-service recycling); set `DATAFYE_CLI` / `RUMI_CLI` to override their paths. Supported platforms: Amazon Linux 2/2023, RHEL, CentOS, Fedora, Rocky Linux, AlmaLinux, Ubuntu/Debian (including WSL), and macOS.
