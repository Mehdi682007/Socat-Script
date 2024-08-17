#!/bin/bash

# دریافت ورودی از کاربر
read -p "Enter the port number you want to use: " port
read -p "Enter the IPv6 address you want to forward to: " ipv6

# نصب socat در صورت عدم نصب
sudo apt update
sudo apt install -y socat

# بررسی و اضافه کردن #!/bin/bash به ابتدای /etc/rc.local در صورت عدم وجود
if ! grep -q "^#!/bin/bash" /etc/rc.local; then
    echo "Adding #!/bin/bash to the top of /etc/rc.local"
    sudo sed -i '1i #!/bin/bash' /etc/rc.local
else
    echo "#!/bin/bash already present in /etc/rc.local"
fi

# حذف exit 0 در صورت وجود، برای اضافه کردن دستورات جدید
sudo sed -i '/exit 0/d' /etc/rc.local

# اضافه کردن دستور socat به /etc/rc.local
echo "socat TCP4-LISTEN:${port},fork TCP6:[${ipv6}]:${port},ipv6only=1 &" | sudo tee -a /etc/rc.local
echo "exit 0" | sudo tee -a /etc/rc.local

# تنظیم مجوز اجرایی برای /etc/rc.local
sudo chmod +x /etc/rc.local

# نمایش محتوای نهایی /etc/rc.local برای بررسی
echo "Final content of /etc/rc.local:"
cat /etc/rc.local

# ریبوت سیستم
read -p "Do you want to reboot the system now? (y/n): " reboot_choice
if [ "$reboot_choice" = "y" ]; then
    sudo reboot
else
    echo "Please reboot the system manually to apply changes."
fi
