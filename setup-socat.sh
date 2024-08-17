#!/bin/bash

# تابع برای نصب اسکریپت
install_script() {
    echo "Enter the port number you want to use: "
    read port
    echo "Enter the IPv6 address you want to forward to: "
    read ipv6

    # نصب socat در صورت عدم نصب
    sudo apt update
    sudo apt install -y socat

    # بازنویسی /etc/rc.local با افزودن #!/bin/bash به بالا
    echo "#!/bin/bash" | sudo tee /etc/rc.local > /dev/null
    echo "socat TCP4-LISTEN:${port},fork TCP6:[${ipv6}]:${port},ipv6only=1 &" | sudo tee -a /etc/rc.local > /dev/null
    echo "exit 0" | sudo tee -a /etc/rc.local > /dev/null

    # تنظیم مجوز اجرایی برای /etc/rc.local
    sudo chmod +x /etc/rc.local

    echo "Script installed successfully."
}

# تابع برای حذف اسکریپت
uninstall_script() {
    # حذف خط socat از /etc/rc.local
    sudo sed -i '/socat TCP4-LISTEN/d' /etc/rc.local

    # حذف خط #!/bin/bash از ابتدای فایل اگر موجود باشد
    sudo sed -i '1d' /etc/rc.local

    echo "Script uninstalled successfully."
}

# تابع برای نمایش منو و پردازش ورودی
show_menu() {
    clear
    echo "================================"
    echo " ParsDigitall Script Management "
    echo "================================"
    echo "1) Install Script"
    echo "2) Uninstall Script"
    echo "3) Exit"
    echo "============================="
    echo -n "Please select an option [1-3]: "
}

# منو اصلی
while true; do
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
            ;;
    esac
done
