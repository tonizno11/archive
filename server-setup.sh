#!/bin/bash

# Pastikan script dijalankan dengan user root
if [ "$(id -u)" -ne 0 ]; then
    echo "Jalankan script ini sebagai root."
    exit 1
fi

echo "============================"
echo "Setup Server DigitalOcean"
echo "============================"

# Update dan upgrade sistem
echo ">> Mengupdate dan meng-upgrade sistem..."
apt update && apt upgrade -y

# Install paket dasar
echo ">> Menginstall paket dasar..."
apt install -y curl wget git ufw fail2ban htop

# Tambahkan user baru
echo ">> Membuat user baru..."
read -p "Masukkan nama user baru: " NEW_USER
adduser $NEW_USER
usermod -aG sudo $NEW_USER
echo "User $NEW_USER berhasil dibuat dan ditambahkan ke grup sudo."

# Konfigurasi SSH
echo ">> Mengamankan SSH..."
sed -i 's/^#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
read -p "Masukkan path kunci publik SSH (default ~/.ssh/id_rsa.pub): " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa.pub}

if [ -f "$SSH_KEY_PATH" ]; then
    mkdir -p /home/$NEW_USER/.ssh
    cat $SSH_KEY_PATH > /home/$NEW_USER/.ssh/authorized_keys
    chown -R $NEW_USER:$NEW_USER /home/$NEW_USER/.ssh
    chmod 700 /home/$NEW_USER/.ssh
    chmod 600 /home/$NEW_USER/.ssh/authorized_keys
    echo "Kunci SSH berhasil ditambahkan untuk user $NEW_USER."
else
    echo "Kunci SSH tidak ditemukan. Pastikan file kunci publik tersedia."
fi

systemctl restart ssh
echo "Konfigurasi SSH selesai."

# Setup firewall
echo ">> Mengatur firewall..."
ufw allow OpenSSH
ufw enable -y
echo "Firewall diaktifkan dan port OpenSSH dibuka."

# Install Nginx (Opsional)
read -p "Apakah Anda ingin menginstall Nginx? (y/n): " INSTALL_NGINX
if [[ "$INSTALL_NGINX" == "y" ]]; then
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    ufw allow 'Nginx Full'
    echo "Nginx berhasil diinstall dan portnya dibuka."
fi

# Install Docker (Opsional)
read -p "Apakah Anda ingin menginstall Docker? (y/n): " INSTALL_DOCKER
if [[ "$INSTALL_DOCKER" == "y" ]]; then
    apt install -y docker.io
    systemctl start docker
    systemctl enable docker
    echo "Docker berhasil diinstall."
fi

# Konfigurasi Fail2Ban
echo ">> Mengaktifkan Fail2Ban..."
systemctl enable fail2ban
systemctl start fail2ban
echo "Fail2Ban berhasil diaktifkan."

# Nonaktifkan IPv6 (Opsional)
read -p "Apakah Anda ingin menonaktifkan IPv6? (y/n): " DISABLE_IPV6
if [[ "$DISABLE_IPV6" == "y" ]]; then
    echo ">> Menonaktifkan IPv6..."
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p
    echo "IPv6 dinonaktifkan."
fi

# Konfigurasi selesai
echo "============================"
echo "Setup server selesai!"
echo "Silakan logout dari user root dan login dengan user $NEW_USER."
echo "============================"
