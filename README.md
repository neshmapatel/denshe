# DeNshe

Jewellery brand storefront and admin. Rails monolith: customer site + ActiveAdmin.

## Stack

- Ruby 4.0.6
- Rails 8.1.3
- PostgreSQL
- Active Storage (local disk in development, Cloudflare R2 later)
- ActiveAdmin + Devise for Neshma and Devanshi

## First run

Use Ruby 4.0.6 (`rvm use ruby-4.0.6` if RVM is your version manager).

```bash
bin/setup --skip-server
bin/rails server
```

Then open:

- Storefront placeholder: http://localhost:3000
- Admin: http://localhost:3000/admin

### Admin logins (development)

Password for both accounts: `denshe-admin-123`

Override with `ADMIN_SEED_PASSWORD` before seeding if you want a different password.

| Name | Email | Role |
| --- | --- | --- |
| Neshma | neshma@denshe.in | super_admin |
| Devanshi | devanshi@denshe.in | admin |

Change these passwords after you first log in.

## What to check in Phase 1

1. Log in as Neshma.
2. Create a product with images, purchase price, selling price, and stock.
3. Publish it (status: Active).
4. Add or reduce stock from **Catalogue → Inventory**.
5. Log out, then log in as Devanshi and confirm you can do the same.

Purchase price is visible in admin only. It is never meant for the customer site.

## Phases

- **Phase 0–1 (this):** foundation, models, ActiveAdmin, inventory
- **Phase 2:** DeNshe storefront pages
- **Phase 3:** cart and checkout
- **Phase 4:** payment gateway
- **Phase 5:** order fulfilment wiring
- **Phase 6:** mystery box quiz
- **Phase 7:** polish and launch
