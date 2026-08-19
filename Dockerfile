# The Flutter release bundle is built and versioned with the source. Keeping
# this runtime native avoids emulating Flutter's AMD64-only Linux SDK on the
# ARM64 Coolify host.
FROM nginx:1.27-alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY release/web /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1
