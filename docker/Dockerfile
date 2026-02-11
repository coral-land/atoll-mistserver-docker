############################
# Stage 1: build
############################
FROM alpine:3.18 AS mist_build

ENV CFLAGS="-O2 -fstack-protector-strong -D_FORTIFY_SOURCE=2"
ENV CXXFLAGS="${CFLAGS}"
ENV LDFLAGS="-Wl,-z,relro,-z,now"

RUN apk add --no-cache \
    build-base cmake meson ninja python3 git \
    linux-headers curl pkgconfig cjson-dev openssl-dev \
    libmicrohttpd-dev

WORKDIR /src
ARG MIST_REPO=https://github.com/DDVTECH/mistserver.git
ARG MIST_REF=3.10
RUN git clone --depth 1 --branch ${MIST_REF} ${MIST_REPO} .

ARG DEBUG=0
ARG VERSION=0.1.2
ARG TARGETPLATFORM
ARG RELEASE=Docker_linux/amd64

RUN meson setup /build . \
    --buildtype=release \
    --strip \
    -DNOUPDATE=true \
    -DDEBUG=${DEBUG} \
    -DVERSION=${VERSION} \
    -DRELEASE=${RELEASE} \
    -Dforce_fallback_for=[] \
    && ninja -C /build install

############################
# Stage 2: Runtime Hardening (The Library "Collector")
############################

FROM alpine:3.18 AS lib_collector

RUN mkdir -p /secure_libs
COPY --from=mist_build /usr/local/lib/ /secure_libs/

RUN cp /usr/lib/libcrypto.so.3 /secure_libs/ || true
RUN cp /usr/lib/libssl.so.3 /secure_libs/ || true
RUN cp /usr/lib/libcjson.so.1 /secure_libs/ || true

############################
# Stage 3: Final Production Image
############################
FROM gcr.io/distroless/cc-debian12:nonroot

LABEL org.opencontainers.image.title="MistServer Hardened"
LABEL org.opencontainers.image.description="Minimal attack surface streaming server"

# Copy Binaries
COPY --from=mist_build /usr/local/bin/MistController /usr/local/bin/MistController
COPY --from=mist_build /usr/local/bin/MistUtilHealth /usr/local/bin/MistUtilHealth
COPY --from=mist_build /usr/local/bin/MistOutHTTP /usr/local/bin/MistOutHTTP
COPY --from=lib_collector /secure_libs/ /usr/lib/

WORKDIR /usr/local/bin
EXPOSE 4242 8080 1935

USER nonroot:nonroot

ENTRYPOINT ["/usr/local/bin/MistController"]