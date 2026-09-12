# BloodBridgeApp



# 🩸 BloodBridge— Blood Donor Matching Platform

> Connecting people who need blood with eligible nearby donors through a simple request, matching, notification, response, chat, and confirmation flow.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State%20Management-Riverpod-53C1DE)](https://riverpod.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-informational)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

When a patient needs blood, finding a suitable, nearby, willing donor quickly is often slow and fragmented. **BloodBridge** connects **Requesters** and **Donors** directly, while **Hospitals** and **Partner Institutions** (blood banks, welfare orgs) support trust and fulfillment.

> This is a coordination tool — **not** a medical eligibility authority. Final donor suitability remains the responsibility of qualified hospitals and medical staff.

## Key Features

- 📝 Quick request creation, even without a registered hospital
- 🔔 Push notifications to eligible, nearby, available donors
- ✅ Accept/Decline response flow with lightweight coordination
- 💬 In-app chat — unlocked only after donor willingness (non-binding)
- 🩺 Donation confirmation with partial/full unit tracking
- 🏥 Hospital verification for requests tied to their location
- 🤝 Partner institution support (create requests, fulfill from stock)
- 🛡️ Admin console — user/request review, trust labels, safety flags, metrics

## User Roles

| Role | Description |
|---|---|
| **Requester** | Creates and tracks a blood request |
| **Donor** | Sets availability, responds to compatible requests |
| **Hospital** | Verifies requests tied to its own location (no fulfillment role) |
| **Partner Institution** | Creates requests, fulfills others from declared stock |
| **Admin** | Manages trust/safety, reviews flags, views metrics |

## Trust Labels

- 🔵 **Self-verified** — created without institutional approval
- 🏥 **Institution-backed** — verified by the requester's own hospital
- 🤝 **Partner fulfillment** — a partner institution has claimed available stock

## Tech Stack

**Flutter** · **Clean Architecture** (domain/data/presentation) · **Riverpod** · **go_router** · Phone/OTP auth · Push notifications

## Project Structure

```
lib/
├── core/           # Shared constants, theming, utilities
├── features/       # auth, donor_profile, requests, matching,
│                   # notifications, response, chat, hospital,
│                   # partner_institution, admin, audit
└── routing/        # go_router config & role-based guards
```

Each feature follows: `data/` (models, repositories) → `domain/` (entities, use cases) → `presentation/` (Riverpod providers, screens).

## Request Lifecycle

```
Draft → (Pending Hospital Verification) → Active → Matched → Fulfilled → Closed
```

Requests track **Units Required / Fulfilled / Remaining** — partial fulfillment keeps a request active until fully met, cancelled, or expired.

## Getting Started

```bash
git clone https://github.com/<your-username>/hemalink.git
cd hemalink
flutter pub get
flutter run
```

Requires: Flutter SDK (stable), a push notification provider config (e.g. Firebase), and a `.env` with your `API_BASE_URL` and relevant API keys.

## Roadmap

- [ ] Phase 1 — Wireframes, data model, OTP stub, request/profile forms
- [ ] Phase 2 — Availability, location, compatibility & distance matching
- [ ] Phase 3 — Push notifications, accept/decline, request lifecycle
- [ ] Phase 4 — Chat, donation confirmation, partner support, trust labels
- [ ] Phase 5 — Admin console, metrics, edge-case testing, deployment

## Out of Scope (MVP)

IVR/SMS/WhatsApp channels · clinical eligibility screening · full inventory management · automated donor scoring · payments/rewards · live map navigation · ML-based matching

## Safety

BloodBridge is a logistics/coordination tool only. Chat is non-binding and not proof of donation. Sensitive diagnoses must never appear in public request text. Test data must be anonymized before any public sharing.

## Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit and push your changes
4. Open a Pull Request

## License

MIT — see [LICENSE](LICENSE) for details.

