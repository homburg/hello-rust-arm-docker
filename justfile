arm-arch := "aarch64-unknown-linux-gnu"

image := "test-rust-arm-docker-build"

build-chef:
    docker build -t test-rust-arm-docker-build --rm .

build *FLAGS:
    docker build -t {{image}} {{FLAGS}} -f Dockerfile.cross .

run *FLAGS:
    docker run --rm -it {{FLAGS}} {{image}}

cargo-build-arm:
    cargo build --target {{arm-arch}}