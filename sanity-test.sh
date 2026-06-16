#!/usr/bin/env bash
# =============================================================================
# sanity-test.sh
#
# Shipping CERTIFICATION for the Datafye Data Cloud samples.
#
# Exercises EVERY sample — every combination of asset class x dataset x schema x
# access mode (fetch / subscribe / stream / backtest download + replay, incl. the
# is-running/cancel/stop lifecycle ops) x protocol (REST / WebSocket / Java). It
# provisions a local foundry on Synthetic, runs the full sample suite, then cycles
# to the next dataset with `datafye foundry local apply` (Synthetic -> SIP ->
# Crypto), and finally asserts that every sample id registered in bin/run.sh was
# exercised. SIP + Crypto require a crypto-entitled POLYGON_API_KEY; without it the
# run certifies Synthetic only and reports SIP/Crypto as NOT CERTIFIED.
#
# Run from the root of the datafye-samples repo:
#
#   sudo bash sanity-test.sh                                  # Synthetic only (no key)
#   sudo -E bash sanity-test.sh                               # full cert: Synthetic -> SIP -> Crypto (POLYGON_API_KEY)
#   sudo POLYGON_API_KEY="key" bash sanity-test.sh            # full cert (inline key)
#   sudo bash sanity-test.sh -v                               # Verbose (show sample output)
#
# Requires the rumi CLI (for single-service recycling + config) in addition to the
# datafye CLI; without it the Java live-subscribe samples are skipped.
#
# Supported platforms:
#   - Amazon Linux 2 or 2023
#   - RHEL, CentOS, Fedora, Rocky Linux, AlmaLinux
#   - Ubuntu/Debian (including WSL on Windows)
#   - macOS (Homebrew)
#
# Prerequisites: root/sudo access (Linux), Homebrew (macOS).
# The script installs Java 17, Maven, and the Datafye CLI if not present.
# =============================================================================
set -uo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges. Re-run with: sudo bash sanity-test.sh" >&2
    exit 1
fi

VERBOSE=false
RUN_CRYPTO=false
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=true ;;
        --crypto) RUN_CRYPTO=true ;;
    esac
done

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${WORK_DIR:-/tmp/datafye-sanity-test}"
LOG_DIR="${WORK_DIR}/logs"
SYMBOL="AAPL"
STOCK_SYMBOL="$SYMBOL"
CRYPTO_SYMBOL="BTCUSD"

# Live subscribe / WebSocket samples stream for a bounded window. STREAM_SECS is
# how long each streams; BOUNDED_TIMEOUT is the outer kill switch (the Java
# subscribe samples have no built-in duration, so we bound them ourselves).
STREAM_SECS="${STREAM_SECS:-20}"
BOUNDED_TIMEOUT=$((STREAM_SECS + 15))
# A stream test passes once this many records arrive (replay is ~1/sec, so a few
# seconds suffices); we stop the sample as soon as the threshold is reached.
MIN_STREAM_RECORDS="${MIN_STREAM_RECORDS:-1}"

# The certification always starts on Synthetic (no credentials) and cycles to the
# other datasets via `datafye foundry local apply`. SIP + Crypto need a
# crypto-entitled POLYGON_API_KEY: with one, the full cert runs Synthetic → SIP →
# Crypto; without one it certifies Synthetic only and reports SIP/Crypto as NOT
# CERTIFIED. (--crypto is accepted but the key is what gates the full run.)
DATASET="Synthetic"
DESCRIPTOR_URL="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-synthetic.yaml"
if [ -n "${POLYGON_API_KEY:-}" ]; then
    RUN_CRYPTO=true
else
    [ "$RUN_CRYPTO" = true ] && echo "Full certification (SIP + Crypto) needs a crypto-entitled POLYGON_API_KEY; certifying Synthetic only." >&2
    RUN_CRYPTO=false
fi
DS_LOWER=$(printf '%s' "$DATASET" | tr '[:upper:]' '[:lower:]')
# Versioned Rumi system names (e.g. datafye-api-system-2.0-SNAPSHOT) are resolved from
# the deployment API after each provision/apply — the controller registers systems by
# their full versioned name, which run-admin-script requires.
DS_SYSTEM=""
API_SYSTEM=""
API_HOST="api.rest.rumi.local:7776"
# rumi CLI drives single-service lifecycle (shutdown-single / launch-single) + config
# (configure) via the Rumi deployment scripts; defaults to PATH then ~/.local/bin/rumi.
RUMI_CLI="${RUMI_CLI:-$(command -v rumi 2>/dev/null || echo "${HOME}/.local/bin/rumi")}"
# datafye CLI for provision/apply/deprovision. The dataset cycling needs `apply`,
# which only exists in 2.0+ CLIs; override DATAFYE_CLI to point at a built 2.0 dist
# if the installed `datafye` predates it.
DATAFYE_CLI="${DATAFYE_CLI:-datafye}"
# certification bookkeeping
CERT_UNCERTIFIED=()
COVERED_FILE="${WORK_DIR}/covered-ids.txt"

# Test date: ~30 days ago (within the 90-day window the quickstart provisions),
# rolled back to a weekday. Stocks datasets (SIP, Synthetic) have no weekend
# session, so a Saturday/Sunday date yields no ticks to download or replay and
# the live phases would see no data. (Crypto trades 24/7, so this is harmless
# there.) Note: a weekday market holiday is still possible but rare.
TEST_OFFSET=30
TEST_DOW=$(date -d "-${TEST_OFFSET} days" +%u 2>/dev/null || date -v-${TEST_OFFSET}d +%u)
case "$TEST_DOW" in
    6) TEST_OFFSET=$((TEST_OFFSET + 1)) ;;  # Saturday -> Friday
    7) TEST_OFFSET=$((TEST_OFFSET + 2)) ;;  # Sunday   -> Friday
esac
TEST_DATE=$(date -d "-${TEST_OFFSET} days" +%Y-%m-%d 2>/dev/null || date -v-${TEST_OFFSET}d +%Y-%m-%d)
STREAM_FROM="${TEST_DATE}T09:30:00"
STREAM_TO="${TEST_DATE}T16:00:00"

# ---------------------------------------------------------------------------
# Terminal colors
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    CYAN='\033[1;36m'
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[1;33m'
    WHITE='\033[1;37m'
    RESET='\033[0m'
else
    BOLD='' DIM='' CYAN='' GREEN='' RED='' YELLOW='' WHITE='' RESET=''
fi

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0
FAILURES=""
TIMER_START=$(date +%s)

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
banner() {
    echo ""
    printf "${CYAN}%-62s${RESET}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "${WHITE}  Datafye Foundry — Sanity Test${RESET}\n"
    printf "${DIM}  Dataset: %-12s  Symbol: %-6s  Date: %s${RESET}\n" "$DATASET" "$SYMBOL" "$TEST_DATE"
    printf "${CYAN}%-62s${RESET}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

section() {
    echo ""
    printf "  ${WHITE}▸ %s${RESET}\n" "$1"
}

setup_msg() {
    printf "    ${DIM}%s${RESET}" "$1"
}

setup_ok() {
    printf "\r    ${GREEN}✓${RESET} %s\n" "$1"
}

setup_info() {
    printf "    ${DIM}%s${RESET}\n" "$1"
}

setup_warn() {
    printf "    ${YELLOW}!${RESET} %s\n" "$1"
}

setup_missing() {
    printf "    ${RED}✗${RESET} %s\n" "$1"
}

# Run a numbered test. Usage: run_test <label> <sample-name> [args...]
run_test() {
    local label="$1"; shift
    local sample="$1"; shift
    printf '%s\n' "$sample" >> "$COVERED_FILE" 2>/dev/null || true
    TOTAL=$((TOTAL + 1))

    local index_str
    index_str=$(printf "%2d" "$TOTAL")

    printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    local logfile="${LOG_DIR}/${TOTAL}-${sample}.log"
    local t_start t_end elapsed

    if [ "$VERBOSE" = true ]; then
        echo ""
    fi

    t_start=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    if [ "$VERBOSE" = true ]; then
        if "${DIST_DIR}/bin/run.sh" "$sample" "$@" 2>&1 | tee "$logfile"; then
            local _rc=0
        else
            local _rc=1
        fi
    else
        if "${DIST_DIR}/bin/run.sh" "$sample" "$@" >"$logfile" 2>&1; then
            local _rc=0
        else
            local _rc=1
        fi
    fi

    t_end=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    elapsed=$(( (t_end - t_start) / 1000000 ))

    if [ "$VERBOSE" = true ]; then
        printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"
    fi

    if [ "$_rc" -eq 0 ]; then
        printf "${GREEN}PASS${RESET}  ${DIM}%s${RESET}\n" "$(format_ms $elapsed)"
        PASSED=$((PASSED + 1))
    else
        printf "${RED}FAIL${RESET}  ${DIM}%s${RESET}\n" "$(format_ms $elapsed)"
        FAILED=$((FAILED + 1))
        FAILURES="${FAILURES}\n    ${RED}✗${RESET} ${label}  ${DIM}(log: ${logfile})${RESET}"
    fi
}

format_ms() {
    local ms=$1
    if [ "$ms" -ge 60000 ]; then
        printf "%dm%ds" $((ms / 60000)) $(( (ms % 60000) / 1000 ))
    elif [ "$ms" -ge 1000 ]; then
        printf "%d.%ds" $((ms / 1000)) $(( (ms % 1000) / 100 ))
    else
        printf "%dms" "$ms"
    fi
}

# Run a streaming/subscribe sample and PASS once it has received at least
# MIN_STREAM_RECORDS inbound records. Every subscribe (Java) and WebSocket sample
# prints received data with a leading "<-- " marker, so we judge by data flow, not
# exit code. run.sh execs the JVM, so the pid is the JVM and a plain kill stops it.
# Replay runs at ~1 tick/sec, so we poll the log and stop as soon as enough records
# have arrived (a few seconds) rather than waiting the whole window.
# Usage: run_stream_test <label> <sample> [args...]
run_stream_test() {
    local label="$1"; shift
    local sample="$1"; shift
    printf '%s\n' "$sample" >> "$COVERED_FILE" 2>/dev/null || true
    TOTAL=$((TOTAL + 1))

    local index_str
    index_str=$(printf "%2d" "$TOTAL")
    printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    local logfile="${LOG_DIR}/${TOTAL}-${sample}.log"
    local t_start t_end elapsed
    [ "$VERBOSE" = true ] && echo ""

    t_start=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    "${DIST_DIR}/bin/run.sh" "$sample" "$@" >"$logfile" 2>&1 &
    local pid=$! waited=0 received=0
    while [ "$waited" -lt "$BOUNDED_TIMEOUT" ]; do
        received=$(grep '^<-- ' "$logfile" 2>/dev/null | grep -cvE '"type":"(connected|subscribed|unsubscribed|halt|resume)"')
        [ "$received" -ge "$MIN_STREAM_RECORDS" ] && break
        kill -0 "$pid" 2>/dev/null || break   # sample exited on its own
        sleep 1
        waited=$((waited + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        pkill -P "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null || true
    received=$(grep -c '^<-- ' "$logfile" 2>/dev/null || echo 0)

    [ "$VERBOSE" = true ] && cat "$logfile"
    t_end=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    elapsed=$(( (t_end - t_start) / 1000000 ))
    [ "$VERBOSE" = true ] && printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    if [ "$received" -ge "$MIN_STREAM_RECORDS" ]; then
        printf "${GREEN}PASS${RESET}  ${DIM}%s, %s records${RESET}\n" "$(format_ms $elapsed)" "$received"
        PASSED=$((PASSED + 1))
    else
        printf "${RED}FAIL${RESET}  ${DIM}%s, %s records (<%s)${RESET}\n" "$(format_ms $elapsed)" "$received" "$MIN_STREAM_RECORDS"
        FAILED=$((FAILED + 1))
        FAILURES="${FAILURES}\n    ${RED}✗${RESET} ${label}  ${DIM}(log: ${logfile})${RESET}"
    fi
}

# Shut down / re-launch a single service instance to free (or restore) its single
# Ether subscription slot. This MUST go through the Rumi lifecycle (the rumi CLI's
# run-admin-script → shutdown-single / launch-single), never `docker stop` — a bare
# docker stop leaves the instance in a state the lifecycle can't recover. Args:
# <system> <serviceInstanceName>, e.g. "datafye-api-system" "datafye-api-stream".
shutdown_single() {
    setup_msg "Shutting down $2 (freeing its Ether subscription slot)..."
    if "$RUMI_CLI" cloud local run-admin-script -s "$1" -i shutdown-single -a "serviceInstanceName=$2" \
            >"${LOG_DIR}/shutdown-single-$2.log" 2>&1; then
        setup_ok "Shut down $2"
    else
        setup_warn "Could not shut down $2 (see ${LOG_DIR}/shutdown-single-$2.log)"
    fi
    sleep 3   # let the feed/agg notice the disconnect and release the slot
}

launch_single() {
    setup_msg "Re-launching $2..."
    if "$RUMI_CLI" cloud local run-admin-script -s "$1" -i launch-single -a "serviceInstanceName=$2" \
            >"${LOG_DIR}/launch-single-$2.log" 2>&1; then
        setup_ok "Re-launched $2"
    else
        setup_warn "Could not re-launch $2 (see ${LOG_DIR}/launch-single-$2.log)"
    fi
}

# Poll until a tick replay reports running (so live data is flowing) before we
# exercise the live samples. Best-effort: returns after a bounded number of
# tries. Usage: wait_replay_running <is-tick-replay-running-sample> [extra args]
# (stocks samples need -D "$DATASET"; crypto samples take no dataset flag).
wait_replay_running() {
    local sample="$1"; shift
    local tries=0
    while [ "$tries" -lt 15 ]; do
        if "${DIST_DIR}/bin/run.sh" "$sample" "$@" 2>/dev/null | grep -qi "true"; then
            return 0
        fi
        sleep 1
        tries=$((tries + 1))
    done
    return 1
}

summary() {
    local wall_end wall_elapsed
    wall_end=$(date +%s)
    wall_elapsed=$((wall_end - TIMER_START))

    echo ""
    printf "${CYAN}%-62s${RESET}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$FAILED" -eq 0 ]; then
        printf "  ${GREEN}${BOLD}%d passed${RESET}, ${DIM}0 failed${RESET}" "$PASSED"
    else
        printf "  ${GREEN}%d passed${RESET}, ${RED}${BOLD}%d failed${RESET}" "$PASSED" "$FAILED"
    fi
    if [ "$SKIPPED" -gt 0 ]; then
        printf ", ${YELLOW}%d skipped${RESET}" "$SKIPPED"
    fi
    printf "  ${DIM}(%dm%ds)${RESET}\n" $((wall_elapsed / 60)) $((wall_elapsed % 60))

    if [ -n "$FAILURES" ]; then
        echo ""
        printf "  ${RED}Failures:${RESET}"
        printf "$FAILURES"
        echo ""
    fi
    printf "${CYAN}%-62s${RESET}\n" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    printf "  ${DIM}Logs: ${LOG_DIR}${RESET}\n"
    echo ""
}

fail_setup() {
    printf "\r    ${RED}✗${RESET} %s\n" "$1"
    echo ""
    printf "  ${RED}Setup failed. Aborting.${RESET}\n\n"
    exit 1
}

ask_yn() {
    local prompt="$1" default="${2:-y}"
    local yn
    if [ "$default" = "y" ]; then
        printf "\n  ${WHITE}%s${RESET} ${DIM}[Y/n]${RESET} " "$prompt"
    else
        printf "\n  ${WHITE}%s${RESET} ${DIM}[y/N]${RESET} " "$prompt"
    fi
    read -r yn
    yn="${yn:-$default}"
    case "$yn" in
        y|Y) return 0 ;;
        *)   return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
pkg_install() {
    case "$PKG_MGR" in
        apt)  apt-get install -y -qq "$@" &>/dev/null ;;
        dnf)  dnf install -y "$@" &>/dev/null ;;
        yum)  yum install -y "$@" &>/dev/null ;;
        brew) brew install "$@" &>/dev/null ;;
    esac
}

has_docker_compose() {
    docker compose version &>/dev/null || docker-compose version &>/dev/null
}

install_docker_compose() {
    local compose_version="v2.24.5"
    local arch
    arch=$(uname -m)
    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)       fail_setup "Unsupported architecture for Docker Compose: $arch" ;;
    esac
    local plugin_dir="/usr/local/lib/docker/cli-plugins"
    mkdir -p "$plugin_dir"
    curl -fsSL "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}" \
        -o "$plugin_dir/docker-compose"
    chmod +x "$plugin_dir/docker-compose"
}

# ===========================================================================
# Phase 1: Detect platform and check all prerequisites
# ===========================================================================
banner

section "Checking Prerequisites"

mkdir -p "$WORK_DIR" "$LOG_DIR"

# --- Detect platform ---
DISTRO=""
PKG_MGR=""
IS_WSL=false

if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    case "$ID" in
        amzn)
            DISTRO="amzn"
            if [[ "${VERSION_ID:-}" == "2" ]]; then
                PKG_MGR="yum"
                setup_info "Amazon Linux 2 (note: AL2 reaches end-of-life June 2026)"
            else
                PKG_MGR="dnf"
                setup_info "Amazon Linux 2023"
            fi
            ;;
        centos|rhel)
            DISTRO="$ID"
            if command -v dnf &>/dev/null; then PKG_MGR="dnf"; else PKG_MGR="yum"; fi
            setup_info "${NAME:-$ID} ${VERSION_ID:-}"
            ;;
        fedora|rocky|almalinux)
            DISTRO="$ID"
            PKG_MGR="dnf"
            setup_info "${NAME:-$ID} ${VERSION_ID:-}"
            ;;
        ubuntu|debian)
            DISTRO="$ID"
            PKG_MGR="apt"
            if grep -qi microsoft /proc/version 2>/dev/null; then
                IS_WSL=true
                setup_info "${NAME:-$ID} ${VERSION_ID:-} (WSL)"
            else
                setup_info "${NAME:-$ID} ${VERSION_ID:-}"
            fi
            ;;
        *)
            fail_setup "Unsupported Linux distribution: ${ID:-unknown}. Supported: Amazon Linux, RHEL, CentOS, Fedora, Rocky, AlmaLinux, Ubuntu, Debian."
            ;;
    esac
elif [[ "$(uname)" == "Darwin" ]]; then
    DISTRO="macos"
    PKG_MGR="brew"
    if ! command -v brew &>/dev/null; then
        fail_setup "macOS detected but Homebrew is not installed. Install it from https://brew.sh"
    fi
    setup_info "macOS $(sw_vers -productVersion)"
else
    fail_setup "Unable to detect platform. Supported: Amazon Linux, RHEL, CentOS, Fedora, Rocky, AlmaLinux, Ubuntu, Debian, macOS."
fi

# --- Memory check ---
MEM_TOTAL_MB=0
if [ "$DISTRO" = "macos" ]; then
    MEM_TOTAL_MB=$(( $(sysctl -n hw.memsize) / 1048576 ))
elif [ -f /proc/meminfo ]; then
    MEM_TOTAL_MB=$(awk '/MemTotal/ { printf "%d", $2 / 1024 }' /proc/meminfo)
fi
MEM_TOTAL_GB=$(( (MEM_TOTAL_MB + 512) / 1024 ))  # round to nearest GB

if [ "$DISTRO" = "macos" ] || [ "$IS_WSL" = true ]; then
    MEM_MIN_GB=12
else
    MEM_MIN_GB=8
fi

if [ "$MEM_TOTAL_MB" -gt 0 ]; then
    if [ "$MEM_TOTAL_GB" -lt "$MEM_MIN_GB" ]; then
        fail_setup "Insufficient memory: ${MEM_TOTAL_GB}GB detected, ${MEM_MIN_GB}GB required. The local foundry runs in Docker and needs at least ${MEM_MIN_GB}GB of RAM."
    else
        setup_ok "Memory: ${MEM_TOTAL_GB}GB (${MEM_MIN_GB}GB required)"
    fi
fi

# --- Disk check ---
if [ "$DISTRO" = "macos" ]; then
    BEST_MOUNT=$(df -g 2>/dev/null | awk 'NR>1 && $4+0 > max { max=$4; mount=$NF } END { print mount }')
    BEST_AVAIL_GB=$(df -g 2>/dev/null | awk 'NR>1 && $4+0 > max { max=$4 } END { print max }')
    CWD_AVAIL_GB=$(df -g "${REPO_DIR}" 2>/dev/null | awk 'NR==2 { print $4 }')
else
    BEST_MOUNT=$(df -BG --output=avail,target 2>/dev/null | awk 'NR>1 { gsub(/G/,"",$1); if ($1+0 > max) { max=$1; mount=$2 } } END { print mount }')
    BEST_AVAIL_GB=$(df -BG --output=avail,target 2>/dev/null | awk 'NR>1 { gsub(/G/,"",$1); if ($1+0 > max) { max=$1 } } END { print max }')
    CWD_AVAIL_GB=$(df -BG --output=avail "${REPO_DIR}" 2>/dev/null | awk 'NR==2 { gsub(/G/,""); print $1 }')
fi

if [ -n "${CWD_AVAIL_GB:-}" ] && [ -n "${BEST_AVAIL_GB:-}" ]; then
    setup_ok "Disk: ${CWD_AVAIL_GB}GB available on current volume"
    if [ "${CWD_AVAIL_GB:-0}" -lt "${BEST_AVAIL_GB:-0}" ] && [ "${BEST_MOUNT:-}" != "/" ] && [ "${BEST_MOUNT:-}" != "$(df "${REPO_DIR}" 2>/dev/null | awk 'NR==2{print $NF}')" ]; then
        setup_warn "Largest volume is ${BEST_MOUNT} (${BEST_AVAIL_GB}GB free). Consider running from there"
        setup_warn "so Docker maps container volumes to the disk with the most space."
    fi
    if [ "${CWD_AVAIL_GB:-0}" -lt 20 ]; then
        setup_warn "Less than 20GB free. Historical data downloads may require significant disk space"
        setup_warn "depending on the number of symbols, date range, and data types downloaded."
    fi
fi

# --- Check software prerequisites ---
MISSING=()

# Docker
HAS_DOCKER=false
DOCKER_VERSION=""
if [ "$DISTRO" = "macos" ]; then
    if command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
        HAS_DOCKER=true
        DOCKER_VERSION="Docker Desktop $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
    fi
else
    if command -v docker &>/dev/null; then
        if docker info &>/dev/null 2>&1; then
            HAS_DOCKER=true
            DOCKER_VERSION="Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
        else
            # daemon not running — try to start it
            systemctl start docker &>/dev/null && systemctl enable docker &>/dev/null
            if docker info &>/dev/null 2>&1; then
                HAS_DOCKER=true
                DOCKER_VERSION="Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
            fi
        fi
    fi
fi
if [ "$HAS_DOCKER" = true ]; then
    setup_ok "$DOCKER_VERSION"
else
    if [ "$DISTRO" = "macos" ]; then
        fail_setup "Docker Desktop is not running. Install it from https://docs.docker.com/desktop/install/mac-install/ and start it."
    fi
    setup_missing "Docker — not installed"
    MISSING+=("Docker")
fi

# Docker Compose
HAS_COMPOSE=false
COMPOSE_VERSION=""
if [ "$HAS_DOCKER" = true ]; then
    if has_docker_compose; then
        HAS_COMPOSE=true
        COMPOSE_VERSION="Docker Compose $(docker compose version --short 2>/dev/null || docker-compose version --short 2>/dev/null)"
        setup_ok "$COMPOSE_VERSION"
    else
        setup_missing "Docker Compose — not installed"
        MISSING+=("Docker Compose")
    fi
fi

# Java 17
HAS_JAVA=false
JAVA_VERSION=""
if java -version 2>&1 | grep -q '"17\.'; then
    HAS_JAVA=true
    JAVA_VERSION="Java $(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)"/\1/')"
    setup_ok "$JAVA_VERSION"
else
    setup_missing "Java 17 — not installed"
    MISSING+=("Java 17")
fi

# Maven
HAS_MAVEN=false
MAVEN_VERSION_STR=""
if command -v mvn &>/dev/null; then
    HAS_MAVEN=true
    MAVEN_VERSION_STR="Maven $(mvn --version 2>/dev/null | head -1 | sed 's/Apache Maven \([^ ]*\).*/\1/')"
    setup_ok "$MAVEN_VERSION_STR"
else
    setup_missing "Maven — not installed"
    MISSING+=("Maven")
fi

# Datafye CLI
HAS_CLI=false
CLI_VERSION=""
if command -v datafye &>/dev/null; then
    HAS_CLI=true
    CLI_VERSION="Datafye CLI $(datafye --version 2>/dev/null | head -1)"
    setup_ok "$CLI_VERSION"
else
    setup_missing "Datafye CLI — not installed"
    MISSING+=("Datafye CLI")
fi

# Rumi CLI — drives single-service recycling (shutdown-single / launch-single) for the
# live Java-subscribe tests (Ether buses allow only one subscriber, so a service must be
# shut down to free a slot for a Java client). Without it those tests are skipped.
HAS_RUMI_CLI=false
if [ -x "$RUMI_CLI" ] || command -v rumi &>/dev/null; then
    HAS_RUMI_CLI=true
    setup_ok "Rumi CLI ($RUMI_CLI)"
else
    setup_warn "Rumi CLI not found — live Java-subscribe tests will be skipped (set RUMI_CLI to its path)"
fi

# ===========================================================================
# Phase 2: Install missing prerequisites (if any)
# ===========================================================================
if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    printf "  ${YELLOW}Missing: %s${RESET}\n" "$(IFS=', '; echo "${MISSING[*]}")"

    if ! ask_yn "Install missing prerequisites?"; then
        echo ""
        printf "  ${DIM}Exiting. Install the missing prerequisites and re-run.${RESET}\n\n"
        exit 0
    fi

    section "Installing Prerequisites"

    # Docker
    if [ "$HAS_DOCKER" = false ]; then
        setup_msg "Installing Docker..."
        case "$DISTRO" in
            amzn)
                pkg_install docker || fail_setup "Docker installation failed"
                ;;
            ubuntu|debian)
                apt-get update -qq &>/dev/null
                apt-get install -y -qq ca-certificates curl gnupg lsb-release &>/dev/null
                install -m 0755 -d /etc/apt/keyrings
                curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
                chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
                    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
                apt-get update -qq &>/dev/null
                apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>/dev/null \
                    || fail_setup "Docker installation failed"
                ;;
            centos|rhel|fedora|rocky|almalinux)
                yum install -y yum-utils &>/dev/null
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>/dev/null
                yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>/dev/null \
                    || fail_setup "Docker installation failed"
                ;;
            *)
                fail_setup "Cannot install Docker automatically on ${DISTRO}. Please install Docker manually."
                ;;
        esac
        systemctl start docker &>/dev/null && systemctl enable docker &>/dev/null \
            || fail_setup "Docker installed but daemon failed to start"
        docker info &>/dev/null 2>&1 || fail_setup "Docker installation failed"
        setup_ok "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
    fi

    # Docker Compose
    if [ "$HAS_COMPOSE" = false ] && ! has_docker_compose; then
        setup_msg "Installing Docker Compose..."
        install_docker_compose || fail_setup "Docker Compose installation failed"
        setup_ok "Docker Compose $(docker compose version --short 2>/dev/null)"
    fi

    # Java 17
    if [ "$HAS_JAVA" = false ]; then
        setup_msg "Installing Java 17..."
        case "$PKG_MGR" in
            apt)
                apt-get update -qq &>/dev/null
                pkg_install openjdk-17-jdk || fail_setup "Java 17 installation failed"
                ;;
            dnf)
                if [ "$DISTRO" = "amzn" ]; then
                    pkg_install java-17-amazon-corretto-devel || fail_setup "Java 17 installation failed"
                else
                    pkg_install java-17-openjdk-devel || fail_setup "Java 17 installation failed"
                fi
                ;;
            yum)
                if [ "$DISTRO" = "amzn" ]; then
                    pkg_install java-17-amazon-corretto-devel || fail_setup "Java 17 installation failed"
                else
                    rpm --import https://yum.corretto.aws/corretto.key 2>/dev/null || true
                    curl -sLo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
                    pkg_install java-17-amazon-corretto-devel || fail_setup "Java 17 installation failed"
                fi
                ;;
            brew)
                pkg_install openjdk@17 || fail_setup "Java 17 installation failed"
                ;;
        esac
        setup_ok "Java $(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)"/\1/')"
    fi

    # Maven
    if [ "$HAS_MAVEN" = false ]; then
        setup_msg "Installing Maven..."
        if [ "$PKG_MGR" = "brew" ]; then
            pkg_install maven || fail_setup "Maven installation failed"
        else
            MAVEN_VERSION="3.9.6"
            curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
                | tar -xz -C /opt || fail_setup "Maven installation failed"
            ln -sf "/opt/apache-maven-${MAVEN_VERSION}/bin/mvn" /usr/local/bin/mvn
        fi
        setup_ok "Maven $(mvn --version 2>/dev/null | head -1 | sed 's/Apache Maven \([^ ]*\).*/\1/')"
    fi

    # Datafye CLI
    if [ "$HAS_CLI" = false ]; then
        setup_msg "Installing Datafye CLI..."
        curl -fsSL https://downloads.n5corp.com/datafye/cli/latest/install.sh \
            | bash &>"${LOG_DIR}/datafye-cli-install.log" \
            || fail_setup "Datafye CLI installation failed (see ${LOG_DIR}/datafye-cli-install.log)"
        setup_ok "Datafye CLI $(datafye --version 2>/dev/null | head -1)"
    fi
fi

# --- Set JAVA_HOME (needed for build regardless of whether Java was just installed) ---
if [ "$DISTRO" = "macos" ]; then
    JAVA_HOME_DIR=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home")
else
    JAVA_HOME_DIR=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
fi
export JAVA_HOME="${JAVA_HOME_DIR}"
export PATH="${JAVA_HOME}/bin:${PATH}"

# ===========================================================================
# Phase 3: Confirm before running tests
# ===========================================================================
echo ""
printf "  ${GREEN}All prerequisites are in place.${RESET}\n"
echo ""
DATASET_LABEL="$DATASET"
[ "$RUN_CRYPTO" = true ] && DATASET_LABEL="SIP + Crypto"
printf "  ${DIM}The sanity test will:${RESET}\n"
printf "  ${DIM}  1. Build the samples from source${RESET}\n"
printf "  ${DIM}  2. Provision a local Data Cloud Only Foundry (${DATASET_LABEL} dataset)${RESET}\n"
printf "  ${DIM}  3. Add DNS entries to /etc/hosts${RESET}\n"
printf "  ${DIM}  4. Run tests (health, reference, download, fetch, stream, live, subscribe, WebSocket)${RESET}\n"
printf "  ${DIM}  5. Remove DNS entries from /etc/hosts${RESET}\n"
printf "  ${DIM}  6. Deprovision the foundry${RESET}\n"

if ! ask_yn "Proceed?"; then
    echo ""
    printf "  ${DIM}Exiting.${RESET}\n\n"
    exit 0
fi

TIMER_START=$(date +%s)

# ===========================================================================
# Build
# ===========================================================================
section "Build"

setup_msg "Building samples..."
export MAVEN_OPTS="-Xmx2g --add-exports=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/jdk.internal.ref=ALL-UNNAMED"
if [ "$VERBOSE" = true ]; then
    echo ""
    if (cd "${REPO_DIR}" && mvn clean install) 2>&1 | tee "${LOG_DIR}/build.log"; then
        setup_ok "Build complete"
    else
        fail_setup "Build failed (see ${LOG_DIR}/build.log)"
    fi
else
    if (cd "${REPO_DIR}" && mvn clean install -q) &>"${LOG_DIR}/build.log"; then
        setup_ok "Build complete"
    else
        fail_setup "Build failed (see ${LOG_DIR}/build.log)"
    fi
fi

setup_msg "Extracting distribution..."
DIST_TAR=$(ls "${REPO_DIR}/target/"*-distribution.tar.gz 2>/dev/null | head -1)
if [ -z "$DIST_TAR" ]; then
    fail_setup "Distribution archive not found"
fi
tar -xzf "$DIST_TAR" -C "${WORK_DIR}"
DIST_DIR=$(find "${WORK_DIR}" -maxdepth 1 -type d -name "datafye-samples-*" | head -1)
setup_ok "Distribution ready"

# ===========================================================================
# Provision
# ===========================================================================
section "Provision"

# The certification always provisions Synthetic first, then cycles to SIP/Crypto
# via `apply` (see the certification section). One dataset is deployed at a time.
setup_msg "Downloading Synthetic quickstart descriptor..."
curl -fsSL -o "${WORK_DIR}/quickstart.yaml" "$DESCRIPTOR_URL" || fail_setup "Descriptor download failed"
setup_ok "Descriptor downloaded (Synthetic)"

setup_msg "Provisioning foundry (this may take a few minutes)..."
if [ "$VERBOSE" = true ]; then
    echo ""
    if "$DATAFYE_CLI" foundry local provision --descriptor "${WORK_DIR}/quickstart.yaml" 2>&1 | tee "${LOG_DIR}/provision.log"; then
        setup_ok "Foundry provisioned"
    else
        fail_setup "Provisioning failed (see ${LOG_DIR}/provision.log)"
    fi
else
    if "$DATAFYE_CLI" foundry local provision --descriptor "${WORK_DIR}/quickstart.yaml" &>"${LOG_DIR}/provision.log"; then
        setup_ok "Foundry provisioned"
    else
        fail_setup "Provisioning failed (see ${LOG_DIR}/provision.log)"
    fi
fi

# --- DNS entries ---
HOSTS_ENTRIES=(
    "solace.rumi.local"
    "api.rest.rumi.local"
    "api.stream.rumi.local"
    "sip.feed.rumi.local"
    "sip.history.rumi.local"
    "synthetic.feed.rumi.local"
    "synthetic.history.rumi.local"
    "local-foundry-dev-api.datafye.local"
    "local-foundry-dev-admin.datafye.local"
    "local-foundry-dev-monitor.datafye.local"
)
if [ "$RUN_CRYPTO" = true ]; then
    HOSTS_ENTRIES+=("crypto.feed.rumi.local" "crypto.history.rumi.local")
fi
HOSTS_MARKER="# -- DNS Entries for the local Datafye Foundry deployment --"
HOSTS_NEEDED=false
for host in "${HOSTS_ENTRIES[@]}"; do
    if ! grep -q "$host" /etc/hosts 2>/dev/null; then
        HOSTS_NEEDED=true
        break
    fi
done

if [ "$HOSTS_NEEDED" = true ]; then
    {
        echo ""
        echo "$HOSTS_MARKER"
        for h in "${HOSTS_ENTRIES[@]}"; do
            echo "127.0.0.1   $h"
        done
        echo "$HOSTS_MARKER"
    } >> /etc/hosts
    setup_ok "DNS entries added to /etc/hosts"
else
    setup_ok "DNS entries already in /etc/hosts"
fi

# ===========================================================================
# Certification
# ===========================================================================
# Exercise EVERY sample (every asset class x dataset x schema x access mode x
# protocol). Datasets are certified one at a time and cycled with
# `datafye foundry local apply` (Synthetic -> SIP -> Crypto). SIP and Crypto
# require a crypto-entitled POLYGON_API_KEY; without it only Synthetic is
# certified and SIP/Crypto are reported NOT CERTIFIED. run_test/run_stream_test
# record every invoked sample id; a coverage assertion at the end diffs that
# against every id registered in bin/run.sh.

LIVE_FREQ="${LIVE_FREQ:-Second}"
# Live OHLC/SMA/EMA bar finalizes are sparse (~1 / few sec) and SMA/EMA need
# warmup, so indicator/agg stream windows are generous.
STREAM_SECS="${STREAM_SECS:-20}"
INDICATOR_SECS="${INDICATOR_SECS:-50}"

# --- coverage tracking: which run.sh ids are registered, and which we invoked ---
ALL_IDS_FILE="${WORK_DIR}/all-run-ids.txt"
grep -oE '^[[:space:]]+[a-z0-9][a-z0-9-]+\)' "${DIST_DIR}/bin/run.sh" 2>/dev/null \
    | tr -d ' )' | grep -vE '^\*$' | sort -u > "$ALL_IDS_FILE"
: > "$COVERED_FILE"   # fresh coverage tally for this run

# Enable live SMA/EMA processing in the agent's controller.conf (once). Each
# dataset's agg localizes against it on provision/apply, so SMA/EMA compute and
# stream. Needs the rumi CLI; without it indicator subscribe is skipped.
enable_indicators() {
    [ "$HAS_RUMI_CLI" = true ] || { setup_warn "rumi CLI absent — live SMA/EMA processing not enabled"; return 1; }
    section "Enabling Live SMA/EMA Processing"
    local k
    for k in LIVE_SECOND_SMA_PROCESS LIVE_SECOND_EMA_PROCESS LIVE_SECOND_OHLC_PUBLISH; do
        if "$RUMI_CLI" cloud local configure -s LiveAnalytics -k "$k" -v true >"${LOG_DIR}/configure-$k.log" 2>&1; then
            setup_ok "Set $k=true"
        else
            setup_warn "Could not set $k (see ${LOG_DIR}/configure-$k.log)"
        fi
    done
    return 0
}

# Resolve the versioned Rumi system names for the currently-deployed dataset.
resolve_systems() {   # <ds-lower>
    local ds="$1" sys
    sys=$(curl -fsS "http://${API_HOST}/datafye-api/v1/deployment/systems" 2>/dev/null)
    API_SYSTEM=$(printf '%s' "$sys" | grep -oE "datafye-api-system[A-Za-z0-9._-]*" | head -1)
    DS_SYSTEM=$(printf '%s' "$sys" | grep -oE "datafye-${ds}-system[A-Za-z0-9._-]*" | head -1)
}

# Re-localize an agg so it picks up the SMA/EMA config (needed only for the first
# dataset; a later `apply` re-localizes the swapped-in agg from controller.conf).
recycle_agg_for_indicators() {   # <ds-lower>
    [ "$HAS_RUMI_CLI" = true ] || return 0
    [ -n "$DS_SYSTEM" ] || return 0
    setup_msg "Re-localizing $1 agg to enable SMA/EMA..."
    shutdown_single "$DS_SYSTEM" "datafye-$1-agg"
    "$RUMI_CLI" cloud local run-admin-script -s "$DS_SYSTEM" -i upgrade-single -a "serviceInstanceName=datafye-$1-agg" >"${LOG_DIR}/upgrade-$1-agg.log" 2>&1 \
        && setup_ok "Upgraded $1 agg" || setup_warn "Could not upgrade $1 agg"
    launch_single "$DS_SYSTEM" "datafye-$1-agg"
}

# Swap the deployed dataset via apply (downloads the dataset's quickstart descriptor).
apply_dataset() {   # <Dataset>
    local ds="$1" url
    case "$ds" in
        SIP)    url="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-sip.yaml" ;;
        Crypto) url="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-crypto.yaml" ;;
        *)      setup_warn "no descriptor for $ds"; return 1 ;;
    esac
    section "Apply → $ds"
    curl -fsSL -o "${WORK_DIR}/apply-${ds}.yaml" "$url" || { setup_warn "descriptor download failed ($ds)"; return 1; }
    if "$DATAFYE_CLI" foundry local apply -x "${WORK_DIR}/apply-${ds}.yaml" &>"${LOG_DIR}/apply-${ds}.log"; then
        setup_ok "Applied $ds"
        return 0
    fi
    setup_warn "Apply $ds failed (see ${LOG_DIR}/apply-${ds}.log)"
    return 1
}

# Backtest download lifecycle for one schema: start (no wait) -> is-running ->
# cancel, on REST and Java, then a start --wait to actually land data. Args differ
# by asset class: stocks pass -D <DS>, crypto take no dataset flag.
backtest_download() {   # <schema> <pfx> <sym> <ddash-or-empty...>
    local schema="$1" pfx="$2" sym="$3"; shift 3; local D=("$@")
    local proto
    for proto in rest java; do
        run_test "Start ${schema} download (${pfx}/${proto})" \
            "start-${schema}-download-${pfx}-${proto}" -d "$TEST_DATE" -s "$sym" "${D[@]}"
        run_test "Is ${schema} download running (${pfx}/${proto})" \
            "is-${schema}-download-running-${pfx}-${proto}" "${D[@]}"
        run_test "Cancel ${schema} download (${pfx}/${proto})" \
            "cancel-${schema}-download-${pfx}-${proto}" "${D[@]}"
    done
    run_test "Download ${schema} (${pfx}, --wait)" \
        "start-${schema}-download-${pfx}-rest" -d "$TEST_DATE" -s "$sym" -w "${D[@]}"
}

# Full sample suite for one stocks dataset (Synthetic or SIP). pfx=stocks, -D <DS>.
run_stocks_phase() {   # <Dataset>
    local DS="$1" dl pfx=stocks sym="$STOCK_SYMBOL"
    dl=$(printf '%s' "$DS" | tr '[:upper:]' '[:lower:]')
    local D=(-D "$DS")
    resolve_systems "$dl"

    section "[$DS] Health & Reference"
    run_test "Ping (REST)"            ping-rest -d "$DS"
    run_test "Get Securities (REST)"  "get-securities-${pfx}-rest" "${D[@]}"
    run_test "Get Securities (Java)"  "get-securities-${pfx}-java" "${D[@]}"

    section "[$DS] Backtest — Downloads"
    backtest_download tick  "$pfx" "$sym" "${D[@]}"
    backtest_download trade "$pfx" "$sym" "${D[@]}"
    backtest_download quote "$pfx" "$sym" "${D[@]}"
    # OHLC download takes a frequency
    local proto
    for proto in rest java; do
        run_test "Start ohlc download (${pfx}/${proto})"        "start-ohlc-download-${pfx}-${proto}" -d "$TEST_DATE" -s "$sym" -c Minute "${D[@]}"
        run_test "Is ohlc download running (${pfx}/${proto})"   "is-ohlc-download-running-${pfx}-${proto}" "${D[@]}"
        run_test "Cancel ohlc download (${pfx}/${proto})"       "cancel-ohlc-download-${pfx}-${proto}" "${D[@]}"
    done
    run_test "Download Minute OHLC (${pfx}, --wait)"            "start-ohlc-download-${pfx}-rest" -d "$TEST_DATE" -s "$sym" -c Minute -w "${D[@]}"

    section "[$DS] Historical Aggregates"
    run_test "Fetch Historical OHLC (REST)"          "get-historical-ohlc-${pfx}-rest" -s "$sym" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO" "${D[@]}"
    run_test "Fetch Historical OHLC (Java)"          "get-historical-ohlc-${pfx}-java" -s "$sym" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO" "${D[@]}"
    run_test "Fetch Historical Top Gainers (REST)"   "get-historical-top-gainers-${pfx}-rest" -d "$TEST_DATE" "${D[@]}"
    run_test "Fetch Historical Top Gainers (Java)"   "get-historical-top-gainers-${pfx}-java" -d "$TEST_DATE" "${D[@]}"
    run_test "Stream Historical OHLC (Java)"         "stream-historical-ohlc-${pfx}-java" -s "$sym" -f "$STREAM_FROM" -t "$STREAM_TO" "${D[@]}"
    run_test "Stream Historical OHLC Concurrently (Java)" "stream-historical-ohlc-concurrently-${pfx}-java" -f "$TEST_DATE" "${D[@]}"

    section "[$DS] Backtest — Tick Replay"
    run_test "Download Ticks (--wait)"  "start-tick-download-${pfx}-rest" -d "$TEST_DATE" -s "$sym" -w "${D[@]}"
    # exercise the Java replay lifecycle (start/is/stop) on a quick cycle for coverage...
    run_test "Start Tick Replay (Java)"      "start-tick-replay-${pfx}-java" -d "$TEST_DATE" "${D[@]}"
    run_test "Is Tick Replay Running (REST)" "is-tick-replay-running-${pfx}-rest" "${D[@]}"
    run_test "Is Tick Replay Running (Java)" "is-tick-replay-running-${pfx}-java" "${D[@]}"
    run_test "Stop Tick Replay (Java)"       "stop-tick-replay-${pfx}-java" "${D[@]}"
    # ...then start via REST and keep it running through the live tests
    run_test "Start Tick Replay (REST)" "start-tick-replay-${pfx}-rest" -d "$TEST_DATE" "${D[@]}"
    wait_replay_running "is-tick-replay-running-${pfx}-rest" "${D[@]}" \
        && setup_ok "Tick replay running" || setup_warn "Tick replay not running; live samples may see no data"

    section "[$DS] Live — Fetch"
    run_test "Fetch Live OHLC (REST)"         "get-live-ohlc-${pfx}-rest" -s "$sym" "${D[@]}"
    run_test "Fetch Live OHLC (Java)"         "get-live-ohlc-${pfx}-java" -s "$sym" "${D[@]}"
    run_test "Fetch Live Top-of-Book (REST)"  "get-live-top-of-book-${pfx}-rest" -s "$sym" "${D[@]}"
    run_test "Fetch Live Top-of-Book (Java)"  "get-live-top-of-book-${pfx}-java" -s "$sym" "${D[@]}"
    run_test "Fetch Live Last Trade (REST)"   "get-live-last-trade-${pfx}-rest" -s "$sym" "${D[@]}"
    run_test "Fetch Live Last Trade (Java)"   "get-live-last-trade-${pfx}-java" -s "$sym" "${D[@]}"
    run_test "Fetch Live SMA (REST)"          "get-live-sma-${pfx}-rest" -s "$sym" "${D[@]}"
    run_test "Fetch Live SMA (Java)"          "get-live-sma-${pfx}-java" -s "$sym" "${D[@]}"
    run_test "Fetch Live EMA (REST)"          "get-live-ema-${pfx}-rest" -s "$sym" "${D[@]}"
    run_test "Fetch Live EMA (Java)"          "get-live-ema-${pfx}-java" -s "$sym" "${D[@]}"

    section "[$DS] Live — WebSocket subscribe"
    run_stream_test "Subscribe Live Trades (WS)"     subscribe-live-trades-ws       -d "$DS" -s "$sym" -t "$STREAM_SECS"
    run_stream_test "Subscribe Live Quotes (WS)"     subscribe-live-top-of-book-ws  -d "$DS" -s "$sym" -t "$STREAM_SECS"
    run_stream_test "Subscribe Live OHLC (WS)"       subscribe-live-ohlc-ws         -d "$DS" -s "$sym" -f "$LIVE_FREQ" -t "$INDICATOR_SECS"
    run_stream_test "Subscribe Live SMA (WS)"        subscribe-live-sma-ws          -d "$DS" -s "$sym" -f "$LIVE_FREQ" -t "$INDICATOR_SECS"
    run_stream_test "Subscribe Live EMA (WS)"        subscribe-live-ema-ws          -d "$DS" -s "$sym" -f "$LIVE_FREQ" -t "$INDICATOR_SECS"
    run_stream_test "Stream Historical OHLC (WS)"    stream-historical-ohlc-ws      -d "$DS" -s "$sym" -f Minute -b "$STREAM_FROM" -e "$STREAM_TO" -t "$STREAM_SECS"

    if [ "$HAS_RUMI_CLI" = true ]; then
        section "[$DS] Live — Java subscribe (agg-stream slot freed)"
        shutdown_single "$API_SYSTEM" datafye-api-stream
        run_stream_test "Subscribe Live OHLC (Java)" "subscribe-live-ohlc-${pfx}-java" -s "$sym" -c "$LIVE_FREQ" "${D[@]}"
        run_stream_test "Subscribe Live SMA (Java)"  "subscribe-live-sma-${pfx}-java"  -s "$sym" -c "$LIVE_FREQ" "${D[@]}"
        run_stream_test "Subscribe Live EMA (Java)"  "subscribe-live-ema-${pfx}-java"  -s "$sym" -c "$LIVE_FREQ" "${D[@]}"

        section "[$DS] Live — Java subscribe (feed slot freed)"
        shutdown_single "$DS_SYSTEM" "datafye-${dl}-agg"
        run_stream_test "Subscribe Live Top-of-Book (Java)" "subscribe-live-top-of-book-${pfx}-java" -s "$sym" "${D[@]}"
        run_stream_test "Subscribe Live Trades (Java)"      "subscribe-live-trades-${pfx}-java"      -s "$sym" "${D[@]}"

        section "[$DS] Restoring recycled services"
        launch_single "$DS_SYSTEM" "datafye-${dl}-agg"
        launch_single "$API_SYSTEM" datafye-api-stream
    else
        setup_warn "[$DS] Java subscribe skipped — rumi CLI required to free an Ether slot"
    fi

    section "[$DS] Backtest — Stop Replay"
    run_test "Stop Tick Replay (REST)" "stop-tick-replay-${pfx}-rest" "${D[@]}"
}

# Full sample suite for the Crypto dataset. pfx=crypto, dataset-fixed (no -D).
# Crypto has no Java tick-subscribe samples (only agg subscribe + WS).
run_crypto_phase() {
    local DS=Crypto dl=crypto pfx=crypto sym="$CRYPTO_SYMBOL"
    resolve_systems "$dl"

    section "[Crypto] Health & Reference"
    run_test "Ping (REST)"           ping-rest -d "$DS"
    run_test "Get Securities (REST)" "get-securities-${pfx}-rest"
    run_test "Get Securities (Java)" "get-securities-${pfx}-java"

    section "[Crypto] Backtest — Downloads"
    backtest_download tick  "$pfx" "$sym"
    backtest_download trade "$pfx" "$sym"
    backtest_download quote "$pfx" "$sym"
    local proto
    for proto in rest java; do
        run_test "Start ohlc download (crypto/${proto})"      "start-ohlc-download-${pfx}-${proto}" -d "$TEST_DATE" -s "$sym" -c Minute
        run_test "Is ohlc download running (crypto/${proto})" "is-ohlc-download-running-${pfx}-${proto}"
        run_test "Cancel ohlc download (crypto/${proto})"     "cancel-ohlc-download-${pfx}-${proto}"
    done
    run_test "Download Minute OHLC (crypto, --wait)"          "start-ohlc-download-${pfx}-rest" -d "$TEST_DATE" -s "$sym" -c Minute -w

    section "[Crypto] Historical Aggregates"
    run_test "Fetch Historical OHLC (REST)"        "get-historical-ohlc-${pfx}-rest" -s "$sym" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO"
    run_test "Fetch Historical OHLC (Java)"        "get-historical-ohlc-${pfx}-java" -s "$sym" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO"
    run_test "Fetch Historical Top Gainers (REST)" "get-historical-top-gainers-${pfx}-rest" -d "$TEST_DATE"
    run_test "Fetch Historical Top Gainers (Java)" "get-historical-top-gainers-${pfx}-java" -d "$TEST_DATE"
    run_test "Stream Historical OHLC (Java)"       "stream-historical-ohlc-${pfx}-java" -s "$sym" -f "$STREAM_FROM" -t "$STREAM_TO"
    run_test "Stream Historical OHLC Concurrently (Java)" "stream-historical-ohlc-concurrently-${pfx}-java" -f "$TEST_DATE"

    section "[Crypto] Backtest — Tick Replay"
    run_test "Download Ticks (--wait)"  "start-tick-download-${pfx}-rest" -d "$TEST_DATE" -s "$sym" -w
    # exercise the Java replay lifecycle (start/is/stop) for coverage...
    run_test "Start Tick Replay (Java)"      "start-tick-replay-${pfx}-java" -d "$TEST_DATE"
    run_test "Is Tick Replay Running (REST)" "is-tick-replay-running-${pfx}-rest"
    run_test "Is Tick Replay Running (Java)" "is-tick-replay-running-${pfx}-java"
    run_test "Stop Tick Replay (Java)"       "stop-tick-replay-${pfx}-java"
    # ...then start via REST and keep it running through the live tests
    run_test "Start Tick Replay (REST)" "start-tick-replay-${pfx}-rest" -d "$TEST_DATE"
    wait_replay_running "is-tick-replay-running-${pfx}-rest" \
        && setup_ok "Crypto tick replay running" || setup_warn "Crypto tick replay not running"

    section "[Crypto] Live — Fetch"
    run_test "Fetch Live OHLC (REST)"        "get-live-ohlc-${pfx}-rest" -s "$sym"
    run_test "Fetch Live OHLC (Java)"        "get-live-ohlc-${pfx}-java" -s "$sym"
    run_test "Fetch Live Top-of-Book (REST)" "get-live-top-of-book-${pfx}-rest" -s "$sym"
    run_test "Fetch Live Top-of-Book (Java)" "get-live-top-of-book-${pfx}-java" -s "$sym"
    run_test "Fetch Live Last Trade (REST)"  "get-live-last-trade-${pfx}-rest" -s "$sym"
    run_test "Fetch Live Last Trade (Java)"  "get-live-last-trade-${pfx}-java" -s "$sym"
    run_test "Fetch Live SMA (REST)"         "get-live-sma-${pfx}-rest" -s "$sym"
    run_test "Fetch Live SMA (Java)"         "get-live-sma-${pfx}-java" -s "$sym"
    run_test "Fetch Live EMA (REST)"         "get-live-ema-${pfx}-rest" -s "$sym"
    run_test "Fetch Live EMA (Java)"         "get-live-ema-${pfx}-java" -s "$sym"

    section "[Crypto] Live — WebSocket subscribe"
    run_stream_test "Subscribe Live Trades (WS)"  subscribe-live-trades-ws      -d "$DS" -s "$sym" -t "$STREAM_SECS"
    run_stream_test "Subscribe Live Quotes (WS)"  subscribe-live-top-of-book-ws -d "$DS" -s "$sym" -t "$STREAM_SECS"
    run_stream_test "Subscribe Live OHLC (WS)"    subscribe-live-ohlc-ws        -d "$DS" -s "$sym" -f "$LIVE_FREQ" -t "$INDICATOR_SECS"
    run_stream_test "Subscribe Live SMA (WS)"     subscribe-live-sma-ws         -d "$DS" -s "$sym" -f "$LIVE_FREQ" -t "$INDICATOR_SECS"
    run_stream_test "Subscribe Live EMA (WS)"     subscribe-live-ema-ws         -d "$DS" -s "$sym" -f "$LIVE_FREQ" -t "$INDICATOR_SECS"
    run_stream_test "Stream Historical OHLC (WS)" stream-historical-ohlc-ws     -d "$DS" -s "$sym" -f Minute -b "$STREAM_FROM" -e "$STREAM_TO" -t "$STREAM_SECS"

    if [ "$HAS_RUMI_CLI" = true ]; then
        section "[Crypto] Live — Java subscribe (agg-stream slot freed)"
        shutdown_single "$API_SYSTEM" datafye-api-stream
        run_stream_test "Subscribe Live OHLC (Java)" "subscribe-live-ohlc-${pfx}-java" -s "$sym" -c "$LIVE_FREQ"
        run_stream_test "Subscribe Live SMA (Java)"  "subscribe-live-sma-${pfx}-java"  -s "$sym" -c "$LIVE_FREQ"
        run_stream_test "Subscribe Live EMA (Java)"  "subscribe-live-ema-${pfx}-java"  -s "$sym" -c "$LIVE_FREQ"
        section "[Crypto] Restoring recycled services"
        launch_single "$API_SYSTEM" datafye-api-stream
    else
        setup_warn "[Crypto] Java subscribe skipped — rumi CLI required to free an Ether slot"
    fi

    section "[Crypto] Backtest — Stop Replay"
    run_test "Stop Tick Replay (REST)" "stop-tick-replay-${pfx}-rest"
}

# --- driver: first dataset is already provisioned (Synthetic); enable indicators,
#     run it, then apply + run each remaining certifiable dataset. ---
enable_indicators
resolve_systems synthetic
recycle_agg_for_indicators synthetic

run_stocks_phase Synthetic

if [ "$RUN_CRYPTO" = true ]; then
    if apply_dataset SIP;    then run_stocks_phase SIP;   else CERT_UNCERTIFIED+=("SIP"); fi
    if apply_dataset Crypto; then run_crypto_phase;       else CERT_UNCERTIFIED+=("Crypto"); fi
else
    CERT_UNCERTIFIED+=("SIP" "Crypto")
fi

# ===========================================================================
# Coverage assertion
# ===========================================================================
section "Coverage"
COVERED_FILE="${COVERED_FILE:-${WORK_DIR}/covered-ids.txt}"
[ -f "$COVERED_FILE" ] && sort -u "$COVERED_FILE" -o "$COVERED_FILE" || : > "$COVERED_FILE"
# Expected ids = everything in run.sh, minus the SIP/Crypto-only ids if those
# datasets were not certified (Synthetic-only run). Crypto-only ids contain
# "-crypto"; the WS + ping ids are dataset-agnostic and always expected.
EXPECTED_FILE="${WORK_DIR}/expected-ids.txt"
cp "$ALL_IDS_FILE" "$EXPECTED_FILE"
if printf '%s\n' "${CERT_UNCERTIFIED[@]}" | grep -q '^Crypto$'; then
    grep -v -- '-crypto-' "$EXPECTED_FILE" > "${EXPECTED_FILE}.tmp" && mv "${EXPECTED_FILE}.tmp" "$EXPECTED_FILE"
fi
MISSED=$(comm -23 "$EXPECTED_FILE" "$COVERED_FILE")
COVN=$(wc -l < "$COVERED_FILE" | tr -d ' '); EXPN=$(wc -l < "$EXPECTED_FILE" | tr -d ' '); ALLN=$(wc -l < "$ALL_IDS_FILE" | tr -d ' ')
printf "    ${DIM}covered %s / %s expected (of %s registered)${RESET}\n" "$COVN" "$EXPN" "$ALLN"
if [ -n "$MISSED" ]; then
    FAILED=$((FAILED + 1))
    FAILURES="${FAILURES}\n    ${RED}✗${RESET} Coverage: samples never exercised:\n$(printf '        %s\n' $MISSED)"
    printf "    ${RED}✗ %s registered samples not exercised${RESET}\n" "$(printf '%s\n' "$MISSED" | grep -c .)"
else
    printf "    ${GREEN}✓ every expected sample was exercised${RESET}\n"
fi
if [ "${#CERT_UNCERTIFIED[@]}" -gt 0 ]; then
    printf "    ${YELLOW}! NOT CERTIFIED (no crypto-entitled POLYGON_API_KEY): %s${RESET}\n" "${CERT_UNCERTIFIED[*]}"
fi
# ===========================================================================
# Teardown
# ===========================================================================
section "Teardown"

setup_msg "Deprovisioning foundry..."
if [ "$VERBOSE" = true ]; then
    echo ""
    if "$DATAFYE_CLI" foundry local deprovision 2>&1 | tee "${LOG_DIR}/deprovision.log"; then
        setup_ok "Foundry deprovisioned"
    else
        printf "    ${YELLOW}!${RESET} Deprovision returned an error (see ${LOG_DIR}/deprovision.log)\n"
    fi
else
    if "$DATAFYE_CLI" foundry local deprovision &>"${LOG_DIR}/deprovision.log"; then
        setup_ok "Foundry deprovisioned"
    else
        printf "\r    ${YELLOW}!${RESET} Deprovision returned an error (see ${LOG_DIR}/deprovision.log)\n"
    fi
fi

# Remove DNS entries added during provisioning
if grep -q "$HOSTS_MARKER" /etc/hosts 2>/dev/null; then
    setup_msg "Removing DNS entries from /etc/hosts..."
    sed -i "/$HOSTS_MARKER/,/$HOSTS_MARKER/d" /etc/hosts 2>/dev/null \
        && setup_ok "DNS entries removed from /etc/hosts" \
        || setup_warn "Could not remove DNS entries from /etc/hosts"
fi

# ===========================================================================
# Summary
# ===========================================================================
summary

[ "$FAILED" -eq 0 ]
