# Use a small, modern Alpine for building. Pin the version in CI with digest.
ARG ALPINE_VER=3.18
FROM alpine:${ALPINE_VER} AS builder

# metadata for forensics
LABEL org.opencontainers.image.source="https://your.repo/url"
ARG GIT_SHA=unknown
LABEL org.opencontainers.image.revision=${GIT_SHA}

# Install strictly build-time deps. (meson requires python)
RUN apk add --no-cache --virtual .build-deps \
    build-base \
    meson \
    ninja \
    python3 \
    pkgconfig \
    musl-dev \
    linux-headers \
    git \
    patch \
    curl \
    pigz \
    cjson-dev \
    lz4-dev \
    && python3 -m pip install --no-cache-dir meson

WORKDIR /deps

# A pattern to download + verify archives (example for mbedtls).
# IMPORTANT: replace CHECKSUM with a trusted sha256 — verify in CI + pin upstream release digests.
ARG MBEDTLS_URL=https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-3.6.5/mbedtls-3.6.5.tar.bz2
ARG MBEDTLS_SHA256=<REPLACE_WITH_SHA256>
RUN set -eux; \
    curl -fSL --retry 5 ${MBEDTLS_URL} -o mbedtls.tar.bz2; \
    echo "${MBEDTLS_SHA256}  mbedtls.tar.bz2" | sha256sum -c -; \
    tar xjf mbedtls.tar.bz2 --strip-components=0 -C /deps

# Create isolated build dirs so we can set meson options independently
RUN mkdir -p /deps/build/mbedtls /deps/build/libsrtp /deps/build/libsrt /deps/build/librist /deps/build/usrsctp

# Build each dependency static if possible. Pass meson option to prefer static libs.
# Note: use -Ddefault_library=static where supported and -Dstrip=true
# mbedtls: (example)
RUN cd /deps/build/mbedtls && \
    meson setup /deps/mbedtls-3.6.5 -Dstrip=true -Ddefault_library=static && \
    ninja -C /deps/build/mbedtls install

# libsrtp: use pinned commit (use git clone with tag in CI or replace ADD with verified source)
RUN git clone --branch v2.6.0 --depth 1 https://github.com/cisco/libsrtp.git /deps/libsrtp-src && \
    cd /deps/build/libsrtp && \
    meson setup /deps/libsrtp-src -Dstrip=true -Ddefault_library=static && \
    ninja -C /deps/build/libsrtp install

# libsrt
RUN git clone --branch v1.5.4 --depth 1 https://github.com/Haivision/srt.git /deps/libsrt && \
    # if the project expects meson subdirs override meson files as you did before
    cd /deps/build/libsrt && \
    meson setup /deps/libsrt -Dstrip=true -Ddefault_library=static && \
    ninja -C /deps/build/libsrt install

# librist
RUN git clone --branch v0.2.11 --depth 1 https://code.videolan.org/rist/librist.git /deps/librist-src && \
    cd /deps/build/librist && \
    meson setup /deps/librist-src -Dstrip=true -Ddefault_library=static && \
    ninja -C /deps/build/librist install

# usrsctp
RUN git clone --branch 0.9.5.0 --depth 1 https://github.com/sctplab/usrsctp.git /deps/usrsctp-src && \
    cd /deps/build/usrsctp && \
    meson setup /deps/usrsctp-src -Dstrip=true -Ddefault_library=static && \
    ninja -C /deps/build/usrsctp install

# Build MistServer from local source
COPY . /src
WORKDIR /build
# Force static where supported and release optimizations, strip later
ARG MIST_OPTS=""
ARG DEBUG=0
ARG VERSION=Unknown
ARG TARGETPLATFORM
ARG RELEASE=Docker_${TARGETPLATFORM}
RUN set -eux; \
    meson setup /src -DNOUPDATE=true -DDEBUG=${DEBUG} -DVERSION=${VERSION} -DRELEASE=${RELEASE} \
    -Dstrip=true -Ddefault_library=static ${MIST_OPTS} /builddir && \
    ninja -C /builddir && \
    ninja -C /builddir install

# Strip any remaining symbols for smallest binary
RUN set -eux; \
    find /usr/local -type f -executable -exec file {} \; | grep ELF || true; \
    find /usr/local -type f -executable -exec strip --strip-all {} \; || true

# Optional debug upload (only run when OUTPUT_DBG provided)
ARG OUTPUT_DBG
RUN if [ -n "${OUTPUT_DBG}" ]; then tar cf - /build /src /deps | pigz -6 | curl --upload-file - "${OUTPUT_DBG}" ; fi

#### Stage: runtime (tiny, non-root, no shell) ####
# Distroless CC includes libc/libstdc++ but no shell or package manager.
FROM gcr.io/distroless/cc:nonroot AS runtime

# Add immutable metadata and provenance labels
LABEL org.opencontainers.image.source="https://your.repo/url"
LABEL org.opencontainers.image.revision=${GIT_SHA}
# Copy only the files you need (binaries + config)
COPY --from=builder /usr/local/ /usr/local/

# If there's a single controller binary at /usr/local/bin/MistController:
WORKDIR /usr/local/bin

# Distroless nonroot runs as a non-privileged user (65532)
# Exec form healthcheck (no shell)
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
    CMD ["/usr/local/bin/MistUtilHealth"]

EXPOSE 4242 8080 1935 5554 8889/udp 18203/udp

ENTRYPOINT ["/usr/local/bin/MistController"]
