
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Estágio 1: Compilar Mosquitto e o Plugin 
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
FROM debian:bullseye-slim AS builder

# Variáveis de Ambiente
ENV MOSQUITTO_VERSION=2.0.18
ENV RUST_VERSION=1.70.0

# Dependências de Compilação
RUN apt-get update && apt-get install -y \
    build-essential \
    libssl-dev \
    libc-ares-dev \
    uuid-dev \
    libwebsockets-dev \
    libcjson-dev \
    libsystemd-dev \
    wget \
    git \
    curl \
    ca-certificates \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Instalar Rust
ENV PATH="/root/.cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain $RUST_VERSION

# Compilar Mosquitto
WORKDIR /tmp
RUN wget https://mosquitto.org/files/source/mosquitto-${MOSQUITTO_VERSION}.tar.gz \
    && tar -xzf mosquitto-${MOSQUITTO_VERSION}.tar.gz \
    && cd mosquitto-${MOSQUITTO_VERSION} \
    && make WITH_WEBSOCKETS=yes WITH_SRV=yes WITH_TLS=yes \
    && make install \
    && ldconfig

# Compilar o plugin mosquitto-jwt-auth
WORKDIR /tmp
RUN git clone https://github.com/wiomoc/mosquitto-jwt-auth.git \
    && cd mosquitto-jwt-auth \
    && cargo build --release
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Estágio 2: Imagem Final (Apenas com os binários e configs)
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
FROM debian:bullseye-slim

ARG JWT_SECRET

# Instalar apenas as dependências de tempo de execução
RUN apt-get update && apt-get install -y \
    libssl-dev \
    libc-ares2 \
    libwebsockets16 \
    libcjson1 \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário e diretórios
RUN groupadd -r mosquitto && useradd -r -g mosquitto mosquitto

RUN mkdir -p /mosquitto/config \
    && mkdir -p /mosquitto/data \
    && mkdir -p /mosquitto/log \
    && mkdir -p /mosquitto/plugins \
    && mkdir -p /mosquitto/run

# Copiar os artefatos compilados do estágio anterior
COPY --from=builder /usr/local/sbin/mosquitto /usr/local/sbin/mosquitto
COPY --from=builder /usr/local/lib/libmosquitto.so.1 /usr/local/lib/libmosquitto.so.1
COPY --from=builder /tmp/mosquitto-jwt-auth/target/release/libmosquitto_jwt_auth.so /mosquitto/plugins/

# Copiar arquivos de configuração
COPY mosquitto.conf /mosquitto/config/mosquitto.conf

COPY entrypoint.sh /entrypoint.sh
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Permissões & Usuário
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
RUN chown -R mosquitto:mosquitto /mosquitto \
    && chmod 644 /mosquitto/config/* \
    && chmod 755 /mosquitto/plugins/libmosquitto_jwt_auth.so \
    && chmod 755 /mosquitto/run \
    && chmod +x /entrypoint.sh

USER mosquitto
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# Portas
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
EXPOSE 1883 9001
# ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/local/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]