#!/bin/bash

# ==============================================
# BitLocker Mount Script dengan Input Interaktif
# ==============================================

# Minta input dari pengguna
read -p "Masukkan partisi BitLocker (contoh: sda1): " DEVICE_PART
read -p "Masukkan nama direktori dislocker (contoh: bitlocker): " DISLOCKER_DIR_NAME
read -p "Masukkan nama direktori mount (contoh: bitlockermount): " MOUNT_DIR_NAME
read -sp "Masukkan password BitLocker: " PASSWORD
echo  # Pindah baris setelah input password

# Konfigurasi path
DEVICE="/dev/${DEVICE_PART}"
DISLOCKER_DIR="/media/${DISLOCKER_DIR_NAME}"
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
  sudo dislocker -v -V "$DEVICE" -u"$PASSWORD" -- "$DISLOCKER_DIR"

  echo "Mounting ke $MOUNT_POINT..."
  sudo mount -o loop,rw "$DISLOCKER_DIR/dislocker-file" "$MOUNT_POINT"

  # Cek status
  if mount | grep -q "$MOUNT_POINT"; then
    echo "Berhasil di-mount ke: $MOUNT_POINT"
    df -h "$MOUNT_POINT"
  else
    echo "Gagal mounting!" >&2
    exit 1
  fi
}

# ==============================================
# Fungsi Unmount
unmount_bitlocker() {
  echo "Unmounting $MOUNT_POINT..."
  sudo umount "$MOUNT_POINT" || echo "Gagal unmount $MOUNT_POINT" >&2
  
  echo "Unmounting dislocker..."
  sudo umount "$DISLOCKER_DIR" || echo "Gagal unmount $DISLOCKER_DIR" >&2
  
  # Hapus direktori jika kosong
  sudo rmdir "$MOUNT_POINT" 2>/dev/null
  sudo rmdir "$DISLOCKER_DIR" 2>/dev/null
  
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
