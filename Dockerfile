# Database download container
FROM alpine:3.21@sha256:21dc6063fd678b478f57c0e13f47560d0ea4eeba26dfc947b2a4f81f686b9f45 as database

RUN apk add --no-cache gzip tar wget && rm -rf /var/cache/apk/*

ARG LICENSE_KEY

RUN wget -O "GeoLite2-City.tar.gz" "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-City&license_key=$LICENSE_KEY&suffix=tar.gz"
RUN tar -xzvf GeoLite2-City*.tar.gz

# Rust compile container
FROM rust:1.83@sha256:39a313498ed0d74ccc01efb98ec5957462ac5a43d0ef73a6878f745b45ebfd2c as build

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