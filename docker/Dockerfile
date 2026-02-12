## [Section 1: High-Performance Build Environment]
FROM ubuntu:24.04 AS mist_build

# Avoid breaking the linker: Meson handles PIC/PIE internally for libraries.
# We keep -O3 for performance but remove the conflicting -fPIE/-pie from global ENV.
ENV CFLAGS="-O3 -fstack-protector-strong -D_FORTIFY_SOURCE=2"
ENV CXXFLAGS="${CFLAGS}"

# Install dependencies including the ones that cause subproject fallbacks
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
ARG VERSION=0.1.10
ARG RELEASE=Docker_linux/amd64

# FIX: We use Meson's built-in 'b_pie' and 'b_relro' for hardening.
# This ensures binaries get PIE while libraries (like libmist.so) stay as valid shared objects.
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

## [Section 4: Robust Runtime Dependency Mapping]
RUN mkdir -p /deps && \
    for bin in /usr/local/bin/MistController /usr/local/bin/MistUtilHealth /usr/local/bin/MistOutHTTP; do \
    ldd "$bin" | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /deps/; \
    done

## [Section 5: Hardened Runtime]
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"

## [Section 6: Asset Migration]
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP
# Also copy the shared library the build just failed on (it will work now!)
COPY --from=mist_build /usr/local/lib/libmist.so /usr/local/lib/libmist.so

# Copy all discovered dependencies
COPY --from=mist_build /deps/ /usr/lib/x86_64-linux-gnu/

## [Section 7: Execution]
WORKDIR /usr/local/bin
USER nonroot:nonroot

ENV LD_LIBRARY_PATH=/usr/local/lib:/usr/lib/x86_64-linux-gnu

EXPOSE 4242 8080 1935

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]