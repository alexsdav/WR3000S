#!/bin/sh

# Функция для проверки и выхода при ошибке
check_error() {
    if [ $? -ne 0 ]; then
        printf "\033[31;1mERROR: %s\033[0m\n" "$1"
        exit 1
    fi
}

# Функция проверки на пустоту
check_empty() {
    if [ -z "$1" ]; then
        printf "\033[31;1mERROR: %s is empty!\033[0m\n" "$2"
        exit 1
    fi
}

# Получаем данные
BOARD_INFO=$(ubus call system board)
check_error "ubus call failed"

DESCRIPTION=$(echo "$BOARD_INFO" | jsonfilter -e '@.release.description')
check_error "Failed to extract description"

VERSION=$(echo "$BOARD_INFO" | jsonfilter -e '@.release.version')
check_error "Failed to extract version"

# Проверяем что значения не пустые
check_empty "$DESCRIPTION" "System description"
check_empty "$VERSION" "System version"

findKey="openwrt"
findVersion="24"

if echo "$DESCRIPTION" | grep -qi -- "$findKey" && printf '%s\n%s\n' "$findVersion" "$VERSION" | sort -V | tail -n1 | grep -qx -- "$VERSION"; then
    printf "\033[32;1mThis new firmware. Running new script...\033[0m\n"
    
    # Скачивание нового скрипта
    if ! wget --no-check-certificate -O /tmp/universal_config_new_podkop.sh "https://raw.githubusercontent.com/alexsdav/WR3000S/refs/heads/main/universal_config1.sh"; then
        printf "\033[31;1mERROR: Failed to download new script!\033[0m\n"
        exit 1
    fi
    
    # Делаем скрипт исполняемым
    if ! chmod +x /tmp/universal_config_new_podkop.sh; then
        printf "\033[31;1mERROR: Failed to make new script executable!\033[0m\n"
        exit 1
    fi
    
    # Запускаем новый скрипт
    if ! /tmp/universal_config_new_podkop.sh "$1" "$2"; then
        printf "\033[31;1mERROR: New script execution failed!\033[0m\n"
        exit 1
    fi
    
else
    printf "\033[31;1m╔══════════════════════════════════════════════════╗\033[0m\n"
    printf "\033[31;1m║                 WARNING!                         ║\033[0m\n"
    printf "\033[31;1m╠══════════════════════════════════════════════════╣\033[0m\n"
    printf "\033[31;1m║ Old firmware detected: %-25s ║\033[0m\n" "$VERSION"
    printf "\033[31;1m║                                                  ║\033[0m\n"
    printf "\033[31;1m║ Please upgrade your firmware to version %-8s ║\033[0m\n" "$findVersion"
    printf "\033[31;1m║ or newer to continue.                            ║\033[0m\n"
    printf "\033[31;1m║                                                  ║\033[0m\n"
    printf "\033[31;1m║ Current version: %-30s ║\033[0m\n" "$VERSION"
    printf "\033[31;1m║ Required version: %-29s ║\033[0m\n" "$findVersion+"
    printf "\033[31;1m╚══════════════════════════════════════════════════╝\033[0m\n"
    printf "\n"
    printf "\033[33;1mScript execution stopped for security reasons.\033[0m\n"
    exit 1
fi
