## [Section 1: Build Environment Setup]
FROM debian:bookworm-slim AS mist_build

ENV CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-z,relro,-z,now"

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
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} .

## [Section 3: Compilation and Installation]
ARG DEBUG=0
ARG VERSION=0.1.4
ARG TARGETPLATFORM
ARG RELEASE=Docker_linux/amd64

RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    -Dwrap_mode=nofallback \
    && ninja -C /build install

## [Section 4: Hardened Runtime Image]
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"
LABEL org.opencontainers.image.version="${VERSION}"

## [Section 5: Binary and Dependency Migration]
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

COPY --from=mist_build /usr/lib/x86_64-linux-gnu/libssl.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=mist_build /usr/lib/x86_64-linux-gnu/libcrypto.so.3 /usr/lib/x86_64-linux-gnu/
COPY --from=mist_build /usr/lib/x86_64-linux-gnu/libcjson.so.1 /usr/lib/x86_64-linux-gnu/
COPY --from=mist_build /usr/lib/x86_64-linux-gnu/libmicrohttpd.so.12 /usr/lib/x86_64-linux-gnu/

## [Section 6: Execution Configuration]
WORKDIR /usr/local/bin
USER nonroot:nonroot

EXPOSE 4242 8080 1935

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s \
    CMD ["/usr/local/bin/MistUtilHealth"]

ENTRYPOINT ["/usr/local/bin/MistController"]