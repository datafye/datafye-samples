#!/usr/bin/env bash
# =============================================================================
# sanity-test.sh
#
# End-to-end sanity test for a Datafye Data Cloud Only Foundry.
#
# Provisions a local foundry, exercises the Data Cloud API samples across
# health, reference data, backtest tick download, historical aggregate fetch
# and streaming, live data (fetch, Java subscribe, and WebSocket streaming
# driven by a tick replay), then deprovisions the environment. With --crypto
# and a crypto-entitled POLYGON_API_KEY, it also provisions a Crypto dataset
# and runs the equivalent crypto samples.
#
# Run from the root of the datafye-samples repo:
#
#   sudo bash sanity-test.sh                                  # Synthetic data
#   sudo -E bash sanity-test.sh                               # SIP (if POLYGON_API_KEY is exported)
#   sudo POLYGON_API_KEY="key" bash sanity-test.sh            # SIP (inline)
#   sudo -E bash sanity-test.sh --crypto                      # SIP + Crypto (requires POLYGON_API_KEY)
#   sudo bash sanity-test.sh -v                               # Verbose (show sample output)
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
CRYPTO_SYMBOL="BTCUSD"

# Live subscribe / WebSocket samples stream for a bounded window. STREAM_SECS is
# how long each streams; BOUNDED_TIMEOUT is the outer kill switch (the Java
# subscribe samples have no built-in duration, so we bound them ourselves).
STREAM_SECS="${STREAM_SECS:-20}"
BOUNDED_TIMEOUT=$((STREAM_SECS + 15))

if [ -n "${POLYGON_API_KEY:-}" ]; then
    DATASET="SIP"
    DESCRIPTOR_URL="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-sip.yaml"
else
    DATASET="Synthetic"
    DESCRIPTOR_URL="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-synthetic.yaml"
fi

# The crypto phase needs a crypto-entitled Polygon key. Without one we cannot
# provision a Crypto dataset, so disable the phase rather than fail later.
if [ "$RUN_CRYPTO" = true ] && [ -z "${POLYGON_API_KEY:-}" ]; then
    echo "--crypto requires POLYGON_API_KEY (crypto-entitled); skipping the crypto phase." >&2
    RUN_CRYPTO=false
fi

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

# Run a sample for a bounded window, then kill it. run.sh execs the JVM, so the
# backgrounded PID is the JVM and a plain kill stops it (avoids depending on
# `timeout`/`gtimeout`, which are absent on stock macOS). Writes the sample
# output to $1 (logfile); remaining args are the sample id and its options.
_bounded_run() {
    local logfile="$1"; shift
    "${DIST_DIR}/bin/run.sh" "$@" >"$logfile" 2>&1 &
    local pid=$!
    local waited=0
    while kill -0 "$pid" 2>/dev/null && [ "$waited" -lt "$BOUNDED_TIMEOUT" ]; do
        sleep 1
        waited=$((waited + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        pkill -P "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null || true
}

# Run a streaming/subscribe sample and PASS if it received at least one inbound
# record. Every subscribe (Java) and WebSocket sample prints received data with
# a leading "<-- " marker, so we judge success by data flow rather than exit
# code (the unbounded Java subscribers are killed by _bounded_run, and a kill
# is not a failure here). Usage: run_stream_test <label> <sample> [args...]
run_stream_test() {
    local label="$1"; shift
    local sample="$1"; shift
    TOTAL=$((TOTAL + 1))

    local index_str
    index_str=$(printf "%2d" "$TOTAL")
    printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    local logfile="${LOG_DIR}/${TOTAL}-${sample}.log"
    local t_start t_end elapsed
    [ "$VERBOSE" = true ] && echo ""

    t_start=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    _bounded_run "$logfile" "$sample" "$@"
    [ "$VERBOSE" = true ] && cat "$logfile"
    t_end=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    elapsed=$(( (t_end - t_start) / 1000000 ))

    [ "$VERBOSE" = true ] && printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    local received
    received=$(grep -c '^<-- ' "$logfile" 2>/dev/null || echo 0)
    if [ "$received" -gt 0 ]; then
        printf "${GREEN}PASS${RESET}  ${DIM}%s, %s records${RESET}\n" "$(format_ms $elapsed)" "$received"
        PASSED=$((PASSED + 1))
    else
        printf "${RED}FAIL${RESET}  ${DIM}%s, no data${RESET}\n" "$(format_ms $elapsed)"
        FAILED=$((FAILED + 1))
        FAILURES="${FAILURES}\n    ${RED}✗${RESET} ${label}  ${DIM}(log: ${logfile})${RESET}"
    fi
}

# Like run_stream_test, but non-fatal. The Java client's live stream subscription
# binds the feed/agg stream bus directly and only delivers data when the client is
# co-located with the services (AWS, or inside the Docker network). From the host
# against a local Docker foundry the stream connection establishes but no data
# arrives, so "no data" is reported as a skip, not a failure. On a co-located/AWS
# run it passes like any other stream test. (WebSocket streaming, which rides the
# api-stream service over TCP, is the supported local subscribe path and is tested
# strictly above.) Usage: run_stream_soft <label> <sample> [args...]
run_stream_soft() {
    local label="$1"; shift
    local sample="$1"; shift
    TOTAL=$((TOTAL + 1))

    local index_str
    index_str=$(printf "%2d" "$TOTAL")
    printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    local logfile="${LOG_DIR}/${TOTAL}-${sample}.log"
    local t_start t_end elapsed
    [ "$VERBOSE" = true ] && echo ""

    t_start=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    _bounded_run "$logfile" "$sample" "$@"
    [ "$VERBOSE" = true ] && cat "$logfile"
    t_end=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    elapsed=$(( (t_end - t_start) / 1000000 ))

    [ "$VERBOSE" = true ] && printf "    ${DIM}[%s]${RESET}  %-44s" "$index_str" "$label"

    local received
    received=$(grep -c '^<-- ' "$logfile" 2>/dev/null || echo 0)
    if [ "$received" -gt 0 ]; then
        printf "${GREEN}PASS${RESET}  ${DIM}%s, %s records${RESET}\n" "$(format_ms $elapsed)" "$received"
        PASSED=$((PASSED + 1))
    else
        printf "${YELLOW}SKIP${RESET}  ${DIM}no data — Java client streaming needs a co-located/AWS deployment${RESET}\n"
        SKIPPED=$((SKIPPED + 1))
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

if [ "$RUN_CRYPTO" = true ]; then
    # The installed CLI has no runtime `dataset add`, so to run stocks and crypto
    # against one foundry we provision a combined descriptor (SIP + a lean Crypto
    # dataset). ${POLYGON_API_KEY} is left literal for the CLI to substitute, so
    # the heredoc delimiter is quoted to prevent the shell from expanding it.
    setup_msg "Writing combined SIP + Crypto descriptor..."
    cat > "${WORK_DIR}/quickstart.yaml" <<'EOF'
apiVersion: datafye.io/v1
metadata:
  name: foundry-sanity-sip-crypto
  description: Data Cloud with SIP + Crypto for the sanity test
mode: backtest
datasets:
  - dataset: SIP
    provider: Polygon
    symbols:
      tickers:
        - AAPL
        - MSFT
        - GOOGL
        - AMZN
        - TSLA
        - NVDA
        - META
        - NFLX
        - AMD
        - INTC
    history:
      ticks:
        - { schema: trades, duration: 90d }
        - { schema: quotes, duration: 90d }
      aggregates:
        - { schema: ohlc-1m, duration: 90d }
  - dataset: Crypto
    provider: Polygon
    symbols:
      tickers:
        - BTCUSD
    history:
      ticks:
        - { schema: trades, duration: 90d }
        - { schema: quotes, duration: 90d }
      aggregates:
        - { schema: ohlc-1m, duration: 90d }
credentials:
  polygon_api_key: ${POLYGON_API_KEY}
EOF
    setup_ok "Combined descriptor written (SIP + Crypto)"
else
    setup_msg "Downloading quickstart descriptor..."
    curl -fsSL -o "${WORK_DIR}/quickstart.yaml" "$DESCRIPTOR_URL" || fail_setup "Descriptor download failed"
    setup_ok "Descriptor downloaded (${DATASET})"
fi

setup_msg "Provisioning foundry (this may take a few minutes)..."
if [ "$VERBOSE" = true ]; then
    echo ""
    if datafye foundry local provision --descriptor "${WORK_DIR}/quickstart.yaml" 2>&1 | tee "${LOG_DIR}/provision.log"; then
        setup_ok "Foundry provisioned"
    else
        fail_setup "Provisioning failed (see ${LOG_DIR}/provision.log)"
    fi
else
    if datafye foundry local provision --descriptor "${WORK_DIR}/quickstart.yaml" &>"${LOG_DIR}/provision.log"; then
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
# Tests
# ===========================================================================
# Java + WebSocket samples take an explicit dataset; REST samples accept -D too
# (the dataset is sent as a query parameter). Pass the dataset everywhere so the
# same flow works for both SIP and Synthetic. Live aggregate subscribe/stream use
# Second bars so a bar finalises within the bounded streaming window.
LIVE_FREQ="${LIVE_FREQ:-Second}"

section "Health"
run_test "Ping (REST)" \
    ping-rest -d "$DATASET"

section "Reference Data"
run_test "Get Securities (REST)" \
    get-securities-stocks-rest -D "$DATASET"
run_test "Get Securities (Java)" \
    get-securities-stocks-java -D "$DATASET"

section "Backtesting — Download OHLC"
run_test "Download Minute OHLC (REST, --wait)" \
    start-ohlc-download-stocks-rest -D "$DATASET" -d "$TEST_DATE" -s "$SYMBOL" -c Minute -w
run_test "Download Minute OHLC (Java, --wait)" \
    start-ohlc-download-stocks-java -d "$TEST_DATE" -s "$SYMBOL" -c Minute -w -D "$DATASET"

section "Historical Aggregates — Fetch"
run_test "Fetch Historical OHLC (REST)" \
    get-historical-ohlc-stocks-rest -D "$DATASET" -s "$SYMBOL" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO"
run_test "Fetch Historical OHLC (Java)" \
    get-historical-ohlc-stocks-java -s "$SYMBOL" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO" -D "$DATASET"
run_test "Fetch Historical Top Gainers (REST)" \
    get-historical-top-gainers-stocks-rest -D "$DATASET" -d "$TEST_DATE"
run_test "Fetch Historical Top Gainers (Java)" \
    get-historical-top-gainers-stocks-java -d "$TEST_DATE" -D "$DATASET"

section "Historical Aggregates — Stream"
run_test "Stream Historical OHLC (Java)" \
    stream-historical-ohlc-stocks-java -s "$SYMBOL" -f "$STREAM_FROM" -t "$STREAM_TO" -D "$DATASET"
run_stream_test "Stream Historical OHLC (WS)" \
    stream-historical-ohlc-ws -d "$DATASET" -s "$SYMBOL" -f Minute -b "$STREAM_FROM" -e "$STREAM_TO" -t "$STREAM_SECS"

# Live data only exists while a tick replay is running, so download a day of
# ticks, start the replay, exercise the live samples, then stop the replay.
section "Backtesting — Download Ticks"
run_test "Download Ticks (REST, --wait)" \
    start-tick-download-stocks-rest -D "$DATASET" -d "$TEST_DATE" -s "$SYMBOL" -w

section "Backtesting — Start Replay"
run_test "Start Tick Replay (REST)" \
    start-tick-replay-stocks-rest -D "$DATASET" -d "$TEST_DATE"
if wait_replay_running is-tick-replay-running-stocks-rest -D "$DATASET"; then
    setup_ok "Tick replay is running"
else
    setup_warn "Tick replay did not report running; live samples may see no data"
fi

section "Live — Fetch"
run_test "Fetch Live OHLC (REST)" \
    get-live-ohlc-stocks-rest -D "$DATASET" -s "$SYMBOL"
run_test "Fetch Live OHLC (Java)" \
    get-live-ohlc-stocks-java -s "$SYMBOL" -D "$DATASET"
run_test "Fetch Live Top-of-Book (REST)" \
    get-live-top-of-book-stocks-rest -D "$DATASET" -s "$SYMBOL"
run_test "Fetch Live Top-of-Book (Java)" \
    get-live-top-of-book-stocks-java -s "$SYMBOL" -D "$DATASET"
run_test "Fetch Live Last Trade (REST)" \
    get-live-last-trade-stocks-rest -D "$DATASET" -s "$SYMBOL"
run_test "Fetch Live Last Trade (Java)" \
    get-live-last-trade-stocks-java -s "$SYMBOL" -D "$DATASET"
run_test "Fetch Live SMA (REST)" \
    get-live-sma-stocks-rest -D "$DATASET" -s "$SYMBOL"
run_test "Fetch Live EMA (REST)" \
    get-live-ema-stocks-rest -D "$DATASET" -s "$SYMBOL"

section "Live — Subscribe (Java)"
# Soft (non-fatal): the Java client streams over the feed/agg bus and only delivers
# data when co-located with the services (AWS / inside the Docker network), not from
# the host against local Docker. WebSocket streaming below is the local subscribe path.
run_stream_soft "Subscribe Live Top-of-Book (Java)" \
    subscribe-live-top-of-book-stocks-java -D "$DATASET" -s "$SYMBOL"
run_stream_soft "Subscribe Live Trades (Java)" \
    subscribe-live-trades-stocks-java -D "$DATASET" -s "$SYMBOL"
run_stream_soft "Subscribe Live OHLC (Java)" \
    subscribe-live-ohlc-stocks-java -D "$DATASET" -s "$SYMBOL" -c "$LIVE_FREQ"
run_stream_soft "Subscribe Live SMA (Java)" \
    subscribe-live-sma-stocks-java -D "$DATASET" -s "$SYMBOL" -c "$LIVE_FREQ"
run_stream_soft "Subscribe Live EMA (Java)" \
    subscribe-live-ema-stocks-java -D "$DATASET" -s "$SYMBOL" -c "$LIVE_FREQ"

section "WebSocket Streaming"
run_stream_test "Subscribe Live Trades (WS)" \
    subscribe-live-trades-ws -d "$DATASET" -s "$SYMBOL" -t "$STREAM_SECS"
run_stream_test "Subscribe Live Quotes (WS)" \
    subscribe-live-top-of-book-ws -d "$DATASET" -s "$SYMBOL" -t "$STREAM_SECS"
run_stream_test "Subscribe Live OHLC (WS)" \
    subscribe-live-ohlc-ws -d "$DATASET" -s "$SYMBOL" -f "$LIVE_FREQ" -t "$STREAM_SECS"
run_stream_test "Subscribe Live SMA (WS)" \
    subscribe-live-sma-ws -d "$DATASET" -s "$SYMBOL" -f "$LIVE_FREQ" -t "$STREAM_SECS"
run_stream_test "Subscribe Live EMA (WS)" \
    subscribe-live-ema-ws -d "$DATASET" -s "$SYMBOL" -f "$LIVE_FREQ" -t "$STREAM_SECS"

section "Backtesting — Stop Replay"
run_test "Stop Tick Replay (REST)" \
    stop-tick-replay-stocks-rest -D "$DATASET"

# ---------------------------------------------------------------------------
# Crypto phase (optional, --crypto + crypto-entitled POLYGON_API_KEY).
# Crypto samples are dataset-fixed (no -D); WebSocket samples select Crypto via -d.
# ---------------------------------------------------------------------------
if [ "$RUN_CRYPTO" = true ]; then
    section "Crypto — Reference & Backtest"
    run_test "Get Crypto Securities (REST)" \
        get-securities-crypto-rest
    run_test "Download Crypto Ticks (REST, --wait)" \
        start-tick-download-crypto-rest -d "$TEST_DATE" -s "$CRYPTO_SYMBOL" -w
    run_test "Start Crypto Tick Replay (REST)" \
        start-tick-replay-crypto-rest -d "$TEST_DATE"
    if wait_replay_running is-tick-replay-running-crypto-rest; then
        setup_ok "Crypto tick replay is running"
    else
        setup_warn "Crypto tick replay did not report running; live crypto samples may see no data"
    fi

    section "Crypto — Live Fetch"
    run_test "Fetch Live Crypto OHLC (REST)" \
        get-live-ohlc-crypto-rest -s "$CRYPTO_SYMBOL"
    run_test "Fetch Live Crypto OHLC (Java)" \
        get-live-ohlc-crypto-java -s "$CRYPTO_SYMBOL"
    run_test "Fetch Live Crypto Top-of-Book (REST)" \
        get-live-top-of-book-crypto-rest -s "$CRYPTO_SYMBOL"

    section "Crypto — Subscribe & WebSocket"
    run_stream_soft "Subscribe Live Crypto OHLC (Java)" \
        subscribe-live-ohlc-crypto-java -s "$CRYPTO_SYMBOL" -c "$LIVE_FREQ"
    run_stream_test "Subscribe Live Crypto Trades (WS)" \
        subscribe-live-trades-ws -d Crypto -s "$CRYPTO_SYMBOL" -t "$STREAM_SECS"
    run_stream_test "Subscribe Live Crypto OHLC (WS)" \
        subscribe-live-ohlc-ws -d Crypto -s "$CRYPTO_SYMBOL" -f "$LIVE_FREQ" -t "$STREAM_SECS"

    section "Crypto — Stop Replay"
    run_test "Stop Crypto Tick Replay (REST)" \
        stop-tick-replay-crypto-rest
fi

# ===========================================================================
# Teardown
# ===========================================================================
section "Teardown"

setup_msg "Deprovisioning foundry..."
if [ "$VERBOSE" = true ]; then
    echo ""
    if datafye foundry local deprovision 2>&1 | tee "${LOG_DIR}/deprovision.log"; then
        setup_ok "Foundry deprovisioned"
    else
        printf "    ${YELLOW}!${RESET} Deprovision returned an error (see ${LOG_DIR}/deprovision.log)\n"
    fi
else
    if datafye foundry local deprovision &>"${LOG_DIR}/deprovision.log"; then
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
