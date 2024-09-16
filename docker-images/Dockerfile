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
    && apt-get clean

# Imposta la directory di lavoro
WORKDIR /app

# Permessi per l'utente root
USER root
