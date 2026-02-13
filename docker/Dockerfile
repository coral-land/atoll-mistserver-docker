# --- SECTION 1: Build Stage (Alpine) ---
FROM alpine:3.19 AS mist_build

# Corrected package names for Alpine 3.19
RUN apk add --no-cache \
    build-base cmake meson ninja git pkgconf \
    openssl-dev openssl-libs-static \
    mbedtls-dev mbedtls-static \
    srt-dev srt-static \
    cjson-dev \
    librist-dev \
    linux-headers \
    zlib-static

WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

# We force a 100% static build:
# 1. -Ddefault_library=static tells Meson to use .a files.
# 2. -Dbuild_analysers=false prevents dynamic dependencies on NSS/PAM.
# 3. linker flags -static bake all libraries into the binary.
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

# --- SECTION 2: Final Level (Chainguard Static) ---
# This is a "scratch-like" image with 0 OS packages, meaning 0 vulnerabilities.
FROM cgr.dev/chainguard/static:latest

# Copy only the self-contained binaries
COPY --from=mist_build /usr/local/bin/MistController /MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /MistOutHTTP

# Chainguard static uses the nonroot user (UID 65532) by default
USER 65532:65532

EXPOSE 4242 8080 1935

# Binary is at the root
ENTRYPOINT ["/MistController"]