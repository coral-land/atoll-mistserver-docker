# --- SECTION 1: Build Stage (Alpine) ---
FROM alpine:3.19 AS mist_build

RUN apk add --no-cache \
    build-base cmake meson ninja git pkgconf \
    openssl-dev openssl-libs-static \
    mbedtls-dev mbedtls-static \
    cjson-dev \
    linux-headers \
    zlib-static \
    --repository=https://dl-cdn.alpinelinux.org/alpine/v3.19/community \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
    srt-dev librist-dev

WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -Ddefault_library=static \
    -Dprefer_static=true \
    -Dbuild_analysers=false \
    -Dc_link_args='-static' \
    -Dcpp_link_args='-static' \
    -DNOUPDATE=true \
    && ninja -C /build install

# --- SECTION 2: Zero-Vulnerability Runtime ---
FROM cgr.dev/chainguard/static:latest

LABEL org.opencontainers.image.title="MistServer Zero-CVE Static"

# Copy the binaries (they now contain all their libraries internally)
COPY --from=mist_build /usr/local/bin/MistController /MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /MistOutHTTP

USER 65532:65532
EXPOSE 4242 8080 1935

ENTRYPOINT ["/MistController"]