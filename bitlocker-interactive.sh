#!/bin/bash

# ==============================================
# BitLocker Mount Script dengan Input Interaktif
# ==============================================

# Menampilkan semua partisi yang tersedia
echo "Daftar partisi yang tersedia:"
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -E 'sd[a-z][0-9]'

echo ""
# Minta input dari pengguna
read -p "Masukkan partisi BitLocker (contoh: sda1): " DEVICE_PART
read -p "Masukkan nama direktori mount (contoh: bitlockermount): " MOUNT_DIR_NAME
read -sp "Masukkan password BitLocker: " PASSWORD
echo  # Pindah baris setelah input password

# Konfigurasi path
DEVICE="/dev/${DEVICE_PART}"
DISLOCKER_DIR="/media/bitlocker"
MOUNT_POINT="/media/${MOUNT_DIR_NAME}"

# ==============================================
# Fungsi Mount
mount_bitlocker() {
  # Validasi input
  if [ ! -b "$DEVICE" ]; then
    echo "Error: Device $DEVICE tidak ditemukan!" >&2
    exit 1
  fi

  # Buat direktori
  sudo mkdir -p "$DISLOCKER_DIR"
  sudo mkdir -p "$MOUNT_POINT"

  # Dekripsi dan mount
  echo "Membuka BitLocker di $DEVICE..."
  sudo dislocker -V "$DEVICE" -u"$PASSWORD" -- "$DISLOCKER_DIR" && \
  sudo mount -o loop,rw "$DISLOCKER_DIR/dislocker-file" "$MOUNT_POINT" && \
  echo "Berhasil di-mount ke: $MOUNT_POINT" && df -h "$MOUNT_POINT"
}

# ==============================================
# Fungsi Unmount
unmount_bitlocker() {
  echo "Unmounting $MOUNT_POINT..."
  sudo umount "$MOUNT_POINT" && sudo umount "$DISLOCKER_DIR" && \
  sudo rmdir "$MOUNT_POINT" "$DISLOCKER_DIR" 2>/dev/null && \
  echo "Selesai."
}

# ==============================================
# Menu Utama
usage() {
  echo "Penggunaan:"
  echo "  $0 -m : Mount BitLocker"
  echo "  $0 -u : Unmount BitLocker"
  exit 1
}

case "$1" in
  -m|--mount)
    mount_bitlocker
    ;;
  -u|--unmount)
    unmount_bitlocker
    ;;
  *)
    usage
    ;;
esac
