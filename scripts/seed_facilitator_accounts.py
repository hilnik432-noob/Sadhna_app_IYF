"""
ONE-TIME setup script — NOT part of the app, run manually once.

Does two things:
  1. Flags the two existing real Google-Sign-In accounts (already students
     in `users`) as super_admin, by matching their email to the facilitator
     names given at setup time.
  2. For every OTHER facilitator in lib/core/constants/facilitators.dart who
     doesn't already have an account, creates a Firebase Auth email/password
     account (a hidden login identifier, NOT a real inbox — see
     Facilitator.loginEmail in the Dart constants) plus a matching Firestore
     `users/{uid}` doc with accessLevel='facilitator', and a freshly
     generated random password.

Every generated password is written ONCE to a local, git-ignored file for
you to distribute privately — never stored anywhere else, never printed to
this terminal, never committed. Re-running this script is safe: existing
accounts (matched by loginEmail) are left untouched rather than recreated.

Usage:
    python scripts/seed_facilitator_accounts.py
"""
from __future__ import annotations

import re
import secrets
import string
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import auth, credentials, firestore

# ── Config ───────────────────────────────────────────────────────────────
CRED_PATH = r"d:\IYF 1\IYF\sadhna\sadhana-app-iyf-firebase-adminsdk-fbsvc-3200344041.json"
LOGIN_DOMAIN = "facilitators.sadhana-app-iyf.internal"  # must match Dart's _facilitatorLoginDomain
OUTPUT_PATH = Path(r"d:\IYF 1\IYF\sadhna\FACILITATOR_LOGIN_CREDENTIALS_CONFIDENTIAL.txt")

# Kept here as plain data (mirrors lib/core/constants/facilitators.dart) —
# only dikshitName matters for slugging; materialName is just for the output file.
FACILITATORS = [
    ("HG Harisa Pran Prabhuji", "Harisa Pran Prabhuji"),
    ("HG Sachi Priya Prabhu Ji", "Sachin Jangid"),
    ("HG Ashok Govind Prabhu Ji", "Ashok Prabhu Ji"),
    ("Keshav Prabhu Ji", "Keshav Prabhu Ji"),
    ("HG Digvijay Gourang Prabhuji", "Digvijay Gourang Prabhuji"),
    ("HG Dev Krishna Das", "Dev Krishna Teli"),
    ("HG Tribhang Kanai Prabhu Ji", "Tribhang Kanai Prabhu Ji"),
    ("HG Kaushal Pati Prabhu Ji", "Kaushal Pal"),
    ("HG Amal Gaur Prabhu Ji", "Aman Sharma"),
    ("HG Madhur Murli Prabhu Ji", "Madhur Murli Prabhu Ji"),
    ("HG Mohan Murari Prabhuji", "Mohan Murari Prabhuji"),
    ("Gopal Prabhu Ji", "Gopal Prabhu Ji"),
    ("HG Ganshyam Dev Prabhu Ji", "Ganshyam Dev Prabhu Ji"),
    ("HG Avinashi Govind Prabhuji", "Avinash Daroga Prabhu Ji"),
    ("HG Hitkar Vaman Prabhu Ji", "Hitarth Vyas"),
    ("Nitai Nimai Prabhu Ji", "Nikhil Kumawat"),
    ("HG Maya Tita Hari Prabhu Ji", "Mayank Mewara"),
    ("HG Amrita Anand Prabhu Ji", "Amrita Anand Prabhu Ji"),
    ("HG Akshar Hari Prabhu Ji", "Ankit Kumar Singh"),
    ("HG Vishuddh Parth Prabhuji", "Vishal Sharma Prabhu Ji"),
    ("HG Bhav Hari Prabhu Ji", "Bhavya Soni"),
    ("HG Naveen Narad Prabhuji", "Naveen Narad Prabhuji"),
    ("HG Tusht Madan Mohan Prabhuji", "Tushar Soni Prabhu Ji"),
    ("HG Devash Baldev Prabhu Ji", "Devansh Motwani"),
    ("HG Prajwal Nitai Prabhuji", "Prajwal Avasthi Prabhu Ji"),
    ("HG Veer Bhadra Prabhu Ji", "Virendra Prabhu Ji"),
    ("HG Satya Raj Keshav Prabhu Ji", "Shubham Pareek"),
    ("HG Praneshwar Shyam Prabhuji", "Pronit Prabhu Ji"),
    ("HG Manigreev Prabhu Ji", "Manigreev Prabhu Ji"),
    ("HG Krishnakant Prabhu Ji", "Krish Sharma"),
    ("HG Akshay Hari Prabhu Ji", "Aakash Prabhu Ji"),
    ("HG Arjun Prabhu Ji", "Ajay Sharma"),
    ("HG Vipin Shyam Prabhu Ji", "Vipin Sharma Prabhu Ji"),
    ("HG Vikram Prabhu Ji", "Vikas Singh"),
    ("HG Vimal Arjun Prabhu Ji", "Vimal Arjun Prabhu Ji"),
]

# The two facilitators who already have real Google-Sign-In student
# accounts and should become super_admin on THAT account, not a new one.
SUPER_ADMIN_DIKSHIT_NAMES = {"Nitai Nimai Prabhu Ji", "HG Vishuddh Parth Prabhuji"}


def slugify(dikshit_name: str) -> str:
    """MUST match Dart's slugifyFacilitatorName() in facilitators.dart exactly."""
    lowered = dikshit_name.lower()
    cleaned = re.sub(r"[^a-z0-9]+", "_", lowered)
    return cleaned.strip("_")


def login_email(dikshit_name: str) -> str:
    return f"{slugify(dikshit_name)}@{LOGIN_DOMAIN}"


def generate_password(length: int = 16) -> str:
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def promote_existing_super_admins(db) -> list[str]:
    promoted = []
    users = db.collection("users").stream()
    user_docs = {d.id: d.to_dict() for d in users}

    for uid, data in user_docs.items():
        # Match by the sadhanaCategory-era 'name' field the student typed in
        # profile setup against the facilitator's own display name isn't
        # reliable (students type free text) — instead we match by which
        # dikshit name the OPERATOR (you) told me maps to which real email,
        # captured directly below rather than guessed from Firestore data.
        pass

    # Known mapping confirmed directly with the app owner (not guessed):
    #   Nitai Nimai Prabhu Ji      -> nikhilkumawat264@gmail.com
    #   HG Vishuddh Parth Prabhuji -> gnvs0709@gmail.com
    email_to_dikshit = {
        "nikhilkumawat264@gmail.com": "Nitai Nimai Prabhu Ji",
        "gnvs0709@gmail.com": "HG Vishuddh Parth Prabhuji",
    }

    for uid, data in user_docs.items():
        email = data.get("email")
        dikshit_name = email_to_dikshit.get(email)
        if dikshit_name is None:
            continue
        db.collection("users").document(uid).update({
            "accessLevel": "super_admin",
            "facilitatorDikshitName": dikshit_name,
        })
        promoted.append(f"{dikshit_name} ({email}) -> super_admin on existing account {uid}")

    return promoted


def create_facilitator_accounts(db) -> list[tuple[str, str, str]]:
    """Returns list of (dikshit_name, login_email, password) for newly created accounts only."""
    created = []
    for dikshit_name, material_name in FACILITATORS:
        if dikshit_name in SUPER_ADMIN_DIKSHIT_NAMES:
            continue  # handled by promote_existing_super_admins instead

        email = login_email(dikshit_name)
        try:
            existing = auth.get_user_by_email(email)
            continue  # already created in a previous run — leave untouched
        except auth.UserNotFoundError:
            pass

        password = generate_password()
        user_record = auth.create_user(email=email, password=password, display_name=dikshit_name)
        db.collection("users").document(user_record.uid).set({
            "uid": user_record.uid,
            "name": material_name,
            "email": email,
            "accessLevel": "facilitator",
            "facilitatorDikshitName": dikshit_name,
        })
        created.append((dikshit_name, email, password))
    return created


def main() -> int:
    cred = credentials.Certificate(CRED_PATH)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    promoted = promote_existing_super_admins(db)
    created = create_facilitator_accounts(db)

    if promoted:
        print("Promoted to super_admin:")
        for line in promoted:
            print(" -", line)
    else:
        print("No existing accounts matched for super_admin promotion (already done, or emails changed).")

    if created:
        with OUTPUT_PATH.open("w", encoding="utf-8") as f:
            f.write("CONFIDENTIAL — facilitator login credentials. Distribute privately.\n")
            f.write("Do NOT commit this file or paste it anywhere shared.\n")
            f.write("Login screen: dropdown shows the facilitator's own name; enter the password below.\n\n")
            for dikshit_name, email, password in created:
                f.write(f"{dikshit_name}\n  login email (hidden): {email}\n  password: {password}\n\n")
        print(f"\nCreated {len(created)} new facilitator accounts.")
        print(f"Credentials written to: {OUTPUT_PATH}")
        print("This file is git-ignored, but move/delete it once distributed.")
    else:
        print("\nNo new facilitator accounts created (all already exist).")

    return 0


if __name__ == "__main__":
    sys.exit(main())
