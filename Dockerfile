FROM --platform=amd64 lukemathwalker/cargo-chef:latest-rust-1 AS chef

RUN dpkg --add-architecture arm64 && apt-get update && apt-get install -y --no-install-recommends \
    gcc-aarch64-linux-gnu \
    libc6-dev-arm64-cross \
    libssl-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

RUN rustup target add aarch64-unknown-linux-gnu

WORKDIR /app

FROM chef AS planner
COPY . .
RUN PKG_CONFIG_SYSROOT_DIR=/ \
        cargo chef prepare --recipe-path recipe.json

FROM chef AS builder 
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!

RUN PKG_CONFIG_SYSROOT_DIR=/ \
        cargo chef cook --release \
        --target aarch64-unknown-linux-gnu \
        --recipe-path recipe.json

# Build application
COPY . .
RUN PKG_CONFIG_SYSROOT_DIR=/ \
        cargo build --release --target aarch64-unknown-linux-gnu

# We do not need the Rust toolchain to run the binary!
FROM --platform=arm64 debian:buster-slim AS runtime
WORKDIR /app
COPY --from=builder /app/target/aarch64-unknown-linux-gnu/release/app /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/app"]