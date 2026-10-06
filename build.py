#!/usr/bin/env python3
"""Construit index.html à partir de src/ et met à jour la version du cache dans sw.js.

Usage : python3 build.py
"""
import hashlib, pathlib, re

ROOT = pathlib.Path(__file__).parent
src = ROOT / "src"

head = (src / "head.html").read_text()
base = (src / "base.css").read_text()
app = (src / "app.css").read_text()
body = (src / "body.html").read_text()

FONT = ('<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
        '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap">\n')

html = head + "<title>Luck’In</title>\n" + FONT + "<style>" + base + app + "</style>\n\n</head><body>\n" + body + "</body></html>"
(ROOT / "index.html").write_text(html)

# Nouvelle version de cache à chaque changement : les téléphones récupèrent la mise à jour.
ver = hashlib.sha1(html.encode()).hexdigest()[:8]
sw = ROOT / "sw.js"
sw.write_text(re.sub(r'const C="[^"]*";', f'const C="luckin-{ver}";', sw.read_text(), count=1))
print(f"index.html construit · cache luckin-{ver}")
