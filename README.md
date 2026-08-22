# baserow-railway

Wrapper over [Baserow](https://baserow.io)'s all-in-one image for Railway, pinned by digest to
2.3.3.

Upstream sets `is_staff=not User.objects.exists()` when creating a user, and `Settings.
allow_new_signups` defaults to `True` with no environment variable to change it — it is a database
row editable only from the admin UI. A stock deploy therefore hands its Baserow-wide administrator
account to the first stranger who opens the public URL.

This image seeds the deployer's admin account and turns public sign-up off **before** Caddy binds
`$PORT`, so the public URL never serves an unclaimed instance. It also:

- refuses to boot without `BASEROW_ADMIN_EMAIL` / `BASEROW_ADMIN_PASSWORD`, rather than opening an
  unowned instance;
- re-applies the admin password on every boot, so a redeploy is a working password reset;
- binds Caddy to Railway's injected `$PORT` (upstream defaults to `:80`);
- sets `BASEROW_ENABLE_SECURE_PROXY_SSL_HEADER` so the absolute URLs Baserow generates behind
  Railway's TLS-terminating edge come out as `https://`.

Baserow is licensed MIT / Baserow Premium License; see upstream.
