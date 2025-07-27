FROM ubuntu:latest

# Aggiorna e installa i compilatori/interpreti e strumenti di base
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    python3-pip \
    openjdk-11-jdk \
    nodejs \
    npm \
    ruby-full \
    rustc \
    git \
    wget \
    curl \
    zip \
    unzip \
    bash \
    vim \
    nano \
    htop \
    tree \
    tmux \
    screen \
    less \
    grep \
    sed \
    gawk \
    findutils \
    which \
    file \
    procps \
    sysstat \
    util-linux \
    coreutils \
    && apt-get clean

# Installa strumenti di rete
RUN apt-get update && apt-get install -y \
    net-tools \
    iproute2 \
    iputils-ping \
    traceroute \
    mtr \
    nmap \
    telnet \
    netcat-traditional \
    socat \
    openssh-client \
    openssh-server \
    rsync \
    openssh-sftp-server \
    && apt-get clean

# Installa strumenti di sistema
RUN apt-get update && apt-get install -y \
    procps \
    sysstat \
    strace \
    ltrace \
    lsof \
    && apt-get clean

# Installa strumenti di sviluppo aggiuntivi
RUN apt-get update && apt-get install -y \
    gdb \
    valgrind \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config \
    checkinstall \
    dpkg-dev \
    debhelper \
    fakeroot \
    && apt-get clean

# Installa Node.js packages comuni
RUN npm install -g \
    yarn \
    nodemon

# Configura bash con colori e alias
RUN echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> /root/.bashrc && \
    echo 'alias ll="ls -la"' >> /root/.bashrc && \
    echo 'alias la="ls -A"' >> /root/.bashrc && \
    echo 'alias l="ls -CF"' >> /root/.bashrc && \
    echo 'alias grep="grep --color=auto"' >> /root/.bashrc && \
    echo 'alias fgrep="fgrep --color=auto"' >> /root/.bashrc && \
    echo 'alias egrep="egrep --color=auto"' >> /root/.bashrc && \
    echo 'alias diff="diff --color=auto"' >> /root/.bashrc && \
    echo 'alias ip="ip --color=auto"' >> /root/.bashrc && \
    echo 'export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"' >> /root/.bashrc

# Abilita colori per ls
RUN echo 'eval "$(dircolors -b)"' >> /root/.bashrc

# Imposta la directory di lavoro
WORKDIR /app

# Permessi per l'utente root
USER root

# Comando di default
CMD ["/bin/bash"]
