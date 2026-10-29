# Database download container
FROM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a as database

RUN apk add --no-cache gzip tar wget && rm -rf /var/cache/apk/*

ARG LICENSE_KEY

RUN wget -O "GeoLite2-City.tar.gz" "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$LICENSE_KEY&suffix=tar.gz"
RUN tar -xzvf GeoLite2-City*.tar.gz

# Rust compile container
FROM rust:1.99.1-bookworm@sha256:9181b56c2a21ab1d5e73cffe04fc762426d30aa7fac3c91141dd033f49a7fc8b as build

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