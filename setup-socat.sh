#!/bin/bash

# تنظیم مسیر فایل ذخیره‌سازی پورت‌ها و آدرس‌های IPv6
PORTS_FILE="/etc/pd_tun/pd_tun_ports.conf"
SCRIPT_FILE="/usr/local/bin/pd_socat_tunnel.sh"

# تابع برای بررسی وضعیت اجرا
check_status() {
    local running=false
    for port in "${ports[@]}"; do
        if sudo netstat -tuln | grep -q ":${port} .*LISTEN"; then
            running=true
            break
        fi
    done

    if $running; then
        echo -e "\033[0;32mRunning\033[0m"
    else
        echo -e "\033[0;31mNot Running\033[0m"
    fi
}

# تابع برای نصب اسکریپت
install_script() {
    echo "Enter the number of ports you want to use: "
    read num_ports

    ports=()
    ipv6_addresses=()

    for ((i=1; i<=num_ports; i++)); do
        echo "Enter port number $i: "
        read port
        ports+=("$port")
        echo "Enter the IPv6 address for port $port: "
        read ipv6
        ipv6_addresses+=("$ipv6")
    done

    # نصب socat در صورت عدم نصب
    sudo apt update
    sudo apt install -y socat

    # ایجاد دایرکتوری سفارشی در صورت عدم وجود
    sudo mkdir -p "$(dirname "$PORTS_FILE")"

    # ایجاد فایل جدید و نوشتن اطلاعات پورت‌ها و آدرس‌های IPv6
    echo "#!/bin/bash" | sudo tee "$SCRIPT_FILE" > /dev/null

    for index in "${!ports[@]}"; do
        port=${ports[$index]}
        ipv6=${ipv6_addresses[$index]}
        echo "socat TCP4-LISTEN:${port},fork TCP6:[${ipv6}]:${port},ipv6only=1 &" | sudo tee -a "$SCRIPT_FILE" > /dev/null
        echo "PORT:${port} IP:${ipv6}" | sudo tee -a "$PORTS_FILE" > /dev/null
    done

    sudo chmod +x "$SCRIPT_FILE"
    echo -e "\033[0;32m"
    echo "Script installed successfully."
    echo -e "\033[0m"
    # تنظیم سرویس systemd برای اجرای اسکریپت
    echo "[Unit]
Description=Socat Tunnel Service
After=network.target

[Service]
ExecStart=$SCRIPT_FILE
ExecStop=/bin/kill \$MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/socat_tunnel.service > /dev/null

    sudo systemctl enable socat_tunnel.service
    sudo systemctl start socat_tunnel.service

    # ریبوت سیستم (پرسش از کاربر)
    echo -n "Do you want to reboot the system now? (y/n): "
    read -r reboot_choice
    if [ "$reboot_choice" = "y" ]; then
        echo "Rebooting system..."
        sudo reboot
    else
        echo "You chose not to reboot the system. Please reboot manually later."
    fi

    exit 0
}

# تابع برای حذف اسکریپت
uninstall_script() {
    read -p "Are you sure you want to uninstall the script? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        # توقف تمام فرآیندهای socat
        sudo systemctl stop socat_tunnel.service
        sudo systemctl disable socat_tunnel.service
        sudo rm /etc/systemd/system/socat_tunnel.service

        # حذف فایل‌های پورت و اسکریپت
        sudo rm "$PORTS_FILE"
        sudo rm "$SCRIPT_FILE"

        echo "Script uninstalled successfully."
    else
        echo "Uninstallation canceled."
    fi
    exit 0
}

# تابع برای نمایش منو و پردازش ورودی
show_menu() {
    clear
    # طراحی ASCII Art سبز
    echo -e "\033[0;32m"
    echo "  _____               _____     _____   _____    _____    _____   _____   _______              _        _      "
    echo " |  __ \      /\     |  __ \   / ____| |  __ \  |_   _|  / ____| |_   _| |__   __|     /\     | |      | |     "
    echo " | |__) |    /  \    | |__) | | (___   | |  | |   | |   | |  __    | |      | |       /  \    | |      | |     "
    echo " |  ___/    / /\ \   |  _  /   \___ \  | |  | |   | |   | | |_ |   | |      | |      / /\ \   | |      | |     "
    echo " | |       / ____ \  | | \ \   ____) | | |__| |  _| |_  | |__| |  _| |_     | |     / ____ \  | |____  | |____ "
    echo " |_|      /_/    \_\ |_|  \_\ |_____/  |_____/  |_____|  \_____| |_____|    |_|    /_/    \_\ |______| |______|"
    echo "                                                                                                                "
    echo -e "\033[0m"  # بازگشت به رنگ پیش‌فرض

    # فاصله
    echo ""

    # طراحی ASCII Art آبی روشن
    echo -e "\033[1;34m"
    echo "  _______  ______  _       ______  _____  _____             __  __                __  __ __     __ ____   _    _  _______  _    _  ____  "
    echo " |__   __||  ____|| |     |  ____|/ ____||  __ \     /\    |  \/  |  _     ____  |  \/  |\ \   / // __ \ | |  | ||__   __|| |  | ||  _ \ "
    echo "    | |   | |__   | |     | |__  | |  __ | |__) |   /  \   | \  / | (_)   / __ \ | \  / | \ \_/ /| |  | || |  | |   | |   | |  | || |_) |"
    echo "    | |   |  __|  | |     |  __| | | |_ ||  _  /   / /\ \  | |\/| |      / / _\ || |\/| |  \   / | |  | || |  | |   | |   | |  | ||  _ / "
    echo "    | |   | |____ | |____ | |____| |__| || | \ \  / ____ \ | |  | |  _  | | (_| || |  | |   | |  | |__| || |__| |   | |   | |__| || |_) |"
    echo "    |_|   |______||______||______|\_____||_|  \_\/_/    \_\|_|  |_| (_)  \ \__,_||_|  |_|   |_|   \____/  \____/    |_|    \____/ |____/ "
    echo "                                                                          \____/                                                        "
    echo -e "\033[0m"  # بازگشت به رنگ پیش‌فرض
    echo -e "\033[0;32m"
    echo "***** ParsDigitall Script Management *****"
    echo -e "\033[0m"
    echo "=========================================="
    echo -n "Status: "
    load_ports  # بارگذاری پورت‌ها
    check_status  # اضافه کردن وضعیت سرویس
    echo "=========================================="
    echo "1) Install Script"
    echo "2) Uninstall Script"
    echo "3) Exit"
    echo "=========================================="
    echo -n "Please select an option [1-3]: "
}

# تابع برای بارگذاری پورت‌ها
load_ports() {
    if [[ -f "$PORTS_FILE" ]]; then
        ports=($(grep -oP 'PORT:\K\d+' "$PORTS_FILE"))
    else
        ports=()
    fi
}

# منو اصلی
show_menu
read choice
case $choice in
    1)
        install_script
        ;;
    2)
        uninstall_script
        ;;
    3)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option. Please select a valid option."
        exit 1
        ;;
esac
