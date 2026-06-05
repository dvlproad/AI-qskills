#!/bin/bash
# skills_fetch_to_json.sh — 扫描 AI-qskills 目录，提取 SKILL.md front-matter，输出 skills_all.json
# 输出格式与 pods_all.json 一致，方便合并后直接喂给 repos_json_append_pods.sh
#
# Usage:
#   sh skills_fetch_to_json.sh --skills-dir <AI-qskills路径> --output <输出.json> [--order-file <顺序.json>]
#
# Example:
#   sh skills_fetch_to_json.sh \
#     --skills-dir /Users/qian/Project/AI/AI-qskills \
#     --output /path/to/skills_all.json \
#     --order-file /path/to/skills_order.json

set -euo pipefail

SKILLS_DIR=""
OUTPUT=""
ORDER_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="$2"; shift 2 ;;
    --output)     OUTPUT="$2"; shift 2 ;;
    --order-file) ORDER_FILE="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [[ -z "$SKILLS_DIR" || -z "$OUTPUT" ]]; then
  echo "Usage: sh skills_fetch_to_json.sh --skills-dir <dir> --output <json> [--order-file <json>]"
  exit 1
fi

python3 -c "
import os, re, json, sys

skills_dir = sys.argv[1]
output = sys.argv[2]
order_file = sys.argv[3] if len(sys.argv) > 3 else ''
repo_url = 'https://github.com/dvlproad/AI-qskills'

def parse_skill(d):
    skill_path = os.path.join(skills_dir, d, 'SKILL.md')
    if not os.path.isfile(skill_path):
        return None
    with open(skill_path) as f:
        content = f.read()
    parts = content.split('---', 2)
    if len(parts) < 3:
        return None
    front = parts[1]
    name_m = re.search(r'^name:\s*(.+)$', front, re.MULTILINE)
    ver_m = re.search(r'^version:\s*(.+)$', front, re.MULTILINE)
    if not name_m:
        return None
    name = name_m.group(1).strip()
    ver = ver_m.group(1).strip() if ver_m else ''
    desc = ''
    desc_m = re.search(r'^description:\s*(.+)$', front, re.MULTILINE)
    if desc_m:
        first_line = desc_m.group(1).strip()
        if first_line in ('|', '>', '|-', '>-', '|+', '>+'):
            desc_lines = []
            desc_start = desc_m.end()
            for line in front[desc_start:].splitlines():
                if line == '' or line.isspace():
                    continue
                if line[0] in (' ', '\t'):
                    desc_lines.append(line.strip())
                else:
                    break
            desc = ' '.join(desc_lines)
        else:
            desc = first_line
    return {
        'pod': name,
        'version': ver,
        'git': repo_url,
        'summary': desc
    }

def add_skill(skill, category, subspecs, out, seen):
    if skill and skill['pod'] not in seen:
        skill['category'] = category
        if subspecs:
            skill['subspecs'] = subspecs
        out.append(skill)
        seen.add(skill['pod'])

all_dirs = set()
for d in os.listdir(skills_dir):
    if os.path.isfile(os.path.join(skills_dir, d, 'SKILL.md')):
        all_dirs.add(d)

skills = []
seen = set()

if order_file:
    with open(order_file) as f:
        groups = json.load(f)
    for group in groups:
        category = group.get('category', '')
        pod_entries = group.get('pod', [])
        for entry in pod_entries:
            name = entry['name']
            subspec_names = entry.get('subspecs', [])
            sub_objs = []
            for sub in subspec_names:
                sub_skill = parse_skill(sub)
                if sub_skill:
                    sub_objs.append({'name': sub_skill['pod'], 'summary': sub_skill['summary']})
                    seen.add(sub)
            parent = parse_skill(name)
            add_skill(parent, category, sub_objs if sub_objs else None, skills, seen)
    for d in sorted(all_dirs):
        if d not in seen:
            skill = parse_skill(d)
            if skill:
                skill['category'] = '未分类'
                skills.append(skill)
                seen.add(skill['pod'])
else:
    for d in sorted(all_dirs):
        skill = parse_skill(d)
        if skill:
            skills.append(skill)

with open(output, 'w', encoding='utf-8') as f:
    json.dump(skills, f, ensure_ascii=False, indent=2)

print(f'✅ Generated {len(skills)} skills → {output}')
" "$SKILLS_DIR" "$OUTPUT" "$ORDER_FILE"
