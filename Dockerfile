# syntax=docker/dockerfile:1

# Flutter 3.44.6 publishes an AMD64 Linux SDK. The final Nginx image still
# uses the deployment host's native architecture.
FROM --platform=linux/amd64 debian:bookworm-slim AS builder

ARG FLUTTER_VERSION=3.44.6
ARG FLUTTER_SHA256=a6320fd72e9a2690c08e2a6a70874a30cb120dee7c78f49d2c628bd7c9e20525
ARG TRANSMUTE_REPOSITORY_MODE=api
ARG TRANSMUTE_API_BASE_URL

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PATH=/opt/flutter/bin:${PATH}

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl --fail --location --retry 3 \
      --output /tmp/flutter.tar.xz \
      https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum --check --strict \
    && tar --extract --xz --file /tmp/flutter.tar.xz --directory /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . ./

RUN test -n "${TRANSMUTE_API_BASE_URL}" \
    && flutter build web --release \
      --dart-define=TRANSMUTE_REPOSITORY_MODE=${TRANSMUTE_REPOSITORY_MODE} \
      --dart-define=TRANSMUTE_API_BASE_URL=${TRANSMUTE_API_BASE_URL}

FROM nginx:1.27-alpine AS runtime

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
