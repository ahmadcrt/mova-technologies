#!/usr/bin/env python3
"""Generates the platform pages in app/. Run from the repository root: python3 tools/gen_app.py"""
import os, html
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSP = ("default-src 'self'; script-src 'self'; style-src 'self' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; "
       "img-src 'self' data:; connect-src 'self' https://*.supabase.co; base-uri 'self'; form-action 'self'; object-src 'none'")
def ico(n): return f'<svg class="icon" aria-hidden="true" focusable="false"><use href="../assets/img/icons.svg#i-{n}"/></svg>'
def head(title, page):
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="{CSP}">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0B1220">
<meta name="robots" content="noindex">
<title>{html.escape(title)} | MOVA Business Platform</title>
<meta name="description" content="Sign in to the MOVA Business Platform.">
<link rel="icon" href="../favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="../apple-touch-icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&family=Sora:wght@600;700&display=swap">
<link rel="stylesheet" href="../assets/css/tokens.css">
<link rel="stylesheet" href="../assets/css/base.css">
<link rel="stylesheet" href="../assets/css/components.css">
<link rel="stylesheet" href="css/app.css">
<script src="../assets/js/boot.js"></script>
<script src="../assets/js/config.js"></script>
</head>
<body class="app-body" data-page="{page}">
<a class="skip-link" href="#main">Skip to content</a>
'''
def write(name, content): open(os.path.join(ROOT, 'app', name), 'w').write(content)
def field(label, id_, type_='text', extra='', hint=''):
    return f'<div class="field"><label for="{id_}">{label}</label><input id="{id_}" name="{id_}" type="{type_}" {extra} aria-describedby="err-{id_}"><span class="field-error" id="err-{id_}" role="alert"></span></div>'
def pw(label, id_, auto):
    return f'<div class="field"><label for="{id_}">{label}</label><div class="pw-wrap"><input id="{id_}" name="{id_}" type="password" autocomplete="{auto}" maxlength="72" aria-describedby="err-{id_}"><button class="pw-toggle" type="button" data-toggle-password="{id_}" aria-pressed="false" aria-label="Show password">Show</button></div><span class="field-error" id="err-{id_}" role="alert"></span></div>'
STATUS = '<p class="form-status" id="form-status" role="status" aria-live="polite"></p>'
def auth(page, title, inner, scripts='auth-pages.js'):
    return head(title, page) + f'''<main id="main" class="auth">
<aside class="auth__brand"><a href="../index.html" aria-label="MOVA Technologies website"><img src="../assets/img/mova-primary-reversed.svg" width="211" height="64" alt="MOVA Technologies"></a><p class="auth__tag">Technology That Moves Business Forward.</p></aside>
<section class="auth__panel"><div class="auth__card">
{inner}
</div></section>
</main>
<script type="module" src="js/{scripts}"></script>
</body>
</html>
'''
write('login.html', auth('login', 'Sign in', f'''<div><h1>Welcome back</h1><p class="sub">Sign in to manage your business.</p></div>
<form class="form" data-auth novalidate>
{field('Email', 'email', 'email', 'autocomplete="email" maxlength="254"')}
{pw('Password', 'password', 'current-password')}
<p class="row-end"><a href="forgot.html">Forgot password?</a></p>
<button class="btn btn--primary btn--block" type="submit">Sign in {ico('arrow')}</button>
{STATUS}
</form>
<p class="auth-foot">New to MOVA? <a href="register.html">Create an account</a></p>'''))
write('register.html', auth('register', 'Create account', f'''<div class="progress" aria-hidden="true"><i class="on"></i><i></i></div>
<div><p class="step-label">Step 1 of 2</p><h1>Create your account</h1></div>
<form class="form" data-auth novalidate>
{field('Full name', 'name', 'text', 'autocomplete="name" maxlength="120"')}
{field('Email', 'email', 'email', 'autocomplete="email" maxlength="254"')}
{pw('Password', 'password', 'new-password')}
<p class="field-hint">Use 8 or more characters.</p>
<div class="field"><label class="check"><input type="checkbox" id="consent" name="consent" aria-describedby="err-consent"><span>I agree to the <a href="../privacy.html">Privacy notice</a>.</span></label><span class="field-error" id="err-consent" role="alert"></span></div>
<button class="btn btn--primary btn--block" type="submit">Continue {ico('arrow')}</button>
{STATUS}
</form>
<p class="auth-foot">Already have an account? <a href="login.html">Sign in</a></p>'''))
write('forgot.html', auth('forgot', 'Forgot password', f'''<div><h1>Reset your password</h1><p class="sub">Enter your email and we will send a reset link.</p></div>
<form class="form" data-auth novalidate>
{field('Email', 'email', 'email', 'autocomplete="email" maxlength="254"')}
<button class="btn btn--primary btn--block" type="submit">Send reset link {ico('arrow')}</button>
{STATUS}
</form>
<p class="auth-foot"><a href="login.html">Back to sign in</a></p>'''))
write('reset.html', auth('reset', 'Choose a new password', f'''<div><h1>Choose a new password</h1><p class="sub">Use 8 or more characters.</p></div>
<form class="form" data-auth novalidate>
{pw('New password', 'password', 'new-password')}
{pw('Confirm password', 'confirm', 'new-password')}
<button class="btn btn--primary btn--block" type="submit">Update password {ico('check')}</button>
{STATUS}
</form>
<div id="reset-invalid" hidden><p class="form-status form-status--error is-visible">This reset link is invalid or has expired.</p><p class="auth-foot"><a href="forgot.html">Request a new link</a></p></div>'''))
write('setup.html', head('Set up your business', 'setup') + f'''<main id="main" class="auth">
<aside class="auth__brand"><a href="../index.html" aria-label="MOVA Technologies website"><img src="../assets/img/mova-primary-reversed.svg" width="211" height="64" alt="MOVA Technologies"></a><p class="auth__tag">Technology That Moves Business Forward.</p></aside>
<section class="auth__panel"><div class="auth__card">
<div class="progress" aria-hidden="true"><i class="on"></i><i class="on"></i></div>
<div><p class="step-label">Step 2 of 2</p><h1>Set up your business</h1><p class="sub">You can change these later in Settings.</p></div>
<form class="form" id="setup-form" novalidate>
{field('Business name', 'bname', 'text', 'maxlength="100" autocomplete="organization"')}
<div class="field"><label for="btype">Business type</label><select id="btype" name="btype"><option value="retail">Retail shop</option><option value="services">Services</option><option value="wholesale">Wholesale or distribution</option><option value="food">Food and beverage</option><option value="other">Other</option></select><span class="field-error" id="err-btype" role="alert"></span></div>
{field('City or state', 'city', 'text', 'maxlength="100" autocomplete="address-level2"')}
<div class="field"><label for="team">Team size</label><select id="team" name="team"><option value="solo">Just me</option><option value="2-5">2 to 5 people</option><option value="6-20">6 to 20 people</option><option value="21+">More than 20</option></select><span class="field-error" id="err-team" role="alert"></span></div>
<button class="btn btn--primary btn--block" type="submit">Create my business {ico('check')}</button>
{STATUS}
</form>
</div></section>
</main>
<script type="module" src="js/setup.js"></script>
</body>
</html>
''')
write('dashboard.html', head('Dashboard', 'dashboard') + f'''<div class="shell">
<aside class="shell__side">
<div><img src="../assets/img/mova-secondary-reversed.svg" width="111" height="34" alt="MOVA"><nav class="side-nav" aria-label="Main"><a href="dashboard.html" aria-current="page">{ico('grid')}Dashboard</a></nav></div>
<div class="side-user"><span>Signed in as</span><strong data-user-name></strong><button class="btn btn--ghost" type="button" data-signout>Sign out</button></div>
</aside>
<div>
<header class="shell__top"><div class="who"><img src="../assets/img/mova-symbol-reversed.svg" width="27" height="30" alt="MOVA"><span data-biz-name>Your business</span></div><button class="btn btn--ghost" type="button" data-signout>Sign out</button></header>
<main id="main" class="shell__main"><div class="inner"><div class="dash-head"><h1>Dashboard</h1><p class="sub" id="greet"></p></div><div id="dash" class="inner"><p class="loading" role="status">Loading your business...</p></div></div></main>
</div>
</div>
<script type="module" src="js/dashboard.js"></script>
</body>
</html>
''')
print('app pages generated')
