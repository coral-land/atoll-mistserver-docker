############################
# Stage 1: build
############################
FROM alpine:3.18 AS mist_build

# Security hardening compiler/linker flags
ENV CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-z,relro,-z,now"

# Build dependencies only
RUN apk add --no-cache \
    build-base \
    cmake \
    meson \
    ninja \
    python3 \
    git \
    linux-headers \
    curl \
    pigz \
    pkgconfig \
    cjson-dev \
    openssl-dev

ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
WORKDIR /deps

# [All your dependency build steps for mbedtls, libsrtp, libsrt, librist, usrsctp remain EXACTLY THE SAME]
# ... (Include the exact blocks from your provided Dockerfile here, they are correct)

############################
# MistServer (Meson) - THE FIX IS HERE
############################
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10

WORKDIR /src
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} mist

WORKDIR /src/mist

ARG DEBUG=0
ARG VERSION=Unknown
ARG TARGETPLATFORM
ARG RELEASE=Docker_${TARGETPLATFORM}

# Build MistServer - REMOVED THE INVALID OPTIONS
RUN meson setup /build . \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    --buildtype=release \
    --strip \
    && ninja -C /build install

############################
# Stage 2: runtime (distroless)
############################
FROM gcr.io/distroless/cc:nonroot

# Version is passed as a build argument from the pipeline
ARG VERSION=unknown
LABEL org.opencontainers.image.title="MistServer"
LABEL org.opencontainers.image.description="Hardened, high-performance streaming server built from source"
LABEL org.opencontainers.image.source="https://github.com/DDVTECH/mistserver"
LABEL org.opencontainers.image.version="${VERSION}"

# Copy required binaries and libraries
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/lib/ /usr/local/lib/

# Create runtime directories using the minimal shell available in distroless
RUN ["/busybox/sh", "-c", "mkdir -p /config && mkdir -p /media"]

USER nonroot:nonroot
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935 5554 8889/udp 18203/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]