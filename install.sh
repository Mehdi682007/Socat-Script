#!/bin/bash

# تنظیم مسیر فایل ذخیره‌سازی پورت‌ها و آدرس‌های IPv6
PORTS_FILE="/etc/rc.local"

# تابع برای بررسی وجود netstat
check_netstat() {
    if ! command -v netstat &> /dev/null; then
        echo "netstat not found. Installing net-tools..."
        sudo apt update
        sudo apt install -y net-tools
    fi
}

# تابع برای بررسی وضعیت اجرا
check_status() {
    check_netstat  # بررسی و نصب netstat در صورت نیاز

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

    # بررسی و نصب netstat اگر لازم باشد
    check_netstat

    # بازنویسی /etc/rc.local با افزودن #!/bin/bash به بالا
    echo "#!/bin/bash" | sudo tee /etc/rc.local > /dev/null

    # افزودن دستورات socat برای هر پورت و IPv6
    for index in "${!ports[@]}"; do
        port=${ports[$index]}
        ipv6=${ipv6_addresses[$index]}
        echo "socat TCP4-LISTEN:${port},fork TCP6:[${ipv6}]:${port},ipv6only=1 &" | sudo tee -a /etc/rc.local > /dev/null
    done

    echo "exit 0" | sudo tee -a /etc/rc.local > /dev/null

    # تنظیم مجوز اجرایی برای /etc/rc.local
    sudo chmod +x /etc/rc.local

    echo -e "\033[0;32m"
    echo "Script installed successfully."
    echo -e "\033[0m"

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

# تابع برای افزودن IPv6 لوکال
add_ipv6_local() {
    sudo apt-get install -y iproute2

        # بررسی و نصب Netplan اگر لازم باشد
    if ! command -v netplan &> /dev/null; then
        echo "Netplan not found. Installing netplan.io..."
        sudo apt update
        sudo apt install -y netplan.io
    fi

        # اطمینان از فعال بودن systemd-networkd
    sudo systemctl unmask systemd-networkd
    sudo systemctl start systemd-networkd
    sudo systemctl enable systemd-networkd
    
    echo "Enter local IPv4 address: "
    read local_ipv4
    
    echo "Enter remote IPv4 address: "
    read remote_ipv4
    
    echo "Enter your desired local IPv6 address: "
    read local_ipv6
    
    echo "Enter your desired remote IPv6 address: "
    read remote_ipv6
    
    # ساخت فایل پیکربندی netplan
    sudo tee /etc/netplan/pdtun.yaml > /dev/null <<EOL
network:
  version: 2
  tunnels:
    tunel01:
      mode: sit
      local: ${local_ipv4}
      remote: ${remote_ipv4}
      addresses:
        - ${local_ipv6}/64
      mtu: 1500
EOL

    sudo netplan apply

    # ساخت فایل پیکربندی systemd network
    sudo tee /etc/systemd/network/tun0.network > /dev/null <<EOL
[Network]
Address=${local_ipv6}/64
Gateway=${remote_ipv6}
EOL

    sudo systemctl restart systemd-networkd

    echo "Local IPv6 address added successfully."
    exit 0
}

# تابع برای حذف اسکریپت
uninstall_script() {
    read -p "Are you sure you want to uninstall the script and remove local IPv6 settings? (yes/no): " confirm
    if [[ "$confirm" == "yes" ]]; then
        # توقف تمام فرآیندهای socat
        sudo pkill -x socat

        # حذف خطوط socat از /etc/rc.local
        sudo sed -i '/socat TCP4-LISTEN/d' /etc/rc.local

        # حذف خط #!/bin/bash از ابتدای فایل اگر موجود باشد
        sudo sed -i '1d' /etc/rc.local

        # حذف فایل‌های پیکربندی IPv6 لوکال
        if [[ -f "/etc/netplan/pdtun.yaml" ]]; then
            sudo rm /etc/netplan/pdtun.yaml
            sudo netplan apply
        fi

        if [[ -f "/etc/systemd/network/tun0.network" ]]; then
            sudo rm /etc/systemd/network/tun0.network
            sudo systemctl restart systemd-networkd
        fi

        echo "Script and local IPv6 settings uninstalled successfully."
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
    echo "2) Add Local IPv6"
    echo "3) Uninstall Script"
    echo "4) Exit"
    echo "=========================================="
    echo -n "Please select an option [1-4]: "
}

# تابع برای بارگذاری پورت‌ها
load_ports() {
    if [[ -f "$PORTS_FILE" ]]; then
        ports=($(grep -oP 'LISTEN:\K\d+' "$PORTS_FILE"))
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
        add_ipv6_local
        ;;
    3)
        uninstall_script
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid option. Please select a valid option."
        exit 1
        ;;
esac
