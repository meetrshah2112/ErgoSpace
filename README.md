<p align="center">
  <img src="docs/screenshots/logo.png" alt="ErgoSpace logo" width="130"/>
</p>

<h1 align="center">ErgoSpace</h1>
<p align="center"><b>Find your space. Elevate your work.</b><br/>A mobile marketplace to discover, book and pay for cafés, co-working spaces and hot desks.</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white"/>
  <img alt="Django" src="https://img.shields.io/badge/Django-092E20?logo=django&logoColor=white"/>
  <img alt="PostGIS" src="https://img.shields.io/badge/PostgreSQL-PostGIS-336791?logo=postgresql&logoColor=white"/>
  <img alt="Docker" src="https://img.shields.io/badge/Docker-2496ED?logo=docker&logoColor=white"/>
  <img alt="Razorpay" src="https://img.shields.io/badge/Razorpay-0C2451?logo=razorpay&logoColor=white"/>
</p>

<p align="center">
  <img src="docs/screenshots/00-welcome.jpg" width="220" alt="Welcome screen"/>
  <img src="docs/screenshots/customer-01-home.jpg" width="220" alt="Home"/>
  <img src="docs/screenshots/customer-13-ticket.jpg" width="220" alt="Booking ticket"/>
</p>

## Table of contents
- [What is ErgoSpace?](#what-is-ergospace)
- [Screenshots](#screenshots)
- [Tech stack](#tech-stack)
- [Architecture](#architecture)
- [Quick start](#quick-start)
- [Repository layout](#repository-layout)

## What is ErgoSpace?

ErgoSpace connects people who need a place to work with the places that offer one.

**Customers** can
- discover nearby workspaces (distance-based search powered by GeoDjango/PostGIS)
- browse photos, amenities, ratings, opening hours and location
- pick a specific seat type, choose hourly / daily / monthly pricing and see the price update live
- check availability, reserve and pay securely with Razorpay
- get a ticket-style booking confirmation, and review workspaces

**Providers** can
- create a workspace with photos, amenities (default list or their own) and opening hours
- set the map location from the phone's GPS or from the address
- add seat types with their own photos, capacity and hourly / daily / monthly rates
- manage their workspaces and track bookings and revenue from a dashboard

## Screenshots

### Customer experience

<table>
  <tr><td align="center" valign="top"><img src="docs/screenshots/customer-01-home.jpg" width="190" alt="Home"/><br/><sub><b>Home</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-02-home-card.jpg" width="190" alt="Workspace card"/><br/><sub><b>Workspace card</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-03-workspace.jpg" width="190" alt="Workspace page"/><br/><sub><b>Workspace page</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-04-seats.jpg" width="190" alt="Choose a seat"/><br/><sub><b>Choose a seat</b></sub></td></tr>
  <tr><td align="center" valign="top"><img src="docs/screenshots/customer-05-reviews.jpg" width="190" alt="Reviews"/><br/><sub><b>Reviews</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-06-location.jpg" width="190" alt="Location"/><br/><sub><b>Location</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-07-about.jpg" width="190" alt="About us"/><br/><sub><b>About us</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-08-host.jpg" width="190" alt="Host contact"/><br/><sub><b>Host contact</b></sub></td></tr>
  <tr><td align="center" valign="top"><img src="docs/screenshots/customer-09-search-filters.jpg" width="190" alt="Search filters"/><br/><sub><b>Search filters</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-10-book-seat.jpg" width="190" alt="Book a seat"/><br/><sub><b>Book a seat</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-11-booking-summary.jpg" width="190" alt="Booking summary"/><br/><sub><b>Booking summary</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-12-payment.jpg" width="190" alt="Razorpay checkout"/><br/><sub><b>Razorpay checkout</b></sub></td></tr>
  <tr><td align="center" valign="top"><img src="docs/screenshots/customer-13-ticket.jpg" width="190" alt="Booking ticket"/><br/><sub><b>Booking ticket</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/customer-14-my-bookings.jpg" width="190" alt="My bookings"/><br/><sub><b>My bookings</b></sub></td></tr>
</table>

### Provider experience

<table>
  <tr><td align="center" valign="top"><img src="docs/screenshots/provider-01-dashboard.jpg" width="190" alt="Dashboard"/><br/><sub><b>Dashboard</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/provider-02-my-spaces.jpg" width="190" alt="My spaces"/><br/><sub><b>My spaces</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/provider-03-basics.jpg" width="190" alt="Basics"/><br/><sub><b>Basics</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/provider-04-location.jpg" width="190" alt="Location"/><br/><sub><b>Location</b></sub></td></tr>
  <tr><td align="center" valign="top"><img src="docs/screenshots/provider-05-amenities.jpg" width="190" alt="Amenities"/><br/><sub><b>Amenities</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/provider-06-seats.jpg" width="190" alt="Seats & pricing"/><br/><sub><b>Seats & pricing</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/provider-07-photos.jpg" width="190" alt="Photos"/><br/><sub><b>Photos</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/provider-08-review.jpg" width="190" alt="Review & publish"/><br/><sub><b>Review & publish</b></sub></td></tr>
  <tr><td align="center" valign="top"><img src="docs/screenshots/provider-09-bookings.jpg" width="190" alt="Bookings"/><br/><sub><b>Bookings</b></sub></td></tr>
</table>

### Profile and themes

<table>
  <tr><td align="center" valign="top"><img src="docs/screenshots/settings-01-profile.jpg" width="190" alt="Profile"/><br/><sub><b>Profile</b></sub></td><td align="center" valign="top"><img src="docs/screenshots/settings-02-appearance.jpg" width="190" alt="Appearance"/><br/><sub><b>Appearance</b></sub></td></tr>
</table>

## Tech stack

| Layer | Technology |
| --- | --- |
| Mobile app | Flutter, Riverpod (state), go_router (navigation), Dio (HTTP) |
| Backend | Django, Django REST Framework, GeoDjango |
| Database | PostgreSQL + PostGIS |
| Payments | Razorpay (test and live modes) |
| Device features | geolocator, geocoding, url_launcher, image_picker |
| DevOps | Docker, Docker Compose |

## Architecture

```mermaid
flowchart LR
    A[Flutter app<br/>Riverpod + go_router + Dio] -- REST / JSON --> B[Django REST API]
    B --> C[(PostgreSQL + PostGIS)]
    B --> D[Media storage<br/>workspace and seat images]
    A -- Checkout --> E[Razorpay]
    B -- Verify payment signature --> E
```

Backend apps

| App | Responsibility |
| --- | --- |
| `users` | Registration, login, token authentication, profiles |
| `workspaces` | Workspaces, amenities, seat types, photos, reviews, nearby search |
| `booking` | Availability, reservations, Razorpay orders and payment verification |

Frontend structure: `lib/core` (theme, widgets, networking), `lib/features` (customer and provider screens), `lib/shared` (models and repositories).

## Quick start

Full step-by-step instructions, including Razorpay setup, are in **[SETUP.md](SETUP.md)**. In short:

```bash
# 1. Backend (Docker)
cp backend/.env.example backend/.env        # fill in the values (see SETUP.md)
docker compose --env-file backend/.env up --build

# 2. Frontend (Flutter)
cd frontend
flutter create --org com.ergospace --platforms android .
flutter pub get
flutter run --dart-define=RAZORPAY_KEY=<your_test_key_id>
```

## Repository layout

```
backend/    Django REST API
frontend/   Flutter app
docs/       Screenshots
SETUP.md    Detailed setup guide
```

## Security

Secrets live in `backend/.env`, which is git-ignored. Never commit `.env`, `*.pem` files or your Razorpay secret key.

## Author

Built by Meet Shah. Contributions and feedback are welcome.
