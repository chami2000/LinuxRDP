#!/bin/bash

# Copyright (c) [2024] [@ravindu644]

# Set DEBIAN_FRONTEND to noninteractive to suppress prompts
export DEBIAN_FRONTEND=noninteractive

# Function to create user
create_user() {
    echo "Creating User and Setting it up"
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo

    useradd -m "$username"
    adduser "$username" sudo
    echo "$username:$password" | sudo chpasswd
    sed -i 's/\/bin\/sh/\/bin\/bash/g' /etc/passwd

    # Add PATH update to .bashrc of the new user
    echo 'export PATH=$PATH:/home/user/.local/bin' >> /home/"$username"/.bashrc
    # Reload .bashrc for the new user
    su - "$username" -c "source ~/.bashrc"

    echo "User created and configured having username '$username'"
}

#extra storage setup
setup_storage() {
    local username="$1" 
    mkdir -p /storage
    chmod 777 /storage
    chown "$username":"$username" /storage
    mkdir -p /home/"$username"/storage
    mount --bind /storage /home/"$username"/storage
}

# Function to install 64Gram Telegram
install_telegram() {
    local username="$1"
    echo "Installing 64Gram Telegram"
    
    # Install required dependencies
    apt install --assume-yes unzip wget

    # Create Applications directory if it doesn't exist
    mkdir -p /home/"$username"/.local/share/applications
    mkdir -p /home/"$username"/Applications

    # Download and setup 64Gram
    cd /home/"$username"/Applications
    wget https://github.com/TDesktop-x64/tdesktop/releases/download/v1.1.58/64Gram_1.1.58_linux.zip
    unzip 64Gram_1.1.58_linux.zip
    rm 64Gram_1.1.58_linux.zip
    
    # Make files executable
    chmod +x Telegram
    chmod +x Updater

    # Create desktop shortcut
    cat > /home/"$username"/Desktop/64Gram.desktop << EOF
[Desktop Entry]
Version=1.0
Name=64Gram
Comment=Telegram Desktop Client
Exec=/home/$username/Applications/Telegram
Icon=telegram
Terminal=false
Type=Application
Categories=Network;InstantMessaging;
EOF

    # Also add to system applications
    cp /home/"$username"/Desktop/64Gram.desktop /home/"$username"/.local/share/applications/

    # Set proper permissions
    chmod +x /home/"$username"/Desktop/64Gram.desktop
    chmod +x /home/"$username"/.local/share/applications/64Gram.desktop
    chown -R "$username":"$username" /home/"$username"/Applications
    chown "$username":"$username" /home/"$username"/Desktop/64Gram.desktop
    chown "$username":"$username" /home/"$username"/.local/share/applications/64Gram.desktop

    echo "64Gram Telegram has been installed and desktop shortcut created"
}

# Function to install and configure RDP
setup_rdp() {
    echo "Installing Firefox ESR"
    add-apt-repository ppa:mozillateam/ppa -y  
    apt update
    apt install --assume-yes firefox-esr
    apt install --assume-yes dbus-x11 dbus 

    echo "Installing dependencies"
    apt update
    add-apt-repository universe -y
    apt install --assume-yes xvfb xserver-xorg-video-dummy xbase-clients python3-packaging python3-psutil python3-xdg libgbm1 libutempter0 libfuse2 nload qbittorrent ffmpeg gpac fonts-lklug-sinhala

    echo "Installing Desktop Environment"
    apt install --assume-yes xfce4 desktop-base xfce4-terminal xfce4-session
    bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
    apt remove --assume-yes gnome-terminal
    apt install --assume-yes xscreensaver
    systemctl disable lightdm.service

    echo "Installing Chrome Remote Desktop"
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg --install chrome-remote-desktop_current_amd64.deb
    apt install --assume-yes --fix-broken

    echo "Finalizing"
    adduser "$username" chrome-remote-desktop
    
    echo "Please visit http://remotedesktop.google.com/headless and copy the command after Authentication"
    read -p "Paste the CRD command here: " CRP
    read -p "Enter a PIN for CRD (6 or more digits): " Pin

    su - "$username" -c "$CRP --pin=$Pin"
    service chrome-remote-desktop start
    setup_storage "$username"

    echo "RDP setup completed"
}

# Main execution
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

create_user
setup_rdp
install_telegram "$username"

echo "Setup completed. Please check the individual function outputs for access information."

# Keep-alive loop
echo "Starting keep-alive loop. Press Ctrl+C to stop."
while true; do
    echo "I'm alive"
    sleep 300  # Sleep for 5 minutes
done
