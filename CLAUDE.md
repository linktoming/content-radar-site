# CLAUDE.md — content-radar-site

这是 radar.sharpener.ai 的发布 repo(GitHub Pages)。给在这里干活的 agent 的铁律:

## 哪些文件是生成的,别手改

`reports/*.html`、`archive-*.html`、`feed-*.xml`、`sitemap.xml`、`llms.txt` 全部由
**content-radar-2 repo 的 `tools/python/publish_public.py`** 生成,手改会在下次
publish 被原样盖掉。要改它们 → 改生成器,然后全量重跑(重跑命令见 content-radar-2
的 memory/文档,核心是对 `reports/archive.json` 里每个 (date, lang) 重新调用
publish_public.py;nav/归档页/feed/sitemap/llms.txt 都是 archive.json 的纯函数,会
自动重算)。

## index.html 是唯一手写文件,它自己就是真源

- **只做精确匹配替换,不整段重写。** 找不到旧串就报错停下,绝不"重新生成这一段"。
- 文件里有几处用事故换来的东西,看起来能"顺手清理",千万别:
  - JS 顶部 `__archive` 的声明位置和注释(TDZ 事故:声明晚了整个脚本中止,所有
    `.reveal` 卡在 opacity:0,**整页视觉空白**而 HTML 完全正常);
  - `html.js .reveal` 的降级设计(JS 挂了页面仍可读);
  - 文件头的 `<!doctype html>` + `<meta charset>`(缺过:quirks mode + 换 host 就乱码);
  - i18n 结构(CN 文案在 DOM,EN 在 `I18N` 字典,`data-i18n` 键连接两者)——改文案
    要 DOM 和字典两边一起改。
- **改完必跑 `scripts/smoke.sh`**(结构级断言,不锁具体文案),PASS 才能 push。

## 页脚是双拷贝,改一处必改另一处

index.html 的 `<footer>` ↔ `publish_public.py::footer_html()`(在 content-radar-2)。
两边源码有注释互指。改了生成器侧还要全量重跑报告页才能生效。

## Git

- **别用 `git add -A`**,用显式路径 add。血泪:2026-08-05 `-A` 把本地 `.gstack/`
  daemon 状态(含 token)扫进过这个 PUBLIC repo,当场 force-push 清除。
- 文案定稿一个新说法后,全 repo grep 旧说法确认清零(旧主张最爱藏在 head 元数据、
  JSON-LD、feed 描述里)。
