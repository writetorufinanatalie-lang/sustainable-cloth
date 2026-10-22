# Loomtrace — Sustainable Clothes

Loomtrace is a small digital product passport for a garment. A shopper can scan a QR code to see product materials, supply-chain steps and care guidance. The app uses Supabase for shared data and authentication. The sample garment is clearly marked **SAMPLE DATA**; sample review labels are demonstration content, not real-world verification.

## Who can do what

| Person | What they can do |
| --- | --- |
| Public | Read published passports and public evidence; cannot change data. |
| Brand | Sign in, edit the single sample product and its supply-chain steps, upload public evidence, and publish. Brand edits to a reviewed step return it to Submitted. |
| Reviewer | Sign in to the reviewer queue, inspect evidence, and mark a step Reviewed or Needs evidence. The database records the reviewer account and time. |

## Beginner setup (follow in order)

1. **Get the project files.** Keep the folders together. You need a modern browser and Python 3 for local preview. The public site is plain HTML, CSS and JavaScript modules; there is no build step.
2. **Create a Supabase project.** Go to [supabase.com](https://supabase.com), create a free project, and save the database password somewhere private (you will not put it in this repository).
3. **Copy the Supabase connection values.** In the Supabase project dashboard open **Project Settings → API** (or **API Keys** in the current dashboard). Copy the Project URL and the public `anon` / publishable key. Never copy the `service_role` or secret key into this website.
4. **Create the database.** In Supabase open **SQL Editor → New query**. Open `supabase/schema.sql`, copy all of it into the editor, and press **Run**. Then repeat with all of `supabase/seed.sql`. The schema enables row-level security and configures public-read storage buckets.
5. **Create the two sign-in accounts.** In Supabase open **Authentication → Users → Add user**. Create one brand account and one reviewer account with email and password. Use a real inbox if you plan to use password recovery. Do not commit passwords.
6. **Assign the roles.** In Authentication → Users, copy each user's UUID. In SQL Editor run this statement after replacing the two values:

   ```sql
   insert into public.user_roles(user_id, role)
   values ('BRAND_USER_UUID','brand'), ('REVIEWER_USER_UUID','reviewer');
   ```

   The same role statement is also commented at the bottom of `supabase/schema.sql`.
7. **Set the public browser keys.** In PowerShell run `Copy-Item assets/js/config.example.js assets/js/config.js` (macOS/Linux: `cp assets/js/config.example.js assets/js/config.js`). Open `config.js` and replace the two placeholder values with the Project URL and public anon key from step 3. The anon key is public by design; database security comes from row-level security. **Never use or commit the `service_role` key.** `config.js` must be included in the GitHub Pages deployment for the site to connect. It contains only the public URL and anon key, which are intentionally public; never place a service_role or secret key there. The placeholder file in this starter is not usable until replaced.
8. **Run locally.** Open a terminal in this folder and run `python3 -m http.server 8000`. On Windows run `py -m http.server 8000`. In your browser open `http://localhost:8000`. If no valid config is present, the public passport falls back to visibly labeled sample content.
9. **Explore and edit.** Open `http://localhost:8000/p/field-notes-tee-04` for the passport. Open `http://localhost:8000/admin.html` to sign in as the brand and edit the seeded product. Open `http://localhost:8000/admin/review.html` as the reviewer. Evidence and product image files uploaded to Supabase are publicly visible; do not upload private documents.
10. **Deploy after your owner merges the branch.** In GitHub open the repository **Settings → Pages → Build and deployment → Deploy from a branch**, choose `main` and `/ (root)`, and save. Copy your exact GitHub Pages base URL. `index.html` and the QR target use relative paths so the project can live under a repository subpath. Replace `<user>` and `<repo>` in the following links:

    - Passport: `https://<user>.github.io/<repo>/p/field-notes-tee-04`
    - Passport data fallback: `https://<user>.github.io/<repo>/passport.html?slug=field-notes-tee-04`
    - Admin: `https://<user>.github.io/<repo>/admin.html`

11. **Generate a print QR code.** Install the small script dependencies once with `npm install`, then run `npm run qr -- https://<user>.github.io/<repo>/p/field-notes-tee-04`. The output is `qr/field-notes-tee-04.png` (1200 px) and `.svg`, with high error correction and a quiet zone. Print at about 2 cm × 2 cm or larger and scan the physical print with a phone before attaching it to a product. The QR encodes the URL you provide; rerun it with your actual URL after deployment.
12. **Run the public-access smoke check (optional).** With keys configured and the seed loaded, run `npm install` if needed, then `npm run smoke`. It checks anonymous reading of the published sample and anonymous write denial. It also checks that anonymous queries return no unpublished products.

## Data fields in everyday language

| Field | Meaning | Example |
| --- | --- | --- |
| Slug | Stable short name in the passport URL | `field-notes-tee-04` |
| SKU | Brand's inventory reference | `FN-TEE-04` |
| Materials | Material names and percentage claims | `Organic cotton — 100%` |
| Certifications | Brand-listed certification claims | `GOTS (sample claim)` |
| Origin / locations | Country and manufacturing places provided by the brand | Portugal; Porto |
| Step status | Submitted, Reviewed, or Needs evidence | Submitted |
| Evidence | Public URL or uploaded PDF/image supporting a step | Certificate or audit file |
| Care / repair / resale / recycling | Instructions for extending garment life | Wash at 30°C |

## Reviewing claims responsibly

A status of **Submitted** means the brand provided the information. Only mark a claim **Reviewed** after a person has opened and checked the evidence against that claim. **Needs evidence** must include a note stating what is missing. The database trigger requires evidence before review and sets the reviewer account name and timestamp. The seeded sample entries and reviewer details are fictional sample values; do not treat them as independently verified claims.

## Test checklist

- [ ] Open `/p/field-notes-tee-04` on desktop and a 360 px-wide phone.
- [ ] See the SAMPLE DATA label until you replace the sample with actual reviewed product information.
- [ ] Check that submitted, reviewed, and needs-evidence steps have distinct wording.
- [ ] Sign in as brand, edit a reviewed step, and confirm it becomes Submitted on the public passport.
- [ ] Sign in as reviewer, verify the evidence, then mark a step reviewed; check the public name/date.
- [ ] Try opening an unpublished product while signed out; it should not appear.
- [ ] Try anonymous product writes with `npm run smoke`; they should be rejected.
- [ ] Upload a non-private evidence file and open its public link from the passport.
- [ ] Generate the QR using the deployed subpath URL and scan the printed code with a phone.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| Blank page | Serve over HTTP with the Python command above; check browser developer tools for a JavaScript or network error. |
| “Permission denied” | Confirm schema was run, the correct user UUID was assigned the correct role, and the account is signed in. |
| Login loops | Confirm the account exists in Supabase Auth, config URL/key match the same project, and the role row exists. |
| Images not loading | Check the image is PNG/JPG/WEBP, under 5 MB, and the public product-images bucket is enabled by schema.sql. |
| QR opens 404 | Confirm GitHub Pages is deployed, the encoded URL includes the repository subpath, and the stub path is exactly `/p/field-notes-tee-04`. |
| Subpath links fail | Keep the repository files at the Pages root and use the included relative page links; regenerate the QR with the complete Pages URL. |
| Passport shows sample fallback | Check the URL/key in config.js, that seed.sql ran in the same Supabase project, and that browser requests are not blocked. |

## Known limitations and next steps

This MVP has one brand and a shared brand account model, no audit-log history, and public-read evidence and image buckets. Public file links are suitable only for material intended for anyone to view. Reviewer identity is attached to the Auth account email. A later version could add separate brand ownership, private evidence access, a durable audit log, account recovery guidance, and multiple brands.


