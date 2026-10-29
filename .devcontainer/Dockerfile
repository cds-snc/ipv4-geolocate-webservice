FROM mcr.microsoft.com/devcontainers/rust:1-1-bookworm@sha256:fc57fb865035c5395e85246c8842b071ced6e7cde727b3c98abbcc794eaf4759

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates libbrotli1 && \
    dpkg --compare-versions "$(dpkg-query -W -f='${Version}' libbrotli1)" ge 1.0.9-2+deb12u1 && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i \
      -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' \
      -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' \
      /etc/ca-certificates.conf && \
    update-ca-certificates --fresh