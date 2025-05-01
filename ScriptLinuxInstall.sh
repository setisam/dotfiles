#!/bin/bash

set -e

# Arch Post-Install Script V0.0.5 - by PT & Sam
# Assumes a minimal up-to-date Arch install

LOGFILE="$HOME/install.log"
exec > >(tee -a "$LOGFILE") 2>&1

log() { echo -e "\033[1;32m==> $1\033[0m"; }

splash() {
  cat << "SPLASH"
\033[38;5;208m        ____  _________        __     ______  
       / __ \/ ____/   | ____/ /__  / __/ /__
      / /_/ / /_  / /| |/ __  / _ \/ /_/ / _ \
     / ____/ __/ / ___ / /_/ /  __/ __/ /  __/
    /_/   /_/   /_/  |_\__,_/\___/_/ /_/\___/ 
\033[0m\033[38;5;14m              PT  x  SAM // Solaris Setup\033[0m
SPLASH
}

enable_multilib() {
  log "[1/10] Enabling multilib for Steam"
  sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
  sudo pacman -Sy
}

install_base_packages() {
  log "[2/10] Installing base packages (GNOME, Hyprland, zsh, terminals)"
  sudo pacman -S --noconfirm gnome gnome-tweaks hyprland kitty gnome-terminal zsh nautilus git wget fastfetch firefox steam
}

install_chaotic_aur() {
  log "[3/10] Installing Brave-bin and yay via Chaotic AUR"
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm 'https://cdn.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
  sudo pacman -U --noconfirm 'https://cdn.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
  sudo pacman -Sy --noconfirm brave-bin yay
}

install_wireguard() {
  log "[4/10] Installing WireGuard"
  sudo pacman -S --noconfirm wireguard-tools
}

install_portals_and_utils() {
  log "[5/10] Installing xdg portals and Hyprland utils"
  sudo pacman -S --noconfirm xdg-desktop-portal-gnome xdg-desktop-portal-hyprland hyprpanel hyprpaper
}

install_intel_gpu_drivers() {
  log "[6/10] Installing Intel GPU drivers"
  sudo pacman -S --noconfirm mesa libva-intel-driver intel-media-driver vulkan-intel
}

install_rofi_theme() {
  log "[7/10] Installing Rofi with custom theme"
  sudo pacman -S --noconfirm rofi
  mkdir -p ~/.config/rofi
  cat <<EOF > ~/.config/rofi/config.rasi
configuration {
    show-icons: true;
    icon-theme: "Gruvbox-Plus-Dark";
    modi: "drun";
    font: "monospace 12";
}
* {
    background-color: #1d2021;
    border: 0;
    border-radius: 10px;
    padding: 15px;
    text-color: #ebdbb2;
    selected-background-color: #458588;
    selected-foreground-color: #1d2021;
}
EOF
}

setup_zsh() {
  log "[8/10] Setting up zsh with fish-like config"
  sudo pacman -S --noconfirm zsh-autosuggestions zsh-syntax-highlighting
  mkdir -p ~/.config/zsh
  cat <<EOF > ~/.config/zsh/.zshrc
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
PROMPT='%F{green}%n@%m %F{blue}%~ %f$ '
EOF
  chsh -s /bin/zsh
}

create_session_selector() {
  log "[9/10] Creating session startup selector"
  mkdir -p ~/.local/bin
  cat <<'EOF' > ~/.local/bin/select-session.sh
#!/bin/bash
PS3="Choose a session to start: "
options=("GNOME (Wayland)" "Hyprland")
select opt in "${options[@]}"; do
  case "$REPLY" in
    1) exec dbus-run-session -- gnome-session ;;
    2) exec dbus-run-session Hyprland ;;
    *) echo "Invalid option." ;;
  esac
done
EOF
  chmod +x ~/.local/bin/select-session.sh

  echo -e '\n[[ -z $DISPLAY && $(tty) = /dev/tty1 ]] && ~/.local/bin/select-session.sh' >> ~/.bash_profile
}

configure_hyprland() {
  log "[10/10] Configuring Hyprland defaults"
  mkdir -p ~/.config/hypr
  if [ ! -f ~/.config/hypr/hyprland.conf ]; then
    cp /etc/hypr/hyprland.conf ~/.config/hypr/hyprland.conf
  fi
  sed -i 's/dolphin/nautilus/' ~/.config/hypr/hyprland.conf
  sed -i '/rofi/d' ~/.config/hypr/hyprland.conf
  echo "bind = SUPER, A, exec, rofi -show drun" >> ~/.config/hypr/hyprland.conf
}

main() {
  splash
  enable_multilib
  install_base_packages
  install_chaotic_aur
  install_wireguard
  install_portals_and_utils
  install_intel_gpu_drivers
  install_rofi_theme
  setup_zsh
  create_session_selector
  configure_hyprland
  log "Setup complete! Reboot and enjoy your Solaris-powered Arch setup"
  echo "You can now reboot: sudo reboot"
}

main

