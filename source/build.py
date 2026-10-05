#!/usr/bin/env python3
"""Construit la version téléphone (PWA) à partir de japprends-a-lire.html.
Usage : python3 build.py   → génère pwa/index.html et pwa/sw.js"""
import hashlib, json, os, re
ROOT=os.path.dirname(os.path.abspath(__file__)); PWA=os.path.join(ROOT,'..')
src=open(os.path.join(ROOT,"japprends-a-lire.html"),encoding='utf-8').read()
src=re.sub(r'<link rel="preconnect"[^>]*>\n','',src)
src=re.sub(r'<link rel="stylesheet" href="https://fonts.googleapis.com[^>]*>\n','',src)
assert 'fonts.googleapis' not in src
LAT='U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD'
EXT='U+0100-02BA,U+02BD-02C5,U+02C7-02CC,U+02CE-02D7,U+02DD-02FF,U+1D00-1DBF,U+1E00-1E9F,U+1EF2-1EFF,U+2020,U+20A0-20AB,U+20AD-20C0,U+2113,U+2C60-2C7F,U+A720-A7FF'
ff=[]
for w in (400,700):
    ff.append(f"@font-face{{font-family:'Andika';font-weight:{w};font-display:swap;src:url(fonts/andika-latin-{w}-normal.woff2) format('woff2');unicode-range:{LAT}}}")
    ff.append(f"@font-face{{font-family:'Andika';font-weight:{w};font-display:swap;src:url(fonts/andika-latin-ext-{w}-normal.woff2) format('woff2');unicode-range:{EXT}}}")
for w in (500,600,700,800):
    ff.append(f"@font-face{{font-family:'Baloo 2';font-weight:{w};font-display:swap;src:url(fonts/baloo-2-latin-{w}-normal.woff2) format('woff2')}}")
head=f"""<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="description" content="Apprendre à lire et à écrire : lettres, sons, syllabes, mots et phrases.">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" type="image/png" href="icons/favicon.png">
<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
<meta name="mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-title" content="Lire">
<style>{''.join(ff)}
:root{{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}} body{{margin:0}} img{{max-width:100%}} [hidden]{{display:none!important}}
html{{-webkit-text-size-adjust:100%}} body{{overscroll-behavior-y:contain;user-select:none;-webkit-user-select:none}} input,textarea{{user-select:text;-webkit-user-select:text}}</style>
<script>window.JAL_PWA=true;</script>
"""
src=src.replace('</style>\n\n<div id="app"','</style>\n</head>\n<body>\n<div id="app"',1)
assert '<body>' in src
html=head+src+'\n</body>\n</html>\n'
open(os.path.join(PWA,'index.html'),'w',encoding='utf-8').write(html)
# liste des fichiers à mettre en cache
core=['./','index.html','manifest.webmanifest','lib/jszip.min.js']
for d in ('fonts','icons'):
    core+= [f'{d}/{f}' for f in sorted(os.listdir(os.path.join(PWA,d)))]
h=hashlib.sha1()
for f in core[1:]:
    h.update(open(os.path.join(PWA,f),'rb').read())
version=h.hexdigest()[:10]
sw=open(os.path.join(ROOT,'sw.template.js'),encoding='utf-8').read().replace('__VERSION__',version).replace('__CORE__',json.dumps(core,ensure_ascii=False))
open(os.path.join(PWA,'sw.js'),'w',encoding='utf-8').write(sw)
print('index.html', len(html)//1024,'Ko · cache', version, '·', len(core),'fichiers')
