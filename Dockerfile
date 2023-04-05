FROM --platform=amd64 lukemathwalker/cargo-chef:latest-rust-1 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder 
COPY --from=planner /app/recipe.json recipe.json
# Build dependencies - this is the caching Docker layer!
RUN cargo chef cook --release \
        --target aarch64-unknown-linux-gnu \
        --recipe-path recipe.json

# Build application
COPY . .
RUN cargo build --release --target aarch64-unknown-linux-gnu

# We do not need the Rust toolchain to run the binary!
FROM debian:buster-slim AS runtime
WORKDIR /app
COPY --from=builder /app/target/release/app /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/app"]