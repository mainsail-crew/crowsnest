is_raspios() {
    if [[ -f /etc/rpi-issue ]]; then
        echo "1"
    else
        echo "0"
    fi
}

is_dietpi() {
    if [[ -f /boot/config.txt ]] && [[ -d /boot/dietpi ]]; then
        echo "1"
    else
        echo "0"
    fi
}

is_buster() {
    if [[ -f /etc/os-release ]]; then
        grep -cq "buster" /etc/os-release &> /dev/null && echo "1" || echo "0"
    fi
}

is_bookworm() {
    if [[ -f /etc/os-release ]]; then
        grep -cq "bookworm" /etc/os-release &> /dev/null && echo "1" || echo "0"
    fi
}

is_raspberry_pi() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

is_pi5() {
    if [[ -f /proc/device-tree/model ]] &&
    grep -q "Raspberry Pi 5" /proc/device-tree/model; then
        echo "1"
    else
        echo "0"
    fi
}

is_speederpad() {
    if grep -q "Ubuntu 20.04." /etc/os-release &&
    [[ "$(uname -rm)" = "4.9.191 aarch64" ]]; then
        echo "1"
    else
        echo "0"
    fi
}

use_cs() {
    if { [[ "$(is_raspios)" = "1" ]] ||
    [[ "$(is_dietpi)" = "1" ]]; } &&
    [[ "$(is_pi5)" = "0" ]]; then
        echo "1"
    else
        echo "0"
    fi
}
