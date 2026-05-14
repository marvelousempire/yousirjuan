# Biometric Authentication

**Tagline:** Walk up. Be recognized. Step in. No passwords, ever.

---

## What it is

You-Sir Juan™ uses native iOS biometrics to identify family members the moment they approach the kiosk — no phone, no tap, no password. The system knows who you are before you touch anything.

---

## Why it matters

Every password is a friction point. In a family home, friction means people don't use the system. You-Sir Juan™ removes it entirely. The kiosk should feel like walking into a room that knows you — not like logging into an account.

The entire authentication stack runs on-device. Credentials are never transmitted, never stored off-hardware, never exposed to a network. This is not a design choice driven by convenience alone — it is a privacy guarantee.

---

## How it works

**Step 1 — Face recognition**
The kiosk camera identifies the family member as they approach. The system resolves their face to a user ID using Vision framework on-device. No biometric data leaves the iPad.

**Step 2 — Touch ID confirmation (silent 2FA)**
A single fingerprint touch confirms the session. No typing. No PIN. The authentication completes in under a second.

**Step 3 — World loads**
The interface immediately repaints to that member's personal paradigm — their colors, their layout, their Associate Agent's greeting.

---

## Technical foundation

- **Face enrollment:** AVCaptureSession + VNDetectFaceRectanglesRequest → SHA-256 face token computed on-device
- **Session auth:** HMAC-signed token issued by the backend, stored only in session memory
- **Kiosk lock:** iOS Guided Access locks the iPad in kiosk mode when unauthenticated; disables on sign-out

---

## Who it's for

Any household where frictionless access matters — elderly family members who struggle with passwords, children who need a simpler experience, executives who don't want to type credentials in front of staff.

---

## Privacy note

Biometric data never leaves the device. The backend receives only an opaque face ID token (a hash) — never a face image, never a face embedding, never raw biometric data. The token cannot be reversed to reconstruct the original.
