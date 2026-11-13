#!/usr/bin/env python3
"""Zero-dependency site checker. Run from the repository root: python3 tools/check.py
Checks: local links/assets exist, #anchors exist, no inline scripts/styles/handlers (CSP), no emoji,
one <h1> and a description per page, alt text on images, JS/CSS files referenced exist."""
import os, re, sys
from html.parser import HTMLParser
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EMOJI = re.compile('[\U0001F300-\U0001FAFF\u2600-\u27BF\u2B50\u2B06\u2705\u274C]')
class P(HTMLParser):
    def __init__(s): super().__init__(); s.ids=set(); s.refs=[]; s.h1=0; s.desc=False; s.title=False; s.errs=[]; s.text=[]; s.in_script=False
    def handle_starttag(s, tag, a):
        d=dict(a)
        if 'id' in d: s.ids.add(d['id'])
        if tag=='h1': s.h1+=1
        if tag=='meta' and d.get('name')=='description' and d.get('content'): s.desc=True
        if tag=='title': s.title=True
        for k in d:
            if k.startswith('on'): s.errs.append(f'inline handler {k} on <{tag}>')
        if 'style' in d: s.errs.append(f'inline style attribute on <{tag}>')
        if tag=='script': s.in_script=True; 
        if tag=='script' and 'src' not in d: s.errs.append('inline <script>')
        if tag=='img' and 'alt' not in d: s.errs.append(f'img without alt: {d.get("src")}')
        for k in ('href','src'):
            if k in d and tag!='use' : s.refs.append(d[k])
            if k=='href' and tag=='use': s.refs.append(d[k])
    def handle_endtag(s, tag):
        if tag=='script': s.in_script=False
    def handle_data(s, data):
        if not s.in_script: s.text.append(data)
pages=sorted([f for f in os.listdir(ROOT) if f.endswith('.html')]+[os.path.join('app',f) for f in os.listdir(os.path.join(ROOT,'app')) if f.endswith('.html')] if os.path.isdir(os.path.join(ROOT,'app')) else [f for f in os.listdir(ROOT) if f.endswith('.html')])
parsed={}
for f in pages:
    p=P(); p.feed(open(os.path.join(ROOT,f),encoding='utf-8').read()); parsed[f]=p
bad=0
for f,p in parsed.items():
    errs=list(p.errs)
    if p.h1!=1: errs.append(f'expected 1 h1, found {p.h1}')
    if not p.desc: errs.append('missing meta description')
    if not p.title: errs.append('missing title')
    if EMOJI.search(''.join(p.text)): errs.append('emoji found in text')
    for r in p.refs:
        if re.match(r'^(https?:|mailto:|tel:|data:)',r): continue
        path,_,frag=r.partition('#'); path=path.split('?')[0]
        pdir=os.path.dirname(os.path.join(ROOT,f))
        target=os.path.normpath(os.path.join(pdir,path)) if path else os.path.join(ROOT,f)
        if path and not os.path.exists(target): errs.append(f'missing file: {r}'); continue
        if frag and (path.endswith('.html') or not path):
            tp=parsed.get(os.path.relpath(target,ROOT))
            if tp and frag not in tp.ids: errs.append(f'missing anchor: {r}')
        if frag and path.endswith('.svg'):
            if f'id="{frag}"' not in open(target,encoding='utf-8').read(): errs.append(f'missing sprite symbol: {r}')
    for e in errs: print(f'FAIL {f}: {e}'); bad+=1
for dp,_,fs in [x for base in ('assets','app') if os.path.isdir(os.path.join(ROOT,base)) for x in os.walk(os.path.join(ROOT,base))]:
    for fn in fs:
        if fn.endswith(('.js','.css')):
            t=open(os.path.join(dp,fn),encoding='utf-8').read()
            if EMOJI.search(t): print(f'FAIL {fn}: emoji in source'); bad+=1
            if re.search(r'service_role|sb_secret|eyJhbGci',t): print(f'FAIL {fn}: possible secret key'); bad+=1
print('check passed' if not bad else f'{bad} problem(s)'); sys.exit(1 if bad else 0)
