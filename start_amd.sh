#!/bin/bash

# ==============================================================================
# Fedora 43+ Setup Script (AMD/Universal Edition)
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

echo "🚀 Starting System Setup for user: $REAL_USER"

# --- 1. System Update ---
echo "-----------------------------------------------------"
echo "🔄 Updating the system..."
sudo dnf update --refresh -y

# --- 2. Enable Repositories (RPM Fusion) ---
echo "-----------------------------------------------------"
echo "📦 Enabling RPM Fusion Repositories..."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y || true
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y || true

# --- 3. Development Tools & Core Libs ---
# تم إضافة مكتبات mesa و vulkan لضمان أفضل أداء لكرت Vega 8
echo "-----------------------------------------------------"
echo "🛠️ Installing Dev Tools and Graphics Drivers..."
sudo dnf install clang gcc make kernel-devel kernel-headers dkms acpid \
libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig vim util-linux-user \
valgrind zsh python3 pip mesa-dri-drivers vulkan-loader -y

# --- 4. Install Google Chrome ---
echo "-----------------------------------------------------"
echo "🌐 Installing Google Chrome..."
sudo dnf install fedora-workstation-repositories -y
sudo dnf config-manager set-enabled google-chrome 2>/dev/null || sudo dnf config-manager --set-enabled google-chrome 2>/dev/null || true
sudo dnf install google-chrome-stable -y

# --- 5. Flatpak Setup & Apps (VS Code + Telegram) ---
echo "-----------------------------------------------------"
echo "📱 Setting up Flatpak, VS Code, and Telegram..."
sudo dnf install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.telegram.desktop -y
flatpak install flathub com.visualstudio.code -y

# --- 6. Zsh & Oh My Zsh Configuration ---
echo "-----------------------------------------------------"
echo "🐚 Configuring Zsh for $REAL_USER..."

if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
  sudo -u "$REAL_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

ZSH_CUSTOM="$REAL_HOME/.oh-my-zsh/custom"
sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions 2>/dev/null || true
sudo -u "$REAL_USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting 2>/dev/null || true

sudo -u "$REAL_USER" sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jonathan"/g' "$REAL_HOME/.zshrc"
sudo -u "$REAL_USER" sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' "$REAL_HOME/.zshrc"
sudo usermod --shell /bin/zsh "$REAL_USER"

# --- 7. X Window System ---
echo "-----------------------------------------------------"
echo "🖥️ Installing X Window System..."
sudo dnf install @base-x xorg-x11-server-Xorg xorg-x11-xinit xterm -y

# --- 8. 42 School Tools (Norminette & Formatter) ---
echo "-----------------------------------------------------"
echo "📏 Installing 42 School tools..."
python3 -m pip install -U norminette
pip3 install c-formatter-42
sudo export PATH=$PATH:$HOME/.local/bin
# --- 9. Cleanup ---
echo "-----------------------------------------------------"
echo "🧹 Cleaning up..."
sudo dnf autoremove -y

echo "====================================================="
echo "✅ Setup Complete!"
echo "Your AMD system is ready for coding."
echo "PLEASE REBOOT YOUR MACHINE."
echo "====================================================="
