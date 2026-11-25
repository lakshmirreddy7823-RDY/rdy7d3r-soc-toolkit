#!/usr/bin/env bash
###############################################################################
#                                                                             #
#   Project     : Linux System Installer                                      #
#   Author      : @RDY7D3R                                                    #
#   Version     : 2.0                                                         #
#   Description : Automated package installation and system configuration     #
#   Platform    : Debian | RHEL | Arch Linux                                  #
#   Shell       : Bash                                                        #
#                                                                             #
###############################################################################
set -Eeuo pipefail
LOG_FILE="/var/log/linux-installer.log"
PACKAGES=(
    tlp nginx sysstat  btop htop strace tshark hping3 openssh-server nmap netdiscover arp-scan wireshark tcpdump \
    termshark scalpel foremost sleuthkit iper mtr traceroute curl wget httpie siege apache2-utils netcat-openbsd \
    socat ncat telnet iftop nload
    bmon
    qrencode
    scrcpy
    adb
    metasploit-framework
    metasploit
    vnstat
    iptraf-ng
    nethogs
    softflowd
    pmacct
    aircrack-ng
    iw
    wavemon
    nftables
    iptables
    ufw
    firewalld
    conntrack
    rsync
    borgbackup
    restic
    rclone
    nmon
    binwalk
    docker.io
    podman
    qemu-kvm
    virt-manager
    libvirt-clients
    lxc
    gpg
    openssl
    cryptsetup
    tmux
    screen
    vim
    nano
    ripgrep
    fd-find
    lshw
    lscpu
    lsblk
    dmidecode
    stress-ng
    lm-sensors
    default-mysql-client
    postgresql-client
    git
    gcc
    make
    cmake
    gdb
    openvpn
    wireguard-tools
    sar
    vmstat
    iostat
    dstat
    glances
    iotop
    duf
    ncdu
    smartmontools
    hdparm
    inotify-tools
    lsof
    psmisc
    auditd
    systemd
    rsyslog
    logwatch
    logrotate
    multitail
    suricata
    snort
    zeek
    yara
    radare2
    ansible
)
if command -v tput >/dev/null 2>&1 && [[ -t 1 ]]; then
    RESET=$(tput sgr0)
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
else
    RESET=""
    BLACK=""
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
fi
_console() {
    local message="${1:-}"
    printf '%s - %b\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$message" | tee -a "$LOG_FILE"
}
_error_handler() {
    local exit_code=$?
    local line_no=$1
    _console "${RED}[ERROR] Script failed at line ${line_no} with exit code ${exit_code}.${RESET}"
    exit "$exit_code"
}
trap '_error_handler $LINENO' ERR
_check_root() {
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Please run this script as root.${RESET}"
        echo
        echo "Example:"
        echo "    sudo $0"
        exit 1
    fi
}
_check_dependencies() {
    local required_commands=(
        bash
        date
        tee
        awk
        grep
        sed
        tr
    )
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo -e "${RED}[ERROR] Required command not found: $cmd${RESET}"
            exit 1
        fi
    done
    touch "$LOG_FILE" 2>/dev/null || {
        echo -e "${RED}[ERROR] Cannot write to $LOG_FILE${RESET}"
        exit 1
    }
}
_banner() {
    cat <<'EOF'

██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗    ███████╗██╗  ██╗
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗   ██╔════╝██║  ██║
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝   ███████╗███████║
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗   ╚════██║██╔══██║
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║██╗███████║██║  ██║
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝
                           Linux Automation Framework
                                Created by @RDY7D3R
EOF
}
_check_os() {
    if [[ ! -f /etc/os-release ]]; then
        _console "${RED}[ERROR] /etc/os-release not found.${RESET}" && exit 1
    fi
    source /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_NAME="${NAME:-unknown}"
    case "$OS_ID" in
        ubuntu|debian|linuxmint|kali|zorin)
            OS_FAMILY="debian"
            ;;
        rhel|fedora|centos|rocky|almalinux|ol)
            OS_FAMILY="rhel"
            ;;
        arch|manjaro|endeavouros)
            OS_FAMILY="arch"
            ;;
        *)
            _console "${RED}[ERROR] Unsupported distribution: ${OS_ID}${RESET}"
            exit 1
            ;;
    esac
    _console "${GREEN}[+] Operating System: ${OS_NAME}${RESET}"
    _console "${GREEN}[+] OS ID: ${OS_ID}${RESET}"
    _console "${GREEN}[+] OS Family: ${OS_FAMILY}${RESET}"
}
_check_package_manager() {
    case "$OS_FAMILY" in
        debian)
            if command -v nala >/dev/null 2>&1; then
                PACKAGE_MANAGER="nala"
            elif command -v apt-get >/dev/null 2>&1; then
                PACKAGE_MANAGER="apt-get"
            elif command -v apt >/dev/null 2>&1; then
                PACKAGE_MANAGER="apt"
            else
                _console "${RED}[ERROR] No Debian package manager found.${RESET}"
                exit 1
            fi
            ;;
        rhel)
            if command -v dnf >/dev/null 2>&1; then
                PACKAGE_MANAGER="dnf"
            elif command -v yum >/dev/null 2>&1; then
                PACKAGE_MANAGER="yum"
            else
                _console "${RED}[ERROR] No RHEL package manager found.${RESET}"
                exit 1
            fi
            ;;
        arch)
            if command -v pacman >/dev/null 2>&1; then
                PACKAGE_MANAGER="pacman"
            else
                _console "${RED}[ERROR] pacman not found.${RESET}"
                exit 1
            fi
            ;;
    esac
    _console "${CYAN}[+] Package manager: ${PACKAGE_MANAGER}${RESET}"
}
_package_installed() {
    local package_name="$1"
    case "$OS_FAMILY" in
        debian)
            dpkg-query -W -f='${Status}' "$package_name" 2>/dev/null \
                | grep -q "install ok installed"
            ;;
        rhel)
            rpm -q "$package_name" >/dev/null 2>&1
            ;;
        arch)
            pacman -Q "$package_name" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}
_install_package() {
    local package_name="$1"
    if [[ -z "$package_name" ]]; then
        return 0
    fi
    if _package_installed "$package_name"; then
        _console "${CYAN}[=] ${package_name} is already installed.${RESET}"
        return 0
    fi
    _console "${YELLOW}[*] Installing ${package_name}...${RESET}"
    case "$OS_FAMILY" in
        debian)
            if [[ "$PACKAGE_MANAGER" == "nala" ]]; then
                if nala install -y "$package_name"; then
                    _console "${GREEN}[+] ${package_name} installed successfully.${RESET}"
                else
                    _console "${RED}[-] Failed to install ${package_name}.${RESET}"
                    return 1
                fi
            else
                if apt-get install -y "$package_name"; then
                    _console "${GREEN}[+] ${package_name} installed successfully.${RESET}"
                else
                    _console "${RED}[-] Failed to install ${package_name}.${RESET}"
                    return 1
                fi
            fi
            ;;
        rhel)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                if dnf install -y "$package_name"; then
                    _console "${GREEN}[+] ${package_name} installed successfully.${RESET}"
                else
                    _console "${RED}[-] Failed to install ${package_name}.${RESET}"
                    return 1
                fi
            else
                if yum install -y "$package_name"; then
                    _console "${GREEN}[+] ${package_name} installed successfully.${RESET}"
                else
                    _console "${RED}[-] Failed to install ${package_name}.${RESET}"
                    return 1
                fi
            fi
            ;;
        arch)
            if pacman -S --noconfirm "$package_name"; then
                _console "${GREEN}[+] ${package_name} installed successfully.${RESET}"
            else
                _console "${RED}[-] Failed to install ${package_name}.${RESET}"
                return 1
            fi
            ;;
    esac
    return 0
}
_update_repositories() {
    _console "${BLUE}[*] Updating package repositories...${RESET}"
    case "$OS_FAMILY" in
        debian)
            if [[ "$PACKAGE_MANAGER" == "nala" ]]; then
                nala update
            else
                apt-get update
            fi
            ;;
        rhel)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                dnf makecache
            else
                yum makecache
            fi
            ;;
        arch)
            pacman -Sy
            ;;
    esac
    _console "${GREEN}[+] Repository update completed.${RESET}"
}
_install_packages() {
    _console "${BLUE}[*] Starting package installation...${RESET}"
    local success_count=0
    local failed_count=0
    local package_name
    for package_name in "${PACKAGES[@]}"; do

        if [[ -z "$package_name" ]]; then
            continue
        fi
        if _install_package "$package_name"; then
            ((success_count++)) || true
        else
            ((failed_count++)) || true
        fi
    done
    echo
    _console "${GREEN}[+] Installation completed.${RESET}"
    _console "${GREEN}[+] Successful: ${success_count}${RESET}"
    _console "${RED}[-] Failed: ${failed_count}${RESET}"
}
SERVICES=(
    nginx
    ssh
    sshd
    docker
    firewalld
    nftables
    rsyslog
    auditd
    suricata
    snort
)
_test_services() {
    if ! command -v systemctl >/dev/null 2>&1; then
        _console "${YELLOW}[!] systemctl is not available. Skipping service checks.${RESET}"
        return 0
    fi
    _console "${BLUE}[*] Checking services...${RESET}"
    local service_name
    for service_name in "${SERVICES[@]}"; do
        if systemctl list-unit-files \
            --type=service \
            --no-legend \
            2>/dev/null \
            | awk '{print $1}' \
            | grep -Fxq "${service_name}.service"; then
            _console "${CYAN}[*] Checking ${service_name}...${RESET}"
            if systemctl is-active --quiet "$service_name"; then
                _console "${GREEN}[+] ${service_name} is running.${RESET}"
            else
                _console "${YELLOW}[!] ${service_name} is not running.${RESET}"
                read -rp "Start ${service_name}? [y/N]: " answer
                case "$answer" in
                    y|Y|yes|YES)
                        if systemctl enable --now "$service_name"; then
                            _console "${GREEN}[+] ${service_name} started.${RESET}"
                        else
                            _console "${RED}[-] Failed to start ${service_name}.${RESET}"
                        fi
                        ;;
                    *)
                        _console "${YELLOW}[-] Skipping ${service_name}.${RESET}"
                        ;;
                esac
            fi
        else
            _console "${BLACK}[ ] ${service_name} is not installed.${RESET}"
        fi
    done
}
_setup_install() {
    echo
    _console "${BLUE}[*] Installation verification:${RESET}"
    printf '\n'
    printf '%-25s | %-15s | %s\n' "PACKAGE" "STATUS" "COMMAND"
    printf '%s\n' "---------------------------------------------------------------"
    local package_name
    local command_path
    for package_name in "${PACKAGES[@]}"; do
        command_path=""
        if _package_installed "$package_name"; then
            if command_path=$(command -v "$package_name" 2>/dev/null); then
                printf '%-25s | %-15s | %s\n' \
                    "$package_name" \
                    "Installed" \
                    "$command_path"
            else
                printf '%-25s | %-15s | %s\n' \
                    "$package_name" \
                    "Installed" \
                    "N/A"
            fi
        else
            printf '%-25s | %-15s | %s\n' \
                "$package_name" \
                "Not installed" \
                "N/A"
        fi
    done
}
_process_services() {
    if ! command -v systemctl >/dev/null 2>&1; then
        _console "${YELLOW}[!] systemctl unavailable. Skipping service status.${RESET}"
        return 0
    fi
    echo
    _console "${BLUE}[*] Active service summary:${RESET}"
    systemctl list-units \
        --type=service \
        --state=running \
        --no-pager \
        --no-legend 2>/dev/null \
        | awk '{print $1}' \
        | head -50
}
_installer() {
    while true; do
        echo
        printf '%s\n' "${CYAN}==============================================${RESET}"
        printf '%s\n' "${CYAN}             INSTALLATION MENU                ${RESET}"
        printf '%s\n' "${CYAN}==============================================${RESET}"
        printf "${GREEN}1. Install packages${RESET}\n"
        printf "${CYAN}2. Check services${RESET}\n"
        printf "${BLUE}3. Verify installation${RESET}\n"
        printf "${MAGENTA}4. Show running services${RESET}\n"
        printf "${RED}5. Exit${RESET}\n"
        echo
        read -rp "Select an option [1-5]: " choice
        case "$choice" in
            1)
                _update_repositories || {
                    _console "${RED}[ERROR] Repository update failed.${RESET}"
                }
                _install_packages
                ;;
            2)
                _test_services
                ;;
            3)
                _setup_install
                ;;
            4)
                _process_services
                ;;
            5)
                _console "${GREEN}[+] Exiting installer.${RESET}"
                return 0
                ;;
            "")
                _console "${RED}[-] No option selected.${RESET}"
                ;;
            *)
                _console "${RED}[-] Invalid option: ${choice}${RESET}"
                _console "${YELLOW}[!] Please enter a number from 1 to 5.${RESET}"
                ;;
        esac
    done
}
_main() {
    _check_root
    _check_dependencies
    _banner
    _console "${BLUE}[*] Linux System Installer starting...${RESET}"
    _check_os
    _check_package_manager
    echo
    _installer
    echo
    _console "${GREEN}[+] Installer finished.${RESET}"
    _console "${GREEN}[+] Log file: ${LOG_FILE}${RESET}"
}
_main "$@"
