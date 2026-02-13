# --- SECTION 1: Build Stage (Debian 12) ---
FROM debian:12-slim AS mist_build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    libnss3-dev libnspr4-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

# Standard dynamic build
RUN meson setup /build . --buildtype=release --strip -DNOUPDATE=true \
    && ninja -C /build install

# --- SECTION 2: The Dependency Collector ---
RUN mkdir -p /out/bin /out/lib && \
    cp /usr/local/bin/MistController /out/bin/ && \
    cp /usr/local/bin/MistUtilHealth /out/bin/ && \
    cp /usr/local/bin/MistOutHTTP /out/bin/ && \
    find /build -name "libmist.so" -exec cp {} /out/lib/ \; && \
    # This loop finds EVERY .so file MistServer needs and copies it to /out/lib
    for bin in /out/bin/* /out/lib/libmist.so; do \
    ldd "$bin" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /out/lib/; \
    done && \
    echo "hosts: files dns" > /out/nsswitch.conf

# --- SECTION 3: The Hardened Runtime ---
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"

# Copy EVERYTHING we collected: binaries, libmist, and all system .so dependencies
COPY --from=mist_build /out/bin/ /usr/local/bin/
COPY --from=mist_build /out/lib/ /usr/local/lib/
COPY --from=mist_build /out/nsswitch.conf /etc/nsswitch.conf

# Tell the system to look in /usr/local/lib for mbedtls, ssl, etc.
ENV LD_LIBRARY_PATH=/usr/local/lib
USER 65532:65532
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935

ENTRYPOINT ["/usr/local/bin/MistController"]