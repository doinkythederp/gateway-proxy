FROM docker.io/library/alpine:edge AS builder
ARG SIMD=1

RUN apk upgrade && \
    apk add curl gcc g++ musl-dev cmake make && \
    curl -sSf https://sh.rustup.rs | sh -s -- --profile minimal --default-toolchain nightly -y

WORKDIR /build

COPY Cargo.toml Cargo.lock ./

RUN mkdir src/
RUN echo 'fn main() {}' > ./src/main.rs
RUN source $HOME/.cargo/env && \
    if [ "$SIMD" == '0' ]; then \
        cargo build --release --no-default-features --features no-simd; \
    else \
        cargo build --release; \
    fi

RUN rm -f target/release/deps/gateway_proxy*
COPY ./src ./src

RUN source $HOME/.cargo/env && \
    if [ "$TARGET_CPU" == 'x86-64' ]; then \
        cargo build --release --no-default-features --features no-simd; \
    else \
        cargo build --release; \
    fi && \
    cp target/release/gateway-proxy /gateway-proxy && \
    strip /gateway-proxy

FROM scratch

COPY --from=builder /gateway-proxy /gateway-proxy

CMD ["./gateway-proxy"]
