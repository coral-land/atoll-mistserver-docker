## [Section 1: High-Performance Build Environment]
FROM ubuntu:24.04 AS mist_build

# Hardening flags to prevent buffer overflows and memory corruption
ENV CFLAGS="-O3 -fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-z,relro,-z,now -pie"

# Install build-essential and standard security-audited libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    meson \
    ninja-build \
    git \
    pkg-config \
    libcjson-dev \
    libssl-dev \
    libmicrohttpd-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} .

## [Section 3: Secure Compilation]
ARG DEBUG=0
ARG VERSION=0.1.4
ARG TARGETPLATFORM
ARG RELEASE=Docker_linux/amd64

# Force system libraries (-Dwrap_mode=nofallback) to bypass buggy internal subprojects
RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    -Dwrap_mode=nofallback \
    && ninja -C /build install

## [Section 4: Dependency Isolation]
# We gather only the specific shared libraries needed for the runtime
RUN mkdir -p /deps && \
    cp /usr/lib/x86_64-linux-gnu/libssl.so.3 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libcjson.so.1 /deps/ && \
    cp /usr/lib/x86_64-linux-gnu/libmicrohttpd.so.12 /deps/

## [Section 5: Extremely Hardened Runtime]
# Distroless CC contains glibc but no shell or other utilities
FROM gcr.io/distroless/cc-debian12:nonroot

ARG VERSION=0.1.4
LABEL org.opencontainers.image.title="MistServer Hardened"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL security.hardened="true"

## [Section 6: Secure Asset Migration]
# Copy the core binaries
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

# Copy gathered shared libraries into the runtime's library path
COPY --from=mist_build /deps/ /usr/lib/x86_64-linux-gnu/

## [Section 7: Execution Configuration]
# Runtime workdir and non-root user enforcement
WORKDIR /usr/local/bin
USER nonroot:nonroot

# Minimal port exposure
EXPOSE 4242 8080 1935

# Healthcheck using the native Mist tool (more secure than curl/sh)
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]