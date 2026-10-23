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

## Product photographs (WebP)

Every photograph uploaded for a product or curated gift is converted to WebP
automatically (long edge capped at 2400px, quality 85, colours kept in sRGB).
If a WebP would not be smaller, or the file is not a readable image, the original
is stored untouched. The shop also serves all of its resized images as WebP.

Photographs uploaded before this existed can be compressed on the server, with
no re-upload (run each on the production server, e.g. `heroku run` or `kamal app exec`):

```bash
bin/rails images:compress                 # preview: shows the saving, changes nothing
LIMIT=10 APPLY=1 bin/rails images:compress  # try a handful first
APPLY=1 bin/rails images:compress         # compress everything
bin/rails images:warm_variants            # pre-build the shop's image sizes
APPLY=1 bin/rails images:purge_originals  # once the shop looks right, delete the old files
```

Each photograph keeps its place in the gallery and its primary-photo setting.
Originals are kept until `images:purge_originals`, so the change can be checked first.

## Phases

- **Phase 0–1 (this):** foundation, models, ActiveAdmin, inventory
- **Phase 2:** DeNshe storefront pages
- **Phase 3:** cart and checkout
- **Phase 4:** payment gateway
- **Phase 5:** order fulfilment wiring
- **Phase 6:** mystery box quiz
- **Phase 7:** polish and launch
