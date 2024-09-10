# Database download container
FROM alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b as database

RUN apk add --no-cache gzip tar wget && rm -rf /var/cache/apk/*

ARG LICENSE_KEY

RUN wget -O "GeoLite2-City.tar.gz" "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$LICENSE_KEY&suffix=tar.gz"
RUN tar -xzvf GeoLite2-City*.tar.gz

# Rust compile container
FROM rust:1.76@sha256:3e95fdb4838db1eb34be1acbe0150057962cdc349285951874c3a2454f7aea96 as build

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