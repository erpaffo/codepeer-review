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
    more \
    grep \
    sed \
    awk \
    find \
    locate \
    which \
    whereis \
    file \
    stat \
    lsblk \
    df \
    du \
    free \
    top \
    ps \
    kill \
    pkill \
    killall \
    nice \
    renice \
    chmod \
    chown \
    chgrp \
    umask \
    touch \
    mkdir \
    rmdir \
    cp \
    mv \
    rm \
    ln \
    cat \
    tac \
    head \
    tail \
    nl \
    wc \
    sort \
    uniq \
    cut \
    paste \
    join \
    split \
    tr \
    expand \
    unexpand \
    fmt \
    pr \
    fold \
    column \
    col \
    expand \
    unexpand \
    nl \
    od \
    hexdump \
    xxd \
    base64 \
    md5sum \
    sha1sum \
    sha256sum \
    sha512sum \
    cksum \
    sum \
    b2sum \
    tee \
    sponge \
    dd \
    convmv \
    iconv \
    recode \
    dos2unix \
    unix2dos \
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
    netcat \
    socat \
    openssh-client \
    openssh-server \
    rsync \
    scp \
    sftp \
    && apt-get clean

# Installa strumenti di sistema
RUN apt-get update && apt-get install -y \
    procps \
    sysstat \
    iotop \
    iostat \
    vmstat \
    mpstat \
    sar \
    strace \
    ltrace \
    lsof \
    fuser \
    pstree \
    pgrep \
    pidof \
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

# Installa Python packages comuni
RUN pip3 install --no-cache-dir \
    ipython \
    jupyter \
    numpy \
    pandas \
    matplotlib \
    requests \
    beautifulsoup4 \
    flask \
    django \
    pytest \
    black \
    flake8 \
    mypy

# Installa Node.js packages comuni
RUN npm install -g \
    yarn \
    nodemon \
    pm2 \
    eslint \
    prettier \
    typescript \
    ts-node \
    jest \
    mocha \
    chai \
    sinon

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
