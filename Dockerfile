# Database download container
FROM alpine:3.20@sha256:beefdbd8a1da6d2915566fde36db9db0b524eb737fc57cd1367effd16dc0d06d as database

RUN apk add --no-cache gzip tar wget && rm -rf /var/cache/apk/*

# -- Install CA certificates and update them to disable emSign ECC Root CA - G3 and Comodo AAA Services root --
RUN apk add --no-cache ca-certificates && \
    sed -i \
      -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' \
      -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' \
      /etc/ca-certificates.conf && \
    update-ca-certificates --fresh

ARG LICENSE_KEY

RUN wget -O "GeoLite2-City.tar.gz" "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$LICENSE_KEY&suffix=tar.gz"
RUN tar -xzvf GeoLite2-City*.tar.gz

# Rust compile container
FROM rust:1.98@sha256:a8a5f0a1e5fe7dfe1d352591e4a1c7dd2c08fd70475cae872cf3458ba0df0546 as build

# -- Update CA certificates to disable emSign ECC Root CA - G3 and Comodo AAA Services root --
RUN sed -i \
      -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' \
      -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' \
      /etc/ca-certificates.conf && \
    update-ca-certificates --fresh

RUN rustup target add x86_64-unknown-linux-musl

RUN USER=root cargo new --bin ipv4-geolocate-webservice
WORKDIR /ipv4-geolocate-webservice

COPY ./Cargo.lock ./Cargo.lock
COPY ./Cargo.toml ./Cargo.toml
COPY ./src ./src

RUN cargo build --release --target x86_64-unknown-linux-musl

# Final container
FROM scratch

COPY --from=database /GeoLite2-City_*/GeoLite2-City.mmdb .
COPY --from=build /ipv4-geolocate-webservice/target/x86_64-unknown-linux-musl/release/ipv4-geolocate-webservice .

CMD ["./ipv4-geolocate-webservice"]