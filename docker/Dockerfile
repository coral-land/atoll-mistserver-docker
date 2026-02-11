## [Section 1: High-Performance Build Environment]
FROM ubuntu:24.04 AS mist_build

ENV CFLAGS="-O3 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-z,relro,-z,now -pie"

# Added libsrtp2-dev and libssl-dev (which provides mbedtls-compatible crypto)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    meson \
    ninja-build \
    git \
    pkg-config \
    libcjson-dev \
    libssl-dev \
    libsrtp2-dev \
    libmicrohttpd-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} .

## [Section 3: Secure Compilation]
ARG DEBUG=0
ARG VERSION=0.1.6
ARG TARGETPLATFORM
ARG RELEASE=Docker_linux/amd64

# We allow mbedtls fallback because MistServer uses a specific fork for some protocols,
# but we keep nofallback for other system dependencies.
RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    && ninja -C /build install

## [Section 4: Dependency Isolation]
# Gather shared libraries required for the runtime
RUN mkdir -p /deps && \
    cp /usr/lib/x86_64-linux-gnu/libssl.so.3 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libcjson.so.1 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libsrtp2.so.1 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libmicrohttpd.so.12 /deps/

## [Section 5: Extremely Hardened Runtime]
FROM gcr.io/distroless/cc-debian12:nonroot

ARG VERSION=0.1.6
LABEL org.opencontainers.image.title="MistServer Hardened"
LABEL org.opencontainers.image.version="${VERSION}"

## [Section 6: Secure Asset Migration]
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

# Distroless uses /usr/lib/x86_64-linux-gnu for library lookups
COPY --from=mist_build /deps/ /usr/lib/x86_64-linux-gnu/

## [Section 7: Execution Configuration]
WORKDIR /usr/local/bin
USER nonroot:nonroot

EXPOSE 4242 8080 1935

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]