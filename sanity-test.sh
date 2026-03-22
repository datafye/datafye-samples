#!/usr/bin/env bash
# =============================================================================
# sanity-test.sh
#
# End-to-end sanity test for a Datafye Data Cloud Only Foundry.
#
# Provisions a local foundry, exercises the Data Cloud API samples across
# health, reference data, OHLC download, historical aggregate fetch, and
# historical aggregate streaming, then deprovisions the environment.
#
# Run from the root of the datafye-samples repo:
#
#   bash sanity-test.sh                                  # Synthetic data
#   POLYGON_API_KEY="key" bash sanity-test.sh            # SIP (real market data)
#
# Supported platforms:
#   - Amazon Linux 2 or 2023
#   - RHEL, CentOS, Fedora, Rocky Linux, AlmaLinux
#   - Ubuntu/Debian (including WSL on Windows)
#   - macOS (Homebrew)
#
# Prerequisites: sudo access (Linux), Homebrew (macOS).
# The script installs Java 17, Maven, and the Datafye CLI if not present.
# =============================================================================
set -uo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR="${WORK_DIR:-/tmp/datafye-sanity-test}"
LOG_DIR="${WORK_DIR}/logs"
SYMBOL="AAPL"

if [ -n "${POLYGON_API_KEY:-}" ]; then
    DATASET="SIP"
    DESCRIPTOR_URL="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-sip.yaml"
else
    DATASET="Synthetic"
    DESCRIPTOR_URL="https://downloads.n5corp.com/datafye/quickstarts/latest/foundry-data-cloud-only-with-synthetic.yaml"
fi

# Test date: 30 days ago (within the 90-day window the quickstart provisions)
TEST_DATE=$(date -d "-30 days" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d)
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

    t_start=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
    if "${DIST_DIR}/bin/run.sh" "$sample" "$@" >"$logfile" 2>&1; then
        t_end=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
        elapsed=$(( (t_end - t_start) / 1000000 ))
        printf "${GREEN}PASS${RESET}  ${DIM}%s${RESET}\n" "$(format_ms $elapsed)"
        PASSED=$((PASSED + 1))
    else
        t_end=$(date +%s%N 2>/dev/null || echo $(($(date +%s) * 1000000000)))
        elapsed=$(( (t_end - t_start) / 1000000 ))
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

# ---------------------------------------------------------------------------
# Setup: prerequisites
# ---------------------------------------------------------------------------
banner

section "Setup"

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
MEM_TOTAL_GB=$(( MEM_TOTAL_MB / 1024 ))

# macOS and WSL need 12GB (Docker Desktop overhead); native Linux needs 8GB
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
# Find the mount point with the most available space
if [ "$DISTRO" = "macos" ]; then
    # macOS df uses 512-byte blocks by default; use -g for GB
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

# --- Helpers ---
IS_ROOT=false
[ "$(id -u)" -eq 0 ] && IS_ROOT=true

pkg_install() {
    case "$PKG_MGR" in
        apt)  sudo apt-get install -y -qq "$@" &>/dev/null ;;
        dnf)  sudo dnf install -y "$@" &>/dev/null ;;
        yum)  sudo yum install -y "$@" &>/dev/null ;;
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
    sudo mkdir -p "$plugin_dir"
    sudo curl -fsSL "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-linux-${arch}" \
        -o "$plugin_dir/docker-compose"
    sudo chmod +x "$plugin_dir/docker-compose"
}

# --- Docker ---
if [ "$DISTRO" = "macos" ]; then
    # macOS: Docker Desktop required
    if ! command -v docker &>/dev/null || ! docker info &>/dev/null 2>&1; then
        fail_setup "Docker Desktop is not running. Install it from https://docs.docker.com/desktop/install/mac-install/ and start it."
    fi
    setup_ok "Docker Desktop $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
else
    # Linux: check, install if root, or fail with guidance
    if command -v docker &>/dev/null; then
        if docker info &>/dev/null 2>&1; then
            setup_ok "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
        elif [ "$IS_ROOT" = false ]; then
            fail_setup "Docker is installed but not accessible. Add your user to the docker group:
      sudo usermod -aG docker \$USER
    Then log out and back in, or run: newgrp docker"
        else
            # root but daemon not running — try to start it
            setup_msg "Starting Docker daemon..."
            sudo systemctl start docker &>/dev/null && sudo systemctl enable docker &>/dev/null \
                || fail_setup "Docker daemon failed to start"
            setup_ok "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null)"
        fi
    elif [ "$IS_ROOT" = false ]; then
        fail_setup "Docker is not installed. Install it and add your user to the docker group:
      sudo yum install -y docker        # Amazon Linux
      sudo systemctl start docker
      sudo systemctl enable docker
      sudo usermod -aG docker \$USER
    Then log out and back in, and re-run this script."
    else
        setup_msg "Installing Docker..."
        case "$DISTRO" in
            amzn)
                pkg_install docker || fail_setup "Docker installation failed"
                ;;
            ubuntu|debian)
                sudo apt-get update -qq &>/dev/null
                sudo apt-get install -y -qq ca-certificates curl gnupg lsb-release &>/dev/null
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL "https://download.docker.com/linux/$DISTRO/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$DISTRO \
                    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
                sudo apt-get update -qq &>/dev/null
                sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>/dev/null \
                    || fail_setup "Docker installation failed"
                ;;
            centos|rhel|fedora|rocky|almalinux)
                sudo yum install -y yum-utils &>/dev/null
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo &>/dev/null
                sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>/dev/null \
                    || fail_setup "Docker installation failed"
                ;;
            *)
                fail_setup "Cannot install Docker automatically on ${DISTRO}. Please install Docker manually."
                ;;
        esac
        sudo systemctl start docker &>/dev/null && sudo systemctl enable docker &>/dev/null \
            || fail_setup "Docker installed but daemon failed to start"
        if docker info &>/dev/null 2>&1; then
            setup_ok "Docker $(docker version --format '{{.Server.Version}}' 2>/dev/null) (installed)"
        else
            fail_setup "Docker installation failed"
        fi
    fi

    # --- Docker Compose ---
    if has_docker_compose; then
        setup_ok "Docker Compose $(docker compose version --short 2>/dev/null || docker-compose version --short 2>/dev/null)"
    elif [ "$IS_ROOT" = true ]; then
        setup_msg "Installing Docker Compose..."
        install_docker_compose || fail_setup "Docker Compose installation failed"
        setup_ok "Docker Compose $(docker compose version --short 2>/dev/null)"
    else
        fail_setup "Docker Compose is not installed. Re-run as root to install it, or install manually."
    fi
fi

# --- Git ---
if ! command -v git &>/dev/null; then
    setup_msg "Installing git..."
    if [ "$PKG_MGR" = "apt" ]; then
        sudo apt-get update -qq &>/dev/null
    fi
    pkg_install git || fail_setup "git installation failed"
    setup_ok "git"
fi

# --- Java 17 ---
if java -version 2>&1 | grep -q '"17\.'; then
    if [ "$DISTRO" = "macos" ]; then
        JAVA_HOME_DIR=$(/usr/libexec/java_home -v 17 2>/dev/null)
    else
        JAVA_HOME_DIR=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
    fi
else
    setup_msg "Installing Java 17..."
    case "$PKG_MGR" in
        apt)
            sudo apt-get update -qq &>/dev/null
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
                sudo rpm --import https://yum.corretto.aws/corretto.key 2>/dev/null || true
                sudo curl -sLo /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
                pkg_install java-17-amazon-corretto-devel || fail_setup "Java 17 installation failed"
            fi
            ;;
        brew)
            pkg_install openjdk@17 || fail_setup "Java 17 installation failed"
            ;;
    esac
    if [ "$DISTRO" = "macos" ]; then
        JAVA_HOME_DIR=$(/usr/libexec/java_home -v 17 2>/dev/null || echo "$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home")
    else
        JAVA_HOME_DIR=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
    fi
fi
export JAVA_HOME="${JAVA_HOME_DIR}"
export PATH="${JAVA_HOME}/bin:${PATH}"
setup_ok "Java $(java -version 2>&1 | head -1 | sed 's/.*"\(.*\)"/\1/')"

# --- Maven ---
if ! command -v mvn &>/dev/null; then
    setup_msg "Installing Maven..."
    if [ "$PKG_MGR" = "brew" ]; then
        pkg_install maven || fail_setup "Maven installation failed"
    else
        MAVEN_VERSION="3.9.6"
        curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" \
            | sudo tar -xz -C /opt || fail_setup "Maven installation failed"
        sudo ln -sf "/opt/apache-maven-${MAVEN_VERSION}/bin/mvn" /usr/local/bin/mvn
    fi
fi
setup_ok "Maven $(mvn --version 2>/dev/null | head -1 | sed 's/Apache Maven \([^ ]*\).*/\1/')"

# --- Datafye CLI ---
if ! command -v datafye &>/dev/null; then
    setup_msg "Installing Datafye CLI..."
    curl -fsSL https://downloads.n5corp.com/datafye/cli/latest/install.sh | sudo bash &>/dev/null \
        || fail_setup "Datafye CLI installation failed"
fi
setup_ok "Datafye CLI $(datafye --version 2>/dev/null | head -1)"

# ---------------------------------------------------------------------------
# Setup: build
# ---------------------------------------------------------------------------
section "Build"

mkdir -p "$WORK_DIR" "$LOG_DIR"

setup_msg "Building samples..."
export MAVEN_OPTS="-Xmx2g --add-exports=java.base/sun.nio.ch=ALL-UNNAMED --add-opens=java.base/java.nio=ALL-UNNAMED --add-opens=java.base/jdk.internal.ref=ALL-UNNAMED"
if (cd "${REPO_DIR}" && mvn clean install -q) &>"${LOG_DIR}/build.log"; then
    setup_ok "Build complete"
else
    fail_setup "Build failed (see ${LOG_DIR}/build.log)"
fi

setup_msg "Extracting distribution..."
DIST_TAR=$(ls "${REPO_DIR}/target/"*-distribution.tar.gz 2>/dev/null | head -1)
if [ -z "$DIST_TAR" ]; then
    fail_setup "Distribution archive not found"
fi
tar -xzf "$DIST_TAR" -C "${WORK_DIR}"
DIST_DIR=$(find "${WORK_DIR}" -maxdepth 1 -type d -name "datafye-samples-*" | head -1)
setup_ok "Distribution ready"

# ---------------------------------------------------------------------------
# Setup: provision
# ---------------------------------------------------------------------------
section "Provision"

setup_msg "Downloading quickstart descriptor..."
curl -fsSL -o "${WORK_DIR}/quickstart.yaml" "$DESCRIPTOR_URL" || fail_setup "Descriptor download failed"
setup_ok "Descriptor downloaded (${DATASET})"

setup_msg "Provisioning foundry (this may take a few minutes)..."
if datafye foundry local provision --descriptor "${WORK_DIR}/quickstart.yaml" &>"${LOG_DIR}/provision.log"; then
    setup_ok "Foundry provisioned"
else
    fail_setup "Provisioning failed (see ${LOG_DIR}/provision.log)"
fi

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

section "Health"
run_test "Ping (REST)" \
    ping-rest

section "Reference Data"
run_test "Get Securities (REST)" \
    get-securities-rest
run_test "Get Securities (Java)" \
    get-securities-java

section "Backtesting — Download OHLC"
run_test "Download Minute OHLC (Java, --wait)" \
    start-ohlc-download-java -d "$TEST_DATE" -s "$SYMBOL" -c Minute -w

section "Historical Aggregates — Fetch"
run_test "Fetch Historical OHLC (REST)" \
    get-historical-ohlc-rest -s "$SYMBOL" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO"
run_test "Fetch Historical OHLC (Java)" \
    get-historical-ohlc-java -s "$SYMBOL" -c Minute -f "$STREAM_FROM" -t "$STREAM_TO"
run_test "Fetch Historical Top Gainers (REST)" \
    get-historical-top-gainers-rest -d "$TEST_DATE"
run_test "Fetch Historical Top Gainers (Java)" \
    get-historical-top-gainers-java -d "$TEST_DATE"

section "Historical Aggregates — Stream"
run_test "Stream Historical OHLC (Java)" \
    stream-historical-ohlc-java -s "$SYMBOL" -f "$STREAM_FROM" -t "$STREAM_TO"

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------
section "Teardown"

setup_msg "Deprovisioning foundry..."
if datafye foundry local deprovision &>"${LOG_DIR}/deprovision.log"; then
    setup_ok "Foundry deprovisioned"
else
    printf "\r    ${YELLOW}!${RESET} Deprovision returned an error (see ${LOG_DIR}/deprovision.log)\n"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
summary

[ "$FAILED" -eq 0 ]
