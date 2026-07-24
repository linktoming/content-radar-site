# Content Radar — public site

Landing page + daily **public editions** of Content Radar, served at
**radar.sharpener.ai** via GitHub Pages.

- `index.html` — bilingual (auto by system language) landing.
- `reports/*.html` — de-personalized public editions (free, complete, no personal info;
  the paid 选题 + internal ops + personal feed are stripped at render time).
- `reports/archive.json` — index the landing reads to list editions.

**This repo holds ONLY public content.** It is generated + pushed by the private
content-radar pipeline (`tools/python/publish_public.py`, allowlist render). Do not
hand-edit reports here — they are overwritten on each publish.
