# Wrapper over Baserow's all-in-one image, pinned by digest (2.3.3).
# Adds: admin seeded and public sign-up disabled before the public port opens,
# Caddy bound to Railway's injected $PORT, and X-Forwarded-Proto trusted so the
# links Baserow generates are https.
FROM baserow/baserow:2.3.3@sha256:41adb3493379403946a493f30873f743bb65b19b5f387d630ec75f41e25d5b5b

COPY railway-entrypoint.sh /railway-entrypoint.sh
COPY seed_admin.py /baserow/railway_seed_admin.py
RUN chmod +x /railway-entrypoint.sh && chmod 0644 /baserow/railway_seed_admin.py

ENTRYPOINT ["/railway-entrypoint.sh"]
CMD []
