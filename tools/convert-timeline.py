"""Convert old vertical .timeline blocks to the .htimeline syntax.

Usage:
    python3 convert-timeline.py input.qmd output.qmd

Input and output may be the same file. Expects the markup of the vertical
timeline from nenuial/quarto-keynote (key-resources/timeline.scss):

    <!-- Begin timeline -->
    ::: {.container ...}
    ::: {.timeline ...}
    :::: {.timeline-block ...}
    ::: {.timeline-icon}
    :::
    ::: {.timeline-content}
    ::: {.timeline-date}
    1917--1924
    :::
    **Title**
    ::: {.timeline-details ...}
    content, optionally in 80/20 .columns with an image
    :::
    :::
    ::::
    ...
    <!-- End timeline -->

Each block becomes `### Title {date="..."}` followed by its details; column
divs are dropped so that a trailing image goes into the side column. French
month dates ("Février 1917") become ISO ("1917-02"). Timelines without
fragments get `.static`. Add `filters: [htimeline]` to the front matter
yourself.
"""
import re, sys

if len(sys.argv) != 3:
    sys.exit(__doc__)

MONTHS = {m: i + 1 for i, m in enumerate(
    "janvier février mars avril mai juin juillet août septembre octobre novembre décembre".split())}

def convert_date(d):
    m = re.fullmatch(r"(\w+) (\d{3,4})", d.strip())
    if m and m.group(1).lower() in MONTHS:
        return f"{m.group(2)}-{MONTHS[m.group(1).lower()]:02d}"
    return re.sub(r"--\.\.\.$", "--", d.strip())

def convert_block(lines):
    date = title = None
    details, in_details, depth = [], False, 0
    i = 0
    while i < len(lines):
        l = lines[i]
        if l.startswith("::: {.timeline-date}"):
            date = convert_date(lines[i + 1]); i += 3; continue
        if date and title is None and l.strip().startswith("**"):
            title = l.strip().strip("*").strip(); i += 1; continue
        if l.startswith("::: {.timeline-details"):
            in_details, depth = True, 1; i += 1; continue
        if in_details:
            if re.match(r"^:::+ *\{", l) or re.match(r"^:::+ *\w", l):
                depth += 1
                if "no-caption" in l:
                    details.append("@@NOCAPTION@@")
                i += 1; continue
            if re.match(r"^:::+\s*$", l):
                depth -= 1
                if depth == 0:
                    in_details = False
                i += 1; continue
            if l.strip() == "<!-- end columns -->":
                i += 1; continue
            details.append(l)
        i += 1
    nocap = "@@NOCAPTION@@" in details
    details = [l for l in details if l != "@@NOCAPTION@@"]
    if nocap:
        details = [re.sub(r"\{\.lightbox\}", "{.lightbox .no-caption}", l) for l in details]
    fixed = []
    for l in details:
        if l.startswith("![") and fixed and fixed[-1].strip():
            fixed.append("")
        fixed.append(l)
    details = fixed
    while details and not details[-1].strip(): details.pop()
    while details and not details[0].strip(): details.pop(0)
    out = [f'### {title} {{date="{date}"}}', ""]
    if details:
        out += details + [""]
    return out

def convert_timeline(lines, static):
    blocks, cur = [], None
    for l in lines:
        if l.startswith(":::: {.timeline-block"):
            cur = []; blocks.append(cur); continue
        if cur is not None:
            cur.append(l)
    out = ["::: {.htimeline" + (" .static" if static else "") + "}", ""]
    for b in blocks:
        out += convert_block(b)
    out += [":::"]
    return out

src = open(sys.argv[1], encoding="utf-8").read().split("\n")
res, i = [], 0
while i < len(src):
    if src[i] == "<!-- Begin timeline -->":
        j = src.index("<!-- End timeline -->", i)
        region = src[i + 1:j]
        static = "fragment" not in region[0]
        res += convert_timeline(region, static)
        i = j + 1; continue
    res.append(src[i]); i += 1
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(res))
