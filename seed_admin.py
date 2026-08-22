"""Seed the Baserow admin before the public port opens.

Upstream sets ``is_staff=not User.objects.exists()`` in
``baserow.core.user.handler.UserHandler.create_user``: whoever signs up first on
a fresh instance becomes the Baserow-wide administrator. ``Settings.
allow_new_signups`` defaults to ``True`` and there is no environment variable
that turns it off -- it is a database row that can only be changed from the
admin UI, i.e. after someone has already claimed the instance. So every stock
deploy hands its admin account to the first stranger who opens the URL.

This script closes that window. It runs before Caddy binds ``$PORT``: it creates
the deployer's admin account (idempotently), re-applies the password on every
boot so a redeploy is a working password reset, and turns public sign-up off.
"""

import os

from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password

from baserow.core.handler import CoreHandler
from baserow.core.user.handler import UserHandler

email = (os.environ.get("BASEROW_ADMIN_EMAIL") or "").strip().lower()
password = os.environ.get("BASEROW_ADMIN_PASSWORD") or ""
name = (os.environ.get("BASEROW_ADMIN_NAME") or "Admin").strip() or "Admin"

if not email or not password:
    raise SystemExit("SEED: BASEROW_ADMIN_EMAIL and BASEROW_ADMIN_PASSWORD are required")

User = get_user_model()
user = User.objects.filter(email__iexact=email).first()

if user is None:
    user = UserHandler().force_create_user(
        email=email, name=name, password=password, is_staff=True
    )
    print(f"SEED: created admin {user.email} (staff={user.is_staff})")
else:
    user.password = make_password(password)
    user.is_staff = True
    user.is_active = True
    user.save()
    print(f"SEED: re-applied password for existing admin {user.email}")

settings_row = CoreHandler().get_settings()
settings_row.allow_new_signups = False
settings_row.show_admin_signup_page = False
settings_row.save()
print("SEED: public sign-up disabled, admin signup page hidden")
