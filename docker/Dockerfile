## [Section 1: High-Performance Build Environment]
FROM ubuntu:24.04 AS mist_build

# Security hardening flags
ENV CFLAGS="-O3 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-z,relro,-z,now -pie"

# Install dependencies - Added libmbedtls-dev to prevent the subproject trigger
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev \
    libssl-dev \
    libmbedtls-dev \
    libsrtp2-dev \
    libmicrohttpd-dev \
    libsrt-openssl-dev \
    librist-dev \
    libusrsctp-dev \
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} .

## [Section 3: Secure Compilation]
ARG DEBUG=0
ARG VERSION=0.1.8
ARG RELEASE=Docker_linux/amd64

# FIX: We use --wrap-mode=nodownload to force Meson to use the apt packages.
# We also explicitly point to system libraries to bypass the buggy subproject logic.
RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    --wrap-mode=nodownload \
    && ninja -C /build install

## [Section 4: Robust Runtime Dependency Mapping]
# Instead of hardcoding versions (like .so.3), we use a script to find 
# exactly what the binaries linked against. This prevents "file not found" errors.
RUN mkdir -p /deps && \
    for bin in /usr/local/bin/MistController /usr/local/bin/MistUtilHealth /usr/local/bin/MistOutHTTP; do \
    ldd "$bin" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /deps/; \
    done

## [Section 5: Extremely Hardened Runtime]
FROM gcr.io/distroless/cc-debian12:nonroot

ARG VERSION=0.1.8
LABEL org.opencontainers.image.title="MistServer Hardened"
LABEL org.opencontainers.image.version="${VERSION}"

## [Section 6: Secure Asset Migration]
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

# Copy all discovered dependencies into the library path
COPY --from=mist_build /deps/ /usr/lib/x86_64-linux-gnu/

## [Section 7: Execution Configuration]
WORKDIR /usr/local/bin
USER nonroot:nonroot

# Default MistServer ports
EXPOSE 4242 8080 1935

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]