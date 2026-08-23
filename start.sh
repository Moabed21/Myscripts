#!/bin/bash

# ==============================================================================
# Fedora 44 Setup Script
# Updated for: DNF5, Wayland-only GNOME 50, PEP 668 (pipx)
# Projects: Cub3d, CPP00-05, BlackEye (Go), Smart-Educator (Python/Docker),
#           mini-rag (Python/Docker), JARVIS (Ollama), opencode (Bun/Node)
# ==============================================================================

# Stop script on error
set -e

# ── 1. DETECT THE REAL USER ──
if [ -n "$SUDO_USER" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
else
    echo "Error: Please run this script with sudo (e.g., sudo ./start.sh)"
    exit 1
fi

echo "Starting Fedora 44 System Setup for user: $REAL_USER"

# ── 2. System Update ──
echo "-----------------------------------------------------"
echo "Updating the system..."
dnf update --refresh -y

# ── 3. Enable Repositories (RPM Fusion) ──
echo "-----------------------------------------------------"
echo "Enabling RPM Fusion Repositories..."
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm -y || true
dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm -y || true

# ── 4. Core Development Tools ──
echo "-----------------------------------------------------"
echo "Installing Core Dev Tools (C/C++, Python, Zsh, Vim, Valgrind)..."
dnf install \
    clang gcc g++ make cmake \
    kernel-devel kernel-headers dkms acpid \
    libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig \
    vim util-linux-user valgrind gdb \
    zsh git curl wget \
    python3 python3-pip python3-devel pipx \
    -y

# ── 5. X11/XWayland Development Libraries (for Cub3d / minilibx) ──
echo "-----------------------------------------------------"
echo "Installing X11 dev libraries (needed for minilibx / Cub3d)..."
# Fedora 44 is Wayland-only for GNOME, but XWayland still runs X11 apps.
# minilibx-linux links against -lXext -lX11 and uses X11/Xlib.h, XShm, etc.
dnf install \
    libX11-devel libXext-devel libXrandr-devel \
    libXinerama-devel libXcursor-devel libXi-devel \
    libXfixes-devel libXrender-devel \
    xterm \
    mesa-libGL-devel \
    -y

# ── 6. Install Google Chrome ──
echo "-----------------------------------------------------"
echo "Installing Google Chrome..."
dnf install fedora-workstation-repositories -y
# DNF5 syntax: use setopt instead of deprecated --set-enabled
dnf config-manager setopt google-chrome.enabled=1 2>/dev/null || true
dnf install google-chrome-stable -y

# ── 7. Install NVIDIA Drivers (Akmod) ──
echo "-----------------------------------------------------"
echo "Installing NVIDIA Drivers..."
dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y

# ── 8. Flatpak Setup & Apps (Telegram) ──
echo "-----------------------------------------------------"
echo "Setting up Flatpak and Telegram..."
dnf install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub org.telegram.desktop -y

# ── 9. Install VS Code (from Microsoft repo) ──
echo "-----------------------------------------------------"
echo "Installing Visual Studio Code..."
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
dnf install code -y

# ── 10. Zsh & Oh My Zsh Configuration ──
echo "-----------------------------------------------------"
echo "Setting up Zsh for $REAL_USER..."

# A. Install Oh My Zsh
if [ ! -d "$REAL_HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  sudo -u "$REAL_USER" bash -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
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
usermod --shell /bin/zsh "$REAL_USER"

# ── 11. Python Tools via pipx (PEP 668 compliant) ──
echo "-----------------------------------------------------"
echo "Installing Python CLI tools via pipx..."
# Ensure pipx bin dir exists and is in PATH
sudo -u "$REAL_USER" pipx ensurepath
sudo -u "$REAL_USER" pipx install norminette || sudo -u "$REAL_USER" pipx upgrade norminette
sudo -u "$REAL_USER" pipx install c-formatter-42 || sudo -u "$REAL_USER" pipx upgrade c-formatter-42

# Add pipx/local bin to zshrc if not already present
if ! grep -q '.local/bin' "$REAL_HOME/.zshrc" 2>/dev/null; then
    echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$REAL_HOME/.zshrc"
fi

# ── 12. Go Language & BlackEye Build ──
echo "-----------------------------------------------------"
echo "Installing Go and building BlackEye..."
dnf install golang util-linux iproute procps-ng pciutils firewalld -y

# If BlackEye source exists in user Documents, compile and install globally
if [ -d "$REAL_HOME/Documents/BlackEye" ]; then
    echo "Compiling BlackEye dashboard..."
    (cd "$REAL_HOME/Documents/BlackEye" && sudo -u "$REAL_USER" make)
    if [ -f "$REAL_HOME/Documents/BlackEye/blackeye" ]; then
        cp "$REAL_HOME/Documents/BlackEye/blackeye" /usr/local/bin/blackeye
        chmod 755 /usr/local/bin/blackeye
        echo "BlackEye installed to /usr/local/bin/blackeye (Run with 'sudo blackeye')"
    fi
fi

# ── 13. Docker & Docker Compose (for Smart-Educator, mini-rag, JARVIS) ──
echo "-----------------------------------------------------"
echo "Installing Docker..."
dnf install dnf-plugins-core -y
dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null || true
dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Enable and start Docker
systemctl enable --now docker
# Add user to docker group (no sudo needed for docker commands)
usermod -aG docker "$REAL_USER"

# ── 14. Ollama (for JARVIS - local LLM with Modelfile) ──
echo "-----------------------------------------------------"
echo "Installing Ollama (local AI models)..."
curl -fsSL https://ollama.com/install.sh | sh
# Enable Ollama service
systemctl enable --now ollama

# ── 15. Node.js & Bun (for opencode project) ──
echo "-----------------------------------------------------"
echo "Installing Node.js and Bun..."
dnf install nodejs npm -y
# Install Bun for the user (opencode uses bun as packageManager)
sudo -u "$REAL_USER" bash -c 'curl -fsSL https://bun.sh/install | bash'

# ── 16. Cleanup ──
echo "-----------------------------------------------------"
echo "Cleaning up..."
dnf autoremove -y

echo "====================================================="
echo "Setup Complete!"
echo ""
echo "  IMPORTANT NOTES:"
echo "  1. Wait ~5 minutes for the NVIDIA akmod kernel module to build."
echo "  2. Log out and back in for Docker group membership to take effect."
echo "  3. THEN REBOOT YOUR MACHINE."
echo ""
echo "  Post-reboot checklist:"
echo "    - Launch system dashboard: 'sudo blackeye'"
echo "    - Run 'ollama pull qwen2.5:3b' to download JARVIS model"
echo "    - Run 'docker compose up -d' in your project dirs"
echo "    - Run 'bun install' in the opencode project"
echo "====================================================="

