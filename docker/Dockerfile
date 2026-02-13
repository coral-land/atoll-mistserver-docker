# --- SECTION 1: Build Stage (Debian 12) ---
FROM debian:12-slim AS mist_build

# Install all necessary build tools and libraries
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    libnss3-dev libnspr4-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} https://github.com/DDVTECH/mistserver.git .

# Build MistServer. We use a standard build to avoid the static NSS error.
RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -DNOUPDATE=true \
    && ninja -C /build install

# --- SECTION 2: The Collector Stage ---
# We gather ONLY the files we need into a single folder to copy into Distroless
RUN mkdir -p /out/bin /out/lib && \
    cp /usr/local/bin/MistController /out/bin/ && \
    cp /usr/local/bin/MistUtilHealth /out/bin/ && \
    cp /usr/local/bin/MistOutHTTP /out/bin/ && \
    # Find the MistServer shared library
    find /build -name "libmist.so" -exec cp {} /out/lib/ \;

# Create the DNS config file here in the build stage
RUN echo "hosts: files dns" > /out/nsswitch.conf

# --- SECTION 3: The Hardened Runtime (Distroless CC) ---
# 'cc' includes the C library, which makes the binary actually start.
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"

# Copy our prepared binaries and library
COPY --from=mist_build /out/bin/ /usr/local/bin/
COPY --from=mist_build /out/lib/ /usr/local/lib/
COPY --from=mist_build /out/nsswitch.conf /etc/nsswitch.conf

# Distroless 'nonroot' user is UID 65532. We use the ID directly.
USER 65532:65532
WORKDIR /usr/local/bin

# Tell the binary where to find libmist.so
ENV LD_LIBRARY_PATH=/usr/local/lib

EXPOSE 4242 8080 1935

# Start the controller
ENTRYPOINT ["/usr/local/bin/MistController"]
