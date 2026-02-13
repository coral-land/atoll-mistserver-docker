# --- SECTION 1: Build & Patch Stage ---
FROM debian:12-slim AS mist_build

# 1. Update the OS and install security patches BEFORE building
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    libnss3-dev libnspr4-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

RUN meson setup /build . --buildtype=release --strip -DNOUPDATE=true \
    && ninja -C /build install

# --- SECTION 2: The Collector (The "Surgical" Fix) ---
RUN mkdir -p /out/bin /out/lib && \
    cp /usr/local/bin/MistController /out/bin/ && \
    cp /usr/local/bin/MistUtilHealth /out/bin/ && \
    cp /usr/local/bin/MistOutHTTP /out/bin/ && \
    find /build -name "libmist.so" -exec cp {} /out/lib/ \; && \
    # This loop grabs the NEWLY PATCHED libraries from the build stage OS
    # Overwriting the old ones in the scanner's view
    for bin in /out/bin/* /out/lib/libmist.so; do \
    ldd "$bin" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /out/lib/; \
    done && \
    echo "hosts: files dns" > /out/nsswitch.conf

# --- SECTION 3: The Hardened Runtime ---
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened & Patched"

COPY --from=mist_build /out/lib/ /lib/x86_64-linux-gnu/
COPY --from=mist_build /out/bin/ /usr/local/bin/
COPY --from=mist_build /out/nsswitch.conf /etc/nsswitch.conf

ENV LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:/usr/local/lib

USER 65532:65532
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935
ENTRYPOINT ["/usr/local/bin/MistController"]