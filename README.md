# MOVA Technologies website

Static website for MOVA Technologies. HTML5, CSS3 and vanilla JavaScript. No framework, no build step, no dependencies.
Supabase is used for one thing only: storing contact-form messages.

## Structure

```
index.html  products.html  demo.html  services.html  about.html  contact.html  privacy.html  404.html
favicon.svg  favicon.ico  apple-touch-icon.png  android-chrome-*.png  site.webmanifest
robots.txt  .nojekyll  .gitignore
assets/
  css/   tokens.css  base.css  components.css  sections.css
  js/    boot.js  main.js  hero-demo.js  connect.js  explorer.js  sandbox.js  contact.js  config.js
  img/   icons.svg (icon sprite)  mova-*-reversed.svg (official logos)  og-image.png
supabase/migrations/001_contact_messages.sql
tools/gen_pages.py  tools/check.py
```

## Run locally

```
python3 -m http.server 8000      # then open http://localhost:8000
```

## Editing pages

The seven `.html` files are generated so the header, footer and `<head>` stay identical. Edit `tools/gen_pages.py`, then run `python3 tools/gen_pages.py` and commit the regenerated files.

## Live demo

`demo.html` is a working browser-only sandbox of the planned platform (inventory, sales, dashboard). Logic is in `assets/js/sandbox.js`. Data is stored in the visitor's browser (localStorage) and never sent anywhere. Seed figures are sample data and the page says so.

## Contact form (Supabase)

1. Create a Supabase project.
2. Run `supabase/migrations/001_contact_messages.sql` in the SQL editor. Visitors can insert only; nobody can read through the website.
3. Put the **project URL** and the **publishable (anon) key** in `assets/js/config.js`.
4. Never put a secret or service-role key anywhere in this repository.

Until step 3 is done, the form shows "Messaging is being connected". The form has validation, a honeypot field and a 30-second client-side limit. Server-side rate limiting is not included yet: add it (for example a CAPTCHA or an Edge Function) before the site receives real traffic.

## Deploy on GitHub Pages

Repository `mova-technologies` > Settings > Pages > Deploy from branch > `main` / root. All paths are relative, so it works under `/mova-technologies/` or a custom domain.

## Security

A strict Content-Security-Policy is set in each page (`script-src 'self'`, no inline scripts or styles). Add `frame-ancestors` and other headers at the host when a custom domain and host support it.

## Design notes

- Colours: Midnight Navy, Electric Blue, White, Slate Grey from the brand guidelines. **Silver** was added for this website per the brief; add it to the brand guidelines.
- Fonts: Sora and Inter load from Google Fonts. Self-host them before launch to remove the third-party request.
- Hero and demo figures are labelled sample data. Nothing on the site claims clients, partners, achievements or registration.

## To do after the domain exists

- Add absolute `og:image` and `canonical` tags, and a `sitemap.xml`.
- Review the Services copy: confirm what you want to offer publicly.
- Replace the privacy page with a legally reviewed version.
- Hosting: GitHub's terms say Pages is not for running a commercial SaaS. It is fine for this marketing site; review hosting before the paid platform launches.

## Quality check

`python3 tools/check.py` verifies links, anchors, assets and icon-sprite symbols; one h1 and a description per page; alt text; no inline scripts, styles or handlers (CSP); no emoji; and no secret keys in the source. Run it before every commit.

## Tested

Chromium at 375, 768 and 1366 px on all eight pages: no horizontal overflow, no console or CSP errors. Interactive demos, keyboard navigation, mobile menu and form flows (validation, success, error, honeypot, rate limit) were exercised. A screen-reader and real-device pass is still recommended.

Text contrast was audited in the browser across all pages and interactive states: no pair below WCAG AA. Each page loads about 75 to 90 KB of local files (HTML, CSS, JS, SVG), plus Google Fonts.
