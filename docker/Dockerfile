## [Section 1: Build Environment]
FROM ubuntu:24.04 AS mist_build

# We use -static flags to force the compiler to include library code in the binary
ENV CFLAGS="-O3 -static -fstack-protector-all -D_FORTIFY_SOURCE=2"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-static -Wl,-z,relro,-z,now"

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake meson ninja-build git pkg-config ca-certificates \
    libcjson-dev libssl-dev libmbedtls-dev libsrtp2-dev \
    libmicrohttpd-dev libsrt-openssl-dev librist-dev libusrsctp-dev \
    && rm -rf /var/lib/apt/lists/*

## [Section 2: Source Acquisition]
WORKDIR /src
RUN git clone --depth 1 --branch 3.10 https://github.com/DDVTECH/mistserver.git .

## [Section 3: Static Compilation]
# We tell Meson to prefer static linking for all subcomponents
RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -Ddefault_library=static \
    -Dprefer_static=true \
    -Db_pie=false \
    -DNOUPDATE=true \
    && ninja -C /build install

## [Section 4: The Ultimate Hardened Runtime]
# 'static' is the most stripped-down image Google offers. 
# It has NOTHING inside except timezone data and CA certificates.
FROM gcr.io/distroless/static-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Static Hardened"

# Copy the self-contained binaries
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP

# No LD_LIBRARY_PATH needed! The binary doesn't look for external files.
USER nonroot:nonroot
WORKDIR /usr/local/bin

EXPOSE 4242 8080 1935

# Note: Healthcheck might need an internal HTTP check if the binary is 100% static
ENTRYPOINT ["/usr/local/bin/MistController"]