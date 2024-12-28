FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies and configure sources
RUN apt-get update && \
    apt-get upgrade --assume-yes && \
    apt-get install --assume-yes curl gpg wget sudo apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver python-psutil psmisc python3-psutil \
    xserver-xorg-video-dummy ffmpeg python3-packaging python3-xdg libutempter0 firefox && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vs-code.list && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install --assume-yes google-chrome-stable && \
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb && \
    dpkg --install chrome-remote-desktop_current_amd64.deb && \
    apt-get install --assume-yes --fix-broken && \
    rm chrome-remote-desktop_current_amd64.deb && \
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session

# Set up user and Chrome Remote Desktop
ARG USER=myuser
ENV PIN=""
ENV CODE=""
ENV HOSTNAME=""

RUN adduser --disabled-password --gecos '' $USER && \
    mkhomedir_helper $USER && \
    adduser $USER sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    usermod -aG chrome-remote-desktop $USER

WORKDIR /home/$USER

RUN mkdir -p .config/chrome-remote-desktop && \
    chown "$USER:$USER" .config/chrome-remote-desktop && \
    chmod a+rx .config/chrome-remote-desktop && \
    touch .config/chrome-remote-desktop/host.json && \
    echo "/usr/bin/pulseaudio --start" > .chrome-remote-desktop-session && \
    echo "startxfce4 :1030" >> .chrome-remote-desktop-session

CMD \
    if [ -z "$CODE" ] || [ -z "$PIN" ] || [ -z "$HOSTNAME" ]; then \
        echo "Error: CODE, PIN, and HOSTNAME environment variables must be set."; \
        exit 1; \
    fi && \
    DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN && \
    HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
    FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
    cp .config/chrome-remote-desktop/host#*.json $FILENAME && \
    service chrome-remote-desktop stop && \
    service chrome-remote-desktop start && \
    echo "Chrome Remote Desktop is running with HOSTNAME: $HOSTNAME" && \
    sleep infinity & wait
