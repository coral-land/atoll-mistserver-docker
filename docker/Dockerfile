# -------------------------------
# SECTION 1: Build & Compile MistServer
# - Uses Debian 12 to compile MistServer from source
# - Installs all required build dependencies
# - Produces optimized release binaries
# -------------------------------

FROM debian:12-slim AS mist_build

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


# -------------------------------
# SECTION 2: Collect Runtime Artifacts
# - Copies compiled binaries
# - Copies libmist.so
# - Dynamically collects required shared libraries
# - Adds NSS libraries for hostname resolution
# - Creates required system configuration files
# -------------------------------

RUN mkdir -p /out/bin /out/lib /out/etc && \
    cp /usr/local/bin/MistController /out/bin/ && \
    cp /usr/local/bin/MistOutHTTP /out/bin/ && \
    cp /usr/local/bin/MistUtilHealth /out/bin/ && \
    find /build -name "libmist.so" -exec cp {} /out/lib/ \; && \
    for bin in /out/bin/* /out/lib/libmist.so; do \
    ldd "$bin" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /out/lib/; \
    done && \
    cp /lib/x86_64-linux-gnu/libnss_files.so.2 /out/lib/ && \
    cp /lib/x86_64-linux-gnu/libnss_dns.so.2 /out/lib/ && \
    cp /lib/x86_64-linux-gnu/libresolv.so.2 /out/lib/ && \
    echo "hosts: files dns" > /out/etc/nsswitch.conf && \
    echo "127.0.0.1 localhost" > /out/etc/hosts


# -------------------------------
# SECTION 3: Minimal Hardened Runtime
# - Uses distroless Debian 12 runtime
# - Copies only required libraries and binaries
# - Enables proper NSS resolution
# - Runs as non-root user
# -------------------------------

FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"

COPY --from=mist_build /out/lib/ /lib/x86_64-linux-gnu/
COPY --from=mist_build /out/bin/ /usr/local/bin/
COPY --from=mist_build /out/etc/nsswitch.conf /etc/nsswitch.conf
COPY --from=mist_build /out/etc/hosts /etc/hosts

ENV LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/local/lib

USER 65532:65532
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935

ENTRYPOINT ["/usr/local/bin/MistController"]