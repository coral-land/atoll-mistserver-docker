## [Section 1: High-Performance Build Environment]
FROM ubuntu:24.04 AS mist_build

ENV CFLAGS="-O3 -fstack-protector-strong -D_FORTIFY_SOURCE=2"
ENV CXXFLAGS="${CFLAGS}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

## [Section 3: Secure Compilation]
ARG DEBUG=0
ARG VERSION=0.1.10
ARG RELEASE=Docker_linux/amd64

RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -Db_pie=true \
    -Db_relro=true \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    --wrap-mode=nodownload \
    && ninja -C /build install

## [Section 4: The "Collector" Step]
RUN mkdir -p /out/bin /out/lib /out/deps && \
    cp /usr/local/bin/MistController /out/bin/ && \
    cp /usr/local/bin/MistUtilHealth /out/bin/ && \
    cp /usr/local/bin/MistOutHTTP /out/bin/ && \
    find /build -name "libmist.so" -exec cp {} /out/lib/ \; && \
    for bin in /out/bin/* /out/lib/*; do \
    ldd "$bin" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /out/deps/; \
    done

## [Section 5: Hardened Runtime]
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"

## [Section 6: Secure Asset Migration]
# Copy binaries
COPY --from=mist_build /out/bin/ /usr/local/bin/
# Copy libmist.so
COPY --from=mist_build /out/lib/ /usr/local/lib/
# Copy system dependencies
COPY --from=mist_build /out/deps/ /usr/lib/x86_64-linux-gnu/

## [Section 7: Execution Configuration]
WORKDIR /usr/local/bin
USER nonroot:nonroot

# Point to both the system libs and our internal libmist
ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib/x86_64-linux-gnu

EXPOSE 4242 8080 1935

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]