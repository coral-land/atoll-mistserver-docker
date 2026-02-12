# Stage 1: Build using a minimal Debian image
FROM debian:stable-slim AS mist_build

ARG MIST_REF=3.10
ARG DEBUG=0
ARG VERSION=0.1.10
ARG RELEASE=Docker_linux/amd64

# Cache apt package list and update sources
RUN echo "deb http://deb.debian.org/debian stable main contrib non-free" > /etc/apt/sources.list && \
    apt-get update

# Install build dependencies
RUN apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    libnss3-dev libnspr4-dev && \
    rm -rf /var/lib/apt/lists/*

# Clone MistServer repository
WORKDIR /src
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

# Configure and build MistServer with static linking
RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -Ddefault_library=static \
    -Dprefer_static=true \
    -Dc_link_args='-static' \
    -Dcpp_link_args='-static' \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    --wrap-mode=nodownload

RUN ninja -C /build install

# Stage 2: Runtime image using distroless
FROM gcr.io/distroless/static-debian12:nonroot

# Label for container metadata
LABEL org.opencontainers.image.title="MistServer True Static"

# Copy binaries from build stage
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

# Copy nsswitch.conf (specific to the build context)
COPY --from=mist_build /etc/nsswitch.conf /etc/nsswitch.conf

# Set up non-root user
RUN useradd -m mistuser && \
    chown -R mistuser: /usr/local/bin/Mist*

# Switch to non-root user
USER mistuser

# Expose required ports
EXPOSE 4242 8080 1935

# Entry point for MistServer
ENTRYPOINT ["/usr/local/bin/MistController"]