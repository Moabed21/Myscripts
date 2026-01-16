#!/bin/bash

# ==============================================================================
# Fedora Ultimate Setup Script
# Includes: System Update, NVIDIA (Akmod), Chrome, VS Code, Vim, and Zsh Setup
# ==============================================================================

# Stop script on error
set -e

echo "Starting System Setup..."

# --- 1. System Update ---
echo "-----------------------------------------------------"
echo "Updating the system..."
sudo dnf update --refresh -y

# --- 2. Enable Repositories (RPM Fusion) ---
echo "-----------------------------------------------------"
echo "Enabling RPM Fusion Repositories..."
sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y
sudo dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y

# --- 3. Development Tools & Vim ---
echo "-----------------------------------------------------"
echo "Installing Dev Tools and Vim..."
# Added 'vim' and 'util-linux-user' (needed for chsh) here
sudo dnf install clang gcc make kernel-devel kernel-headers dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig vim util-linux-user zsh -y

# --- 4. Install Google Chrome ---
echo "-----------------------------------------------------"
echo "Installing Google Chrome..."
sudo dnf install fedora-workstation-repositories -y
sudo dnf config-manager --set-enabled google-chrome
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

# Install Telegram
flatpak install flathub org.telegram.desktop -y

# Install VS Code (as requested via Flatpak)
flatpak install flathub com.visualstudio.code -y

# --- 7. Zsh & Oh My Zsh Configuration ---
echo "-----------------------------------------------------"
echo "Setting up Zsh, Oh My Zsh, and Plugins..."

# 1. Install Oh My Zsh (Unattended mode prevents it from stopping the script)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 2. Download Plugins (from your screenshot)
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions || true
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting || true

# 3. Configure .zshrc (Theme: Jonathan & Plugins)
# We use sed to edit the config file automatically
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="jonathan"/g' ~/.zshrc
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# 4. Set Zsh as Default Shell
# Uses usermod to avoid password prompt issues
echo "Changing default shell to zsh..."
sudo usermod --shell /bin/zsh $USER

# --- 8. X Window System ---
echo "-----------------------------------------------------"
echo "Installing X Window System..."
sudo dnf group install "X Window System" -y
sudo dnf install xorg-x11-server-Xorg xorg-x11-xinit xterm -y

# --- 9. Cleanup ---
echo "-----------------------------------------------------"
echo "Cleaning up..."
sudo dnf autoremove -y

echo "====================================================="
echo "Setup Complete!"
echo "Please wait approx 5 minutes for the Nvidia akmod to build."
echo "THEN REBOOT YOUR MACHINE."
echo "====================================================="
