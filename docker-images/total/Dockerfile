# Usa una base di Ubuntu
FROM ubuntu:20.04

# Imposta la variabile di ambiente per evitare problemi con tzdata
ENV DEBIAN_FRONTEND=noninteractive

# Installa le dipendenze comuni
RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    openjdk-11-jdk \
    python3 \
    python3-pip \
    ruby \
    nodejs \
    npm \
    git \
    curl \
    && apt-get clean

# Imposta la directory di lavoro
WORKDIR /app

# Copia i file del progetto nel container
COPY . /app

# Comando di default per eseguire il progetto
ENTRYPOINT ["/bin/bash", "-c"]
