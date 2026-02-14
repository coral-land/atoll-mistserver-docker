# ---------------------------------
# SECTION 1: Build MistServer
# - Compile from source
# - Produce stripped release binaries
# ---------------------------------

FROM debian:12-slim AS build

ARG MIST_REF=3.10

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    libnss3-dev libnspr4-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

RUN meson setup /build . --buildtype=release --strip -DNOUPDATE=true && \
    ninja -C /build install


# ---------------------------------
# SECTION 2: Hardened Runtime
# - Minimal Debian runtime
# - No build tools
# - Non-root user
# - Read-only filesystem compatible
# ---------------------------------

FROM debian:12-slim

# We add 'iproute2' to help with internal networking resolution if needed
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates libssl3 libmbedtls14 libsrtp2-1 \
    libmicrohttpd12 librist4 libusrsctp2 \
    libnss3 libnspr4 iproute2 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Create dedicated runtime user
RUN useradd -r -u 65532 -g nogroup -d /nonexistent -s /usr/sbin/nologin mist

# Copy only installed runtime artifacts
COPY --from=build /usr/local/bin/ /usr/local/bin/
COPY --from=build /usr/local/lib/ /usr/local/lib/

# REPAIR: Refresh library cache and create a writable config dir
RUN ldconfig && \
    mkdir -p /config && \
    chown -R mist:nogroup /config

ENV LD_LIBRARY_PATH=/usr/local/lib

USER 65532:65532
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935

# Start with the config file flag to ensure it uses our writable volume
ENTRYPOINT ["/usr/local/bin/MistController", "-c", "/config/server.conf"]