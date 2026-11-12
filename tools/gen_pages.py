#!/usr/bin/env python3
"""Generates the static HTML pages from templates, so header/footer/head stay identical everywhere.
Run from the repository root:  python3 tools/gen_pages.py
The generated .html files are committed; the site itself needs no build step."""
import os, html

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSP = ("default-src 'self'; script-src 'self'; style-src 'self' https://fonts.googleapis.com; "
       "font-src https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self' https://*.supabase.co; "
       "base-uri 'self'; form-action 'self'; object-src 'none'")
NAV = [('index.html', 'Home'), ('products.html', 'Products'), ('services.html', 'Services'), ('about.html', 'About')]

def ico(name, cls='icon'):
    return f'<svg class="{cls}" aria-hidden="true" focusable="false"><use href="assets/img/icons.svg#i-{name}"/></svg>'

def head(title, desc, scripts_head=''):
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="{CSP}">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0B1220">
<title>{html.escape(title)}</title>
<meta name="description" content="{html.escape(desc)}">
<meta property="og:type" content="website">
<meta property="og:title" content="{html.escape(title)}">
<meta property="og:description" content="{html.escape(desc)}">
<link rel="icon" href="favicon.svg" type="image/svg+xml">
<link rel="icon" href="favicon.ico" sizes="48x48">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="manifest" href="site.webmanifest">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Sora:wght@600;700&display=swap">
<link rel="stylesheet" href="assets/css/tokens.css">
<link rel="stylesheet" href="assets/css/base.css">
<link rel="stylesheet" href="assets/css/components.css">
<link rel="stylesheet" href="assets/css/sections.css">
<script src="assets/js/boot.js"></script>
{scripts_head}</head>
<body>
<a class="skip-link" href="#main">Skip to content</a>
'''

def header(current):
    items = ''.join(f'<li><a href="{h}"{" aria-current=\"page\"" if h == current else ""}>{t}</a></li>' for h, t in NAV)
    cta_cur = ' aria-current="page"' if current == 'contact.html' else ''
    return f'''<header class="site-header">
<div class="container site-header__inner">
<a class="brand" href="index.html" aria-label="MOVA Technologies, home"><img src="assets/img/mova-secondary-reversed.svg" width="111" height="34" alt="MOVA"></a>
<button class="nav-toggle" type="button" aria-expanded="false" aria-controls="primary-nav" aria-label="Open menu">{ico('menu', 'icon icon-open')}{ico('close', 'icon icon-close')}</button>
<nav id="primary-nav" class="nav" aria-label="Primary">
<ul>{items}</ul>
<a class="btn btn--primary" href="contact.html"{cta_cur}>Get in touch {ico('arrow')}</a>
</nav>
</div>
</header>
'''

FOOTER = f'''<footer class="site-footer">
<div class="container">
<div class="footer-grid">
<div>
<img src="assets/img/mova-primary-reversed.svg" width="211" height="64" alt="MOVA Technologies">
<p>Technology That Moves Business Forward.</p>
</div>
<nav aria-label="Company"><h2>Company</h2><ul><li><a href="about.html">About</a></li><li><a href="services.html">Services</a></li><li><a href="contact.html">Contact</a></li></ul></nav>
<nav aria-label="Product"><h2>Product</h2><ul><li><a href="products.html">MOVA Business Platform</a></li><li><a href="products.html#modules">Modules</a></li><li><a href="products.html#roadmap">Roadmap</a></li></ul></nav>
</div>
<div class="footer-bottom"><span>&copy; <span data-year>2026</span> MOVA Technologies</span><a href="privacy.html">Privacy</a></div>
</div>
</footer>
'''

def page(fname, title, desc, body, scripts, current=None):
    js = ''.join(f'<script type="module" src="assets/js/{s}"></script>\n' for s in scripts)
    cfg = '<script src="assets/js/config.js"></script>\n' if 'contact.js' in scripts else ''
    out = head(title, desc) + header(current if current is not None else fname) + '<main id="main">\n' + body + '</main>\n' + FOOTER + cfg + '<script type="module" src="assets/js/main.js"></script>\n' + js + '</body>\n</html>\n'
    with open(os.path.join(ROOT, fname), 'w') as f: f.write(out)

def section(cls, inner, id_=''):
    return f'<section class="section {cls}"{f" id=\"{id_}\"" if id_ else ""}>\n<div class="container">\n{inner}</div>\n</section>\n'

def head_block(eyebrow, h2, p=''):
    return f'<div class="section-head reveal"><span class="eyebrow">{eyebrow}</span><h2>{h2}</h2>{f"<p>{p}</p>" if p else ""}</div>\n'

MODS = [('grid','Dashboard'),('box','Inventory'),('cart','Sales'),('clipboard','Orders'),('users','Customers'),('wallet','Finance'),('badge','Employees'),('chart','Reports'),('settings','Settings'),('bell','Notifications')]

def roadmap():
    steps = [('done','Brand identity','Logo, colours, typography.','Delivered'),('now','Website','You are here.','In progress'),('','Product design','Interface design before code.','Planned'),('','Platform foundation','Sign-in, business setup, database.','Planned'),('','Core modules','Built and tested one at a time.','Planned')]
    out = '<ol class="roadmap">\n'
    for i, (st, t, d, b) in enumerate(steps, 1):
        cls = {'done': ' is-done', 'now': ' is-now'}.get(st, '')
        badge = {'Delivered': 'badge badge--done', 'In progress': 'badge badge--progress', 'Planned': 'badge badge--planned'}[b]
        dot = ico('check') if st == 'done' else str(i)
        out += f'<li class="rm-step reveal d{i}{cls}"><span class="rm-dot">{dot}</span><h3>{t}</h3><p>{d}</p><span class="{badge}">{b}</span></li>\n'
    return out + '</ol>\n'

def cta(h, p, label, href):
    return section('', f'<div class="cta-band reveal"><h2>{h}</h2><p class="lead">{p}</p><a class="btn btn--primary" href="{href}">{label} {ico("arrow")}</a></div>\n')

# ---------------------------------------------------------------- HOME
pw = f'''<div class="pw reveal" data-pw>
<div class="pw__bar"><span class="pw__dot"></span><span class="pw__dot"></span><span class="pw__dot"></span><span class="pw__title">MOVA Business Platform</span><span class="pw__chip">Concept preview</span></div>
<div class="pw__body">
<div class="pw__side" role="tablist" aria-label="Preview sections" aria-orientation="vertical">
<button class="pw__tab" role="tab" id="pw-t1" aria-controls="pw-p1" aria-selected="true" aria-label="Overview" type="button">{ico('grid')}</button>
<button class="pw__tab" role="tab" id="pw-t2" aria-controls="pw-p2" aria-selected="false" tabindex="-1" aria-label="Inventory" type="button">{ico('box')}</button>
<button class="pw__tab" role="tab" id="pw-t3" aria-controls="pw-p3" aria-selected="false" tabindex="-1" aria-label="Sales" type="button">{ico('cart')}</button>
</div>
<div class="pw__panels">
<div class="pw__panel" role="tabpanel" id="pw-p1" aria-labelledby="pw-t1">
<h3 class="pw__h">Today</h3>
<div class="kpis"><div class="kpi"><small>Sales</small><strong data-count="184500" data-prefix="&#8358;">&#8358;0</strong></div><div class="kpi"><small>Low stock</small><strong data-count="6">0</strong></div><div class="kpi"><small>Open orders</small><strong data-count="12">0</strong></div></div>
<div class="bars" aria-hidden="true">{''.join(f'<div class="bar"><i data-h="{h}"></i></div>' for h in (42,58,50,72,64,88,76))}</div>
<div class="days" aria-hidden="true"><span>Mon</span><span>Tue</span><span>Wed</span><span>Thu</span><span>Fri</span><span>Sat</span><span>Sun</span></div>
<p class="pw__note">Sample data for illustration.</p>
</div>
<div class="pw__panel" role="tabpanel" id="pw-p2" aria-labelledby="pw-t2" hidden>
<h3 class="pw__h">Inventory</h3>
<div class="rows">
<div class="row"><span>Rice, 50 kg bag</span><span>38 in stock</span><div class="meter"><i data-w="72"></i></div></div>
<div class="row"><span>Cooking oil, 5 L</span><span>9 in stock</span><div class="meter"><i class="low" data-w="22"></i></div></div>
<div class="row"><span>Sugar, 1 kg</span><span>64 in stock</span><div class="meter"><i data-w="85"></i></div></div>
<div class="row"><span>Detergent, 2 kg</span><span>7 in stock</span><div class="meter"><i class="low" data-w="18"></i></div></div>
</div>
<p class="pw__note">Amber bars flag items below their reorder level. Sample data.</p>
</div>
<div class="pw__panel" role="tabpanel" id="pw-p3" aria-labelledby="pw-t3" hidden>
<h3 class="pw__h">Recent sales</h3>
<div class="rows">
<div class="row"><span>Sale 1042, 3 items</span><span>&#8358;12,400</span></div>
<div class="row"><span>Sale 1041, 1 item</span><span>&#8358;8,950</span></div>
<div class="row"><span>Sale 1040, 6 items</span><span>&#8358;23,100</span></div>
<div class="row"><span>Sale 1039, 2 items</span><span>&#8358;4,300</span></div>
</div>
<p class="pw__note">Every sale updates stock automatically. Sample data.</p>
</div>
</div></div></div>'''
hero = f'''<section class="hero">
<div class="container hero__inner">
<div class="hero__copy">
<span class="eyebrow reveal">MOVA Technologies</span>
<h1 class="reveal d1">Technology that moves <span class="accent">business forward.</span></h1>
<p class="lead reveal d2">Practical software that gives small businesses one clear view of their operations.</p>
<div class="hero__cta reveal d3"><a class="btn btn--primary" href="products.html">Explore the platform {ico('arrow')}</a><a class="btn btn--ghost" href="contact.html">Get in touch</a></div>
</div>
{pw}
</div>
</section>
'''
pillars = ''.join(f'<div class="pillar reveal d{i}"><span class="ico">{ico(ic)}</span><h3>{t}</h3><p>{d}</p></div>' for i, (ic, t, d) in enumerate([
    ('link', 'Connected', 'Stock, sales, customers and money in one place.'),
    ('shield', 'Secure by design', 'Every business sees only its own data.'),
    ('bolt', 'Practical', 'Made for everyday work on a phone or a computer.')], 1))
connect = f'''<div class="section-head reveal"><span class="eyebrow">The problem</span><h2>One view instead of five.</h2><p>Most small businesses run on scattered records. Toggle to see the difference.</p></div>
<div class="connect-wrap">
<div class="seg" role="group" aria-label="Choose a view"><button type="button" data-connect-state="scattered" aria-pressed="true">Scattered</button><button type="button" data-connect-state="connected" aria-pressed="false">Connected</button></div>
<div class="connect" data-connect data-state="scattered" role="img" aria-label="Diagram: five separate record sources joining into one MOVA platform">
<svg class="lines" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true"><line x1="50" y1="52" x2="24" y2="26" pathLength="100"/><line x1="50" y1="52" x2="76" y2="26" pathLength="100"/><line x1="50" y1="52" x2="24" y2="76" pathLength="100"/><line x1="50" y1="52" x2="76" y2="76" pathLength="100"/><line x1="50" y1="52" x2="50" y2="10" pathLength="100"/></svg>
<div class="hub"><img src="assets/img/mova-symbol-reversed.svg" width="44" height="50" alt=""></div>
<span class="node node--1">{ico('file')}Notebook</span><span class="node node--2">{ico('sheet')}Spreadsheet</span><span class="node node--3">{ico('chat')}Chat history</span><span class="node node--4">{ico('receipt')}Receipts</span><span class="node node--5">{ico('phone')}Contacts</span>
</div>
<p class="connect-caption" data-connect-caption aria-live="polite"></p>
</div>
'''
tiles = '<div class="mod-tiles">' + ''.join(f'<a class="mod-tile reveal" href="products.html#modules"><span class="ico">{ico(i)}</span>{t}</a>' for i, t in MODS) + '</div>\n'
home = hero + section('', pillars.join(['<div class="grid grid--3">', '</div>\n'])) + section('section--dark', connect) \
    + section('section--silver', head_block('MOVA Business Platform', 'Ten modules. One platform.', 'In planning. Built one module at a time.') + tiles
              + f'<p class="reveal cta-row"><a class="btn btn--dark" href="products.html">See how it works {ico("arrow")}</a></p>\n') \
    + section('', head_block('Progress', 'Where we are today.', 'No launch dates yet. Only what is real.') + roadmap(), 'progress') \
    + cta('Running a small business?', 'Tell us what slows your day down.', 'Get in touch', 'contact.html')
page('index.html', 'MOVA Technologies | Technology That Moves Business Forward', 'MOVA Technologies builds practical business software for small and medium-sized businesses, starting in Nigeria.', home, ['hero-demo.js', 'connect.js'])

# ---------------------------------------------------------------- PRODUCTS
roles = [('key', 'Super Administrator', 'Runs the platform: approvals, plans and support.'), ('badge', 'Business Owner', 'Full control of one business and its team.'), ('users', 'Business Manager', 'Runs daily operations on the owner\'s behalf.'), ('clipboard', 'Employee', 'Does assigned tasks. Sees only what is granted.')]
roles_html = '<div class="grid grid--4">' + ''.join(f'<div class="card role reveal d{i}"><span class="ico">{ico(ic)}</span><h3>{t}</h3><p>{d}</p></div>' for i, (ic, t, d) in enumerate(roles, 1)) + '</div>\n'
lanes = f'''<div class="lanes reveal">
<div class="lane"><header>{ico('lock')}Business A</header><div class="bar-line"></div><small>Own products, sales, customers</small></div>
<div class="lane"><header>{ico('lock')}Business B</header><div class="bar-line"></div><small>Own products, sales, customers</small></div>
<div class="wall">{ico('shield')}Isolated at the database level</div>
</div>
<p class="lead reveal">Planned: Row Level Security on every table, so one business can never read another&#8217;s records.</p>
'''
products = f'''<section class="page-hero"><div class="container"><span class="eyebrow">Product</span><h1>MOVA Business Platform</h1><p class="lead">A connected business system for small and medium-sized businesses.</p><p><span class="badge badge--planned">In planning. Not yet released.</span></p></div></section>
''' + section('section--dark', head_block('Modules', 'Explore the planned modules.', 'Select a module. Every one is planned, and none is released.') + f'''<div class="explorer" data-explorer><div class="explorer__list" role="tablist" aria-label="Platform modules" aria-orientation="vertical" data-explorer-list></div><div class="explorer__panel" id="explorer-panel" role="tabpanel" data-explorer-panel></div></div>
<noscript><p class="lead">Modules: Dashboard, Inventory, Sales, Orders, Customers, Finance, Employees, Reports, Account and Settings, Notifications.</p></noscript>
''', 'modules') \
    + section('', head_block('Roles', 'The right access for each person.') + roles_html) \
    + section('section--dark', head_block('Security', 'Each business in its own lane.') + lanes) \
    + section('section--silver', head_block('Roadmap', 'Built one step at a time.', 'Each module is tested and reviewed before the next begins.') + roadmap(), 'roadmap') \
    + cta('Want early access?', 'Join the list. We will tell you when there is something to try.', 'Request early access', 'contact.html?topic=early-access')
page('products.html', 'MOVA Business Platform | MOVA Technologies', 'The MOVA Business Platform is a planned, connected system for managing stock, sales, orders, customers, finance and staff.', products, ['explorer.js'])

# ---------------------------------------------------------------- SERVICES
svc = [('layers', 'Business software', 'Dashboards, inventory, sales and reporting tools.', ['Dashboards', 'Inventory', 'Reports']),
       ('globe', 'Websites and web apps', 'Fast, responsive and accessible from the first release.', ['Responsive', 'Accessible', 'Performant']),
       ('code', 'Custom business tools', 'Internal tools shaped around how your team works.', ['Internal tools', 'Workflows', 'Data views']),
       ('workflow', 'Automation and integrations', 'Connect your tools and remove repeated manual work.', ['Email', 'Payments', 'Messaging'])]
svc_html = '<div class="grid grid--2">' + ''.join(f'<div class="card reveal d{i}"><span class="ico">{ico(ic)}</span><h3>{t}</h3><p>{d}</p><div class="tags">' + ''.join(f'<span class="tag">{g}</span>' for g in tg) + '</div></div>' for i, (ic, t, d, tg) in enumerate(svc, 1)) + '</div>\n'
steps = [('01', 'Understand', 'We learn how your business really runs.'), ('02', 'Design', 'You see and approve the interface first.'), ('03', 'Build', 'Small, tested pieces, shown as they are made.'), ('04', 'Support', 'We stay to fix, improve and train.')]
steps_html = '<div class="steps">' + ''.join(f'<div class="step d{i}"><b>{n}</b><h3>{t}</h3><p>{d}</p></div>' for i, (n, t, d) in enumerate(steps, 1)) + '</div>\n'
services = '<section class="page-hero"><div class="container"><span class="eyebrow">Services</span><h1>What we build.</h1><p class="lead">Software for business operations. Our own products first, and tailored work where it fits.</p></div></section>\n' \
    + section('', svc_html) + section('section--silver', head_block('How we work', 'Four steps. No surprises.') + steps_html) \
    + cta('Have a project in mind?', 'Describe it in a few lines.', 'Tell us what you need', 'contact.html?topic=custom-project')
page('services.html', 'Services | MOVA Technologies', 'Business software, websites and web apps, custom business tools, and automation from MOVA Technologies.', services, [])

# ---------------------------------------------------------------- ABOUT
vals = [('spark', 'Innovation', 'Better ways to solve old problems.'), ('scale', 'Integrity', 'Honest with customers and ourselves.'), ('star', 'Excellence', 'High standards in design, code and service.'), ('shield', 'Reliability', 'Software people depend on every day.'),
        ('target', 'Customer focus', 'The customer\'s problem comes first.'), ('lock', 'Security', 'Customer data is protected by design.'), ('refresh', 'Continuous improvement', 'Always learning and refining.')]
vals_html = '<div class="grid grid--4">' + ''.join(f'<div class="card value reveal"><span class="ico">{ico(ic)}</span><h3>{t}</h3><p>{d}</p></div>' for ic, t, d in vals) + '</div>\n'
status = [('Brand identity', 'Delivered', 'badge badge--done', 'check'), ('This website', 'In progress', 'badge badge--progress', 'globe'), ('MOVA Business Platform', 'In planning', 'badge badge--planned', 'layers')]
status_html = '<div class="status-list">' + ''.join(f'<div class="status-item reveal"><span class="ico">{ico(ic)}</span><strong>{t}</strong><span class="{c}">{b}</span></div>' for t, b, c, ic in status) + '</div>\n'
about = '<section class="page-hero"><div class="container"><span class="eyebrow">About</span><h1>A technology company building useful business software.</h1></div></section>\n' \
    + section('', f'''<div class="split"><div class="reveal"><span class="eyebrow">Vision</span><p class="statement">To become a leading global technology company transforming how businesses operate and grow.</p></div><div class="reveal d1"><span class="eyebrow">Mission</span><p class="statement">Innovative, accessible and intelligent technology that simplifies operations and creates sustainable growth.</p></div></div>
''') + section('section--silver', head_block('Values', 'What guides our decisions.') + vals_html) \
    + section('', f'''<div class="split"><div>{head_block('Where we are', 'Honest progress.', 'We start with Nigerian small and medium-sized businesses and aim to serve businesses internationally over time.')}</div><div>{status_html}</div></div>''') \
    + section('section--silver', f'''<div class="founder reveal"><span class="avatar"><img src="assets/img/mova-symbol-reversed.svg" width="34" height="38" alt=""></span><div><h2 class="statement">Ahmad Yunusa</h2><p>Founder &amp; CEO. Leads product direction and company strategy.</p></div></div>''') \
    + cta('Talk to us.', 'Partners, early users and curious minds are welcome.', 'Get in touch', 'contact.html')
page('about.html', 'About | MOVA Technologies', 'MOVA Technologies is a business technology company building practical software for small and medium-sized businesses.', about, [])

# ---------------------------------------------------------------- CONTACT
contact_side = ''.join(f'<li class="reveal d{i}"><span class="ico">{ico(ic)}</span><div><strong>{t}</strong><p>{d}</p></div></li>' for i, (ic, t, d) in enumerate([
    ('bell', 'Early access', 'Be first to try the platform when it is ready.'), ('code', 'Custom projects', 'Describe the tool or site you need.'), ('link', 'Partnerships', 'Ideas for working together.')], 1))
form = f'''<form class="form" id="contact-form" novalidate>
<div class="field"><label for="name">Name</label><input id="name" name="name" type="text" autocomplete="name" maxlength="120" required aria-describedby="err-name"><span class="field-error" id="err-name" role="alert"></span></div>
<div class="field"><label for="email">Email</label><input id="email" name="email" type="email" autocomplete="email" maxlength="254" required aria-describedby="err-email"><span class="field-error" id="err-email" role="alert"></span></div>
<div class="field"><label for="topic">Topic</label><select id="topic" name="topic" required aria-describedby="err-topic"><option value="general">General enquiry</option><option value="early-access">Early access</option><option value="custom-project">Custom project</option><option value="partnership">Partnership</option></select><span class="field-error" id="err-topic" role="alert"></span></div>
<div class="field"><label for="message">Message</label><textarea id="message" name="message" maxlength="2000" required aria-describedby="err-message hint-message"></textarea><span class="field-hint" id="hint-message">10 to 2000 characters.</span><span class="field-error" id="err-message" role="alert"></span></div>
<div class="hp" aria-hidden="true"><label for="website">Leave this field empty</label><input id="website" name="website" type="text" tabindex="-1" autocomplete="off"></div>
<div class="field"><label class="check"><input type="checkbox" id="consent" name="consent" aria-describedby="err-consent"><span>I agree to MOVA Technologies using these details to reply. <a href="privacy.html">Privacy</a></span></label><span class="field-error" id="err-consent" role="alert"></span></div>
<button class="btn btn--primary" type="submit">Send message {ico('arrow')}</button>
<p class="form-status" id="form-status" role="status" aria-live="polite"></p>
</form>'''
contact = '<section class="page-hero"><div class="container"><span class="eyebrow">Contact</span><h1>Let&#8217;s talk.</h1><p class="lead">A few lines are enough.</p></div></section>\n' \
    + section('', f'<div class="split"><div class="reveal">{form}</div><ul class="grid contact-side">{contact_side}</ul></div>')
page('contact.html', 'Contact | MOVA Technologies', 'Contact MOVA Technologies about early access, custom projects or partnerships.', contact, ['contact.js'])

# ---------------------------------------------------------------- PRIVACY
privacy = '<section class="page-hero"><div class="container"><span class="eyebrow">Legal</span><h1>Privacy</h1></div></section>\n' + section('', '''<div class="prose">
<p>This page explains, in plain language, how this website handles personal information. It will be updated as the company&#8217;s legal and data-protection arrangements are completed.</p>
<h2>What we collect</h2>
<p>Only what you type into the contact form: your name, email address, topic and message, plus your confirmation that we may use them to reply.</p>
<h2>Why</h2>
<p>To read and answer your message. We do not use it for anything else.</p>
<h2>Where it is stored</h2>
<p>Messages are stored in a database hosted by Supabase. Only the site owner can read them.</p>
<h2>Cookies and tracking</h2>
<p>This website does not use advertising cookies or analytics. The browser may keep a short timestamp locally to limit repeated form submissions. Fonts are loaded from Google Fonts, which receives your IP address when the page loads.</p>
<h2>Your choices</h2>
<p>You can ask us to delete your message at any time by sending a new message through the contact form.</p>
</div>''')
page('privacy.html', 'Privacy | MOVA Technologies', 'How the MOVA Technologies website handles personal information.', privacy, [], current='privacy.html')

# ---------------------------------------------------------------- 404
nf = '<section class="page-hero"><div class="container"><span class="eyebrow">404</span><h1>Page not found.</h1><p class="lead">The page may have moved.</p><p><a class="btn btn--primary" href="index.html">Back to home ' + ico('arrow') + '</a></p></div></section>\n'
page('404.html', 'Page not found | MOVA Technologies', 'Page not found.', nf, [], current='404.html')
print('pages generated')
