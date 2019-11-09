# Database download container
FROM alpine:3.9 as database

RUN apk add --no-cache gzip tar wget && rm -rf /var/cache/apk/*

RUN wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
RUN tar -xzvf GeoLite2-City.tar.gz
 
# Rust compile container
FROM rust:1.39 as build

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