"""Check Vietnamese documentation coverage, immutable examples, and local links.

Run from any directory: python docs/vi/_tools/validate.py
The checker makes no network requests and does not run application commands.
"""
from pathlib import Path
from collections import Counter
from urllib.parse import unquote, urlsplit
import json
import argparse
import re
import subprocess
import sys
import unicodedata

ROOT = Path(__file__).resolve().parents[3]
DEST = ROOT / "docs/vi"
EXCLUDED = {".github/copilot-instructions.md", ".junie/guidelines.md"}


def sources():
    tracked = subprocess.check_output(["git", "ls-files", "*.md"], cwd=ROOT, text=True).splitlines()
    return [p for p in tracked if not p.startswith(("docs/superpowers/", "docs/vi/"))
            and Path(p).name not in {"AGENTS.md", "CLAUDE.md"} and p not in EXCLUDED]


def sections(text):
    prose, blocks, current = [], [], []
    fence = None
    for line in text.splitlines():
        marker = re.match(r"^\s*(?:> ?)*(`{3,}|~{3,})", line)
        if marker and fence is None:
            fence = marker[1][0]
            current = [line]
        elif fence:
            current.append(line)
            if marker and marker[1][0] == fence:
                blocks.append("\n".join(current))
                fence = None
        else:
            prose.append(line)
    if fence:
        blocks.append("\n".join(current))
    return "\n".join(prose), blocks


def slug(text):
    text = re.sub(r"<[^>]*>", "", text)
    text = re.sub(r"\[([^\]]+)\]\([^)]*\)", r"\1", text)
    text = text.lower().replace("`", "")
    return "".join(c for c in text if c.isalnum() or c in "_ -").replace(" ", "-")


def anchors(text):
    prose, _ = sections(text)
    result = set(re.findall(r'<a\s+(?:id|name)=["\']([^"\']+)', prose))
    counts = Counter()
    for line in prose.splitlines():
        heading = re.match(r"^#{1,6}\s+(.+?)\s*#*\s*$", line)
        if heading:
            key = slug(heading[1])
            n = counts[key]
            counts[key] += 1
            result.add(key + (f"-{n}" if n else ""))
    return result


def links(text):
    prose, _ = sections(text)
    # Inline code may contain illustrative Markdown links or HTML attributes.
    prose = re.sub(r"`+[^`\n]+`+", "", prose)
    prose = re.sub(r"<!--.*?-->", "", prose, flags=re.S)
    found = re.findall(r"\]\(([^\s)]+)(?:\s+[^)]*)?\)", prose)
    found += re.findall(r"^\s*\[[^\]]+\]:\s*(\S+)", prose, flags=re.M)
    found += re.findall(r"(?:href|src|srcset)=[\"']([^\"']+)", prose)
    return found


def code_spans(prose):
    # CommonMark allows code spans to wrap across source lines.
    # Normalize whitespace as the rendered code does, rather than mistaking the
    # prose between closing and opening backticks for code on wrapped lines.
    return Counter(re.sub(r"\s+", " ", m[2]).strip()
                   for m in re.finditer(r"(?<!`)(`+)(?!`)(.*?)(?<!`)\1(?!`)", prose, re.S))


def check(require_reviewed=False):
    errors = []
    checked_links = 0
    checked_blocks = 0
    files = sources()
    anchor_cache = {}
    for src in files:
        source = ROOT / src
        target = DEST / src
        if not target.exists():
            errors.append(f"MISSING {src}")
            continue
        english = source.read_text(encoding="utf-8")
        vietnamese = target.read_text(encoding="utf-8")
        ep, eb = sections(english)
        vp, vb = sections(vietnamese)
        checked_blocks += len(eb)
        if eb != vb:
            errors.append(f"CODE_BLOCK {src}: {len(eb)} source / {len(vb)} translated")
        ec = code_spans(ep)
        vc = code_spans(vp)
        if ec != vc:
            errors.append(f"INLINE_CODE {src}: missing={dict(ec-vc)}, extra={dict(vc-ec)}")
        if len(re.findall(r"^#{1,6} ", ep, re.M)) != len(re.findall(r"^#{1,6} ", vp, re.M)):
            errors.append(f"HEADINGS {src}")
        if "[Tiếng Việt](" not in english or "[English](" not in vietnamese:
            errors.append(f"SWITCH {src}")
        if src.startswith("docs/llm-guides/") and "nguồn chính sách có hiệu lực" not in vietnamese:
            errors.append(f"POLICY_NOTICE {src}")
        if re.search(r"QZX\s*\d+\s*XZQ|▁|<unk>", vp):
            errors.append(f"MODEL_TOKEN {src}")
    # Include index/report links, but avoid treating Python regexes as Markdown.
    targets = sorted(DEST.rglob("*.md"))
    for target in targets:
        text = target.read_text(encoding="utf-8")
        for url in links(text):
            if re.match(r"^(?:[\w+.-]+:|//)", url):
                continue
            parts = urlsplit(url.strip("<>"))
            path = unquote(parts.path)
            linked = (ROOT / path.lstrip("/") if path.startswith("/") else target.parent / path).resolve() if path else target
            checked_links += 1
            if not linked.exists():
                errors.append(f"LINK {target.relative_to(DEST)}: {url}")
            elif parts.fragment and linked.suffix.lower() == ".md":
                if linked not in anchor_cache:
                    anchor_cache[linked] = anchors(linked.read_text(encoding="utf-8"))
                if unquote(parts.fragment) not in anchor_cache[linked]:
                    errors.append(f"ANCHOR {target.relative_to(DEST)}: {url}")
    manifest_path = DEST / "coverage.json"
    reviewed = []
    drafts = []
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        reviewed = [p for p, status in manifest["documents"].items() if status == "reviewed"]
        drafts = [p for p, status in manifest["documents"].items() if status == "draft"]
    if require_reviewed and (drafts or len(reviewed) != len(files)):
        errors.append(f"REVIEW_INCOMPLETE: {len(reviewed)} reviewed / {len(files)} required")
    result = {"source_files": len(files), "translated_files": sum((DEST/p).exists() for p in files),
              "reviewed_files": len(reviewed), "draft_files": len(drafts),
              "code_blocks": checked_blocks, "local_links": checked_links, "errors": errors}
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return bool(errors)


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-reviewed", action="store_true")
    args = parser.parse_args()
    raise SystemExit(check(args.require_reviewed))
