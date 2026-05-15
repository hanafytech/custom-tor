FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install VNC, Matchbox (kiosk window manager), and required browser dependencies
RUN apt-get update && apt-get install -y \
    tigervnc-standalone-server novnc websockify matchbox-window-manager \
    curl ca-certificates procps xz-utils \
    libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor0 dbus-x11 \
    libgtk-3-0 libasound2 libdbus-glib-1-2 libx11-xcb1 \
    && rm -rf /var/lib/apt/lists/*

# Set noVNC default index to automatically redirect with the resize parameter
RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?resize=remote">' > /usr/share/novnc/index.html

# Setup user
RUN useradd -m toruser
USER toruser
WORKDIR /home/toruser

# Scrape the Tor site for the latest version, download, and extract it
RUN LATEST=$(curl -s https://www.torproject.org/download/ | grep -oP 'tor-browser-linux-x86_64-\K[0-9.]+(?=\.tar\.xz)' | head -1) && \
    curl -sSL -o tor.tar.xz "https://www.torproject.org/dist/torbrowser/${LATEST}/tor-browser-linux-x86_64-${LATEST}.tar.xz" && \
    tar -xf tor.tar.xz && \
    rm tor.tar.xz

# Auto-disable Tor's letterboxing feature so it actually fills the screen
RUN mkdir -p ~/tor-browser/Browser/TorBrowser/Data/Browser/profile.default && \
    echo 'user_pref("privacy.resistFingerprinting.letterboxing", false);' > ~/tor-browser/Browser/TorBrowser/Data/Browser/profile.default/user.js

# Configure VNC startup to run Matchbox without titlebars
RUN mkdir -p ~/.vnc && \
    echo "exec matchbox-window-manager -use_titlebar no" > ~/.vnc/xstartup && \
    chmod +x ~/.vnc/xstartup

# Create the startup script
RUN echo '#!/bin/bash\n\
vncserver :0 -SecurityTypes None -I-KNOW-THIS-IS-INSECURE -geometry 1280x720 -localhost no\n\
sleep 2\n\
DISPLAY=:0 ~/tor-browser/Browser/start-tor-browser --detach &\n\
websockify --web=/usr/share/novnc/ 8080 localhost:5900\n\
' > /home/toruser/start.sh && chmod +x /home/toruser/start.sh

EXPOSE 8080

CMD ["/home/toruser/start.sh"]
