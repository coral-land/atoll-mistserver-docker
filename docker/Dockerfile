############################
# Stage 1: build
############################
FROM alpine:3.18 AS mist_build

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

############################
# mbedtls (CMake)
############################
ARG MBEDTLS_VER=3.6.5
ARG MBEDTLS_SHA256=4a11f1777bb95bf4ad96721cac945a26e04bf19f57d905f241fe77ebeddf46d8

RUN curl -fsSL https://github.com/Mbed-TLS/mbedtls/releases/download/mbedtls-${MBEDTLS_VER}/mbedtls-${MBEDTLS_VER}.tar.bz2 \
    -o mbedtls.tar.bz2 \
    && echo "${MBEDTLS_SHA256}  mbedtls.tar.bz2" | sha256sum -c - \
    && tar xjf mbedtls.tar.bz2

RUN cmake -S mbedtls-${MBEDTLS_VER} -B build/mbedtls \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_TESTING=OFF \
    -DENABLE_PROGRAMS=OFF \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_SKIP_RPATH=ON \
    && cmake --build build/mbedtls --parallel \
    && cmake --install build/mbedtls

############################
# libsrtp (CMake)
############################
RUN git clone --depth 1 --branch v2.6.0 https://github.com/cisco/libsrtp.git

RUN cmake -S libsrtp -B build/libsrtp \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DENABLE_TESTS=OFF \
    -DCMAKE_SKIP_RPATH=ON \
    && cmake --build build/libsrtp --parallel \
    && cmake --install build/libsrtp

############################
# libsrt (CMake) - Build as shared to avoid PIC issues
############################
RUN git clone --depth 1 --branch v1.5.4 https://github.com/Haivision/srt.git

RUN cmake -S srt -B build/libsrt \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=ON \
    -DENABLE_APPS=OFF \
    -DENABLE_TESTING=OFF \
    -DCMAKE_SKIP_RPATH=ON \
    && cmake --build build/libsrt --parallel \
    && cmake --install build/libsrt

############################
# librist (Meson)
############################
RUN git clone --depth 1 --branch v0.2.11 https://code.videolan.org/rist/librist.git

RUN meson setup build/librist librist \
    -Ddefault_library=shared \
    --buildtype=release \
    --strip \
    && ninja -C build/librist install

############################
# usrsctp (CMake)
############################
RUN git clone --depth 1 --branch 0.9.5.0 https://github.com/sctplab/usrsctp.git

RUN cmake -S usrsctp -B build/usrsctp \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -Dsctp_build_programs=OFF \
    -Dsctp_build_tests=OFF \
    -DCMAKE_C_FLAGS="-Wno-error=maybe-uninitialized" \
    -DCMAKE_SKIP_RPATH=ON \
    && cmake --build build/usrsctp --parallel \
    && cmake --install build/usrsctp

############################
# MistServer (Meson)
############################
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10

WORKDIR /src
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} mist

WORKDIR /src/mist

# Pre-create subprojects directory to avoid warnings
RUN mkdir -p subprojects

ARG DEBUG=0
ARG VERSION=Unknown
ARG TARGETPLATFORM
ARG RELEASE=Docker_${TARGETPLATFORM}

# Build MistServer with system libraries
RUN meson setup /build . \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    -Dmbedtls=disabled \
    -Dlibsrtp2=disabled \
    --buildtype=release \
    --strip \
    && ninja -C /build install

############################
# Stage 2: runtime (distroless)
############################
FROM gcr.io/distroless/cc:nonroot

LABEL org.opencontainers.image.title="MistServer"
LABEL org.opencontainers.image.description="High-performance streaming server"
LABEL org.opencontainers.image.source="https://github.com/DDVTECH/mistserver"
LABEL org.opencontainers.image.version="${VERSION:-unknown}"

# Copy required libraries and binaries
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/lib/ /usr/local/lib/

# Create necessary directories
RUN ["/busybox/sh", "-c", "mkdir -p /config && mkdir -p /media"]

USER 65532:65532
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935 5554 8889/udp 18203/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]