# --- SECTION 1: Build Stage (Alpine) ---
# We use Alpine to create a 100% static binary that needs NO OS to run.
FROM alpine:3.19 AS mist_build

# Install build tools and the STATIC versions of libraries
RUN apk add --no-cache \
    build-base cmake meson ninja git pkgconfig \
    openssl-dev openssl-libs-static \
    mbedtls-dev mbedtls-static \
    libsrt-dev libsrt-static \
    libcjson-dev \
    librist-dev \
    linux-headers \
    zlib-static

WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

# Build flags for a pure static binary
# We disable 'analysers' because they require dynamic NSS libraries which don't link statically.
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

# --- SECTION 2: The Modern Distroless Runtime (Chainguard) ---
# This is a "Distroless" image, but it's not Debian. 
# It is designed to have 0 known vulnerabilities.
FROM cgr.dev/chainguard/static:latest

LABEL org.opencontainers.image.title="MistServer Zero-CVE Distroless"

# Copy the static binaries. They carry their own libraries inside them.
COPY --from=mist_build /usr/local/bin/MistController /MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /MistOutHTTP

# Chainguard static images use UID 65532 by default
USER 65532:65532

EXPOSE 4242 8080 1935

# Entrypoint points to the root binary
ENTRYPOINT ["/MistController"]