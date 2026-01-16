#!/bin/bash

# ==============================================================================
# Fedora 43+ Setup Script (Final)
# ==============================================================================

# Stop script on error
set -e

# 1. DETECT THE REAL USER
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    echo "Error: Please run this script with sudo (e.g., sudo ./setup.sh)"
    exit 1
fi

echo "Starting System Setup for user: $REAL_USER"

# --- 1. System Update ---
echo "-----------------------------------------------------"
echo "Updating the system..."
sudo dnf update --refresh -y

# --- 2. Enable Repositories (RPM Fusion) ---
echo "-----------------------------------------------------"
echo "Enabling RPM Fusion Repositories..."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y || true
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y || true

# --- 3. Development Tools & Vim ---
echo "-----------------------------------------------------"
echo "Installing Dev Tools and Vim..."
sudo dnf install clang gcc make kernel-devel kernel-headers dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig vim util-linux-user zsh -y

# --- 4. Install Google Chrome ---
echo "-----------------------------------------------------"
echo "Installing Google Chrome..."
sudo dnf install fedora-workstation-repositories -y
# Handle DNF5 syntax vs DNF4
sudo dnf config-manager set-enabled google-chrome 2>/dev/null || sudo dnf config-manager --set-enabled google-chrome 2>/dev/null || true
sudo dnf install google-chrome-stable -y

# --- 5. Install NVIDIA Drivers (Akmod) ---
echo "-----------------------------------------------------"
echo "Installing NVIDIA Drivers..."
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y

# --- 6. Flatpak Setup & Apps (VS Code + Telegram) ---
echo "-----------------------------------------------------"
echo "Setting up Flatpak, VS Code, and Telegram..."
sudo dnf install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.telegram.desktop -y
flatpak install flathub com.visualstudio.code -y

# --- 7. Zsh & Oh My Zsh Configuration ---
echo "-----------------------------------------------------"
echo "Setting up Zsh for $REAL_USER..."

# A. Install Oh My Zsh
if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sudo -u "$REAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# B. Download Plugins
echo "Downloading Zsh plugins..."
ZSH_CUSTOM="$REAL_HOME/.oh-my-zsh/custom"
sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions 2>/dev/null || true
sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting 2>/dev/null || true

# C. Configure .zshrc
echo "Configuring .zshrc..."
sudo -u "$REAL_USER" sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jonathan"/g' "$REAL_HOME/.zshrc"
sudo -u "$REAL_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$REAL_HOME/.zshrc"

# D. Set Zsh as Default Shell
echo "Changing default shell to zsh..."
sudo usermod --shell /bin/zsh "$REAL_USER"

# --- 8. X Window System (Fixed for Fedora 43) ---
echo "-----------------------------------------------------"
echo "Installing X Window System..."
# 'base-x' is the modern group name for X11 core
sudo dnf install @base-x xorg-x11-server-Xorg xorg-x11-xinit xterm -y

# --- 9. Cleanup ---
echo "-----------------------------------------------------"
echo "Cleaning up..."
sudo dnf autoremove -y

echo "====================================================="
echo "Setup Complete!"
echo "Please wait approx 5 minutes for the Nvidia akmod to build."
echo "THEN REBOOT YOUR MACHINE."
echo "====================================================="
echo "====================================================="
