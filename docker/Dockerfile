## [Section 1: Static Build Environment]
FROM ubuntu:24.04 AS mist_build

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    libnss3-dev libnspr4-dev \
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

## [Section 3: Static Compilation]
ARG DEBUG=0
ARG VERSION=0.1.10
ARG RELEASE=Docker_linux/amd64

RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -Ddefault_library=static \
    -Dprefer_static=true \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    --wrap-mode=nodownload \
    && ninja -C /build install

RUN echo "hosts: files dns" > /tmp/nsswitch.conf

## [Section 4: The Ultimate Hardened Runtime]
FROM gcr.io/distroless/static-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Fully Static"

# Copy the self-contained binaries
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

# FIX: Copy the file from the build stage instead of trying to RUN a command
COPY --from=mist_build /tmp/nsswitch.conf /etc/nsswitch.conf

USER nonroot:nonroot
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935

ENTRYPOINT ["/usr/local/bin/MistController"]