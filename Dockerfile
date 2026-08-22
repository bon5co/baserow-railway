# Wrapper over Baserow's all-in-one image, pinned by digest (2.3.3).
# Adds: admin seeded and public sign-up disabled before the public port opens,
# Caddy bound to Railway's injected $PORT, and X-Forwarded-Proto trusted so the
# links Baserow generates are https.
FROM baserow/baserow:2.3.3@sha256:41adb3493379403946a493f30873f743bb65b19b5f387d630ec75f41e25d5b5b

COPY railway-entrypoint.sh /railway-entrypoint.sh
COPY seed_admin.py /baserow/railway_seed_admin.py
RUN chmod +x /railway-entrypoint.sh && chmod 0644 /baserow/railway_seed_admin.py

# Baked, non-deployer-facing settings. These are literals, and templateGenerate
# drops a literal default (the variable then publishes as required-and-blank),
# so they belong in the image rather than in the template's variable list.
ENV BASEROW_ADMIN_NAME=Admin \
    BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER=yes \
    BASEROW_AMOUNT_OF_WORKERS=1 \
    BASEROW_AMOUNT_OF_GUNICORN_WORKERS=2 \
    BASEROW_TRIGGER_SYNC_TEMPLATES_AFTER_MIGRATION=false \
    BASEROW_BACKEND_LOG_LEVEL=WARNING \
    BASEROW_BACKEND_DEBUG=false \
    NODE_OPTIONS=--max-old-space-size=512 \
    DISABLE_VOLUME_CHECK=yes

ENTRYPOINT ["/railway-entrypoint.sh"]
CMD []
