#!/bin/sh
# pod_match2_repos.sh - 在每个有 pod 的 section 下按主表追加 Pod 情况表格
# 用法: sh pod_match2_repos.sh [--separate-subspecs] <项目列表.md> [pod数据.json]

SEPARATE=false
while [ $# -gt 0 ]; do
    case "$1" in
        --separate-subspecs) SEPARATE=true; shift ;;
        -h|--help) echo "用法: sh pod_match2_repos.sh [--separate-subspecs] <项目列表.md> [pod数据.json]"; exit 0 ;;
        --) shift; break ;;
        *) break ;;
    esac
done

REPOS_MD="${1}"
POD_JSON="${2:-$(pwd)/github_pod_all.json}"

[ -z "$REPOS_MD" ] && { echo "用法: sh pod_match2_repos.sh [--separate-subspecs] <项目列表.md> [pod数据.json]"; exit 1; }
[ ! -f "$REPOS_MD" ] && { echo "文件不存在: $REPOS_MD"; exit 1; }
[ ! -f "$POD_JSON" ] && { echo "文件不存在: $POD_JSON，请先运行 pods_collectAndRender.sh"; exit 1; }

TMP=$(mktemp)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 - "$REPOS_MD" "$POD_JSON" "$SCRIPT_DIR" "$SEPARATE" > "$TMP" << 'PYEOF'
import json, re, sys
sys.path.insert(0, sys.argv[3])
from pod_data_render import render_project_table, render_unmatched_table, render_subspec_inline

repos_md = sys.argv[1]
pod_json = sys.argv[2]
separate = sys.argv[4] == 'true'  # --separate-subspecs 开关

def norm_url(url):
    u = url.rstrip('/')
    u = re.sub(r'\.git$', '', u)
    return u

def has_md_link(line):
    return re.match(r'^\|\s*\[([^\]]+)\]\(([^)]+)\)', line)

with open(pod_json) as f:
    pods = json.load(f)

pod_map = {}
for p in pods:
    git = p.get('git', 'N/A')
    if git == 'N/A':
        continue
    norm = norm_url(git)
    if norm not in pod_map:
        pod_map[norm] = []
    pod_map[norm].append({
        'pod': p['pod'],
        'version': p.get('version', 'N/A'),
        'summary': p.get('summary', ''),
        'source': p.get('source', ''),
        'visibility': p.get('visibility', ''),
        'language': p.get('language', ''),
        'subspec_count': p.get('subspec_count', 0),
        'subspecs': p.get('subspecs', []),
    })

matched_urls = set()

def find_pods_for_repo(repo_url):
    norm = norm_url(repo_url)
    matched = pod_map.get(norm, [])
    if not matched:
        norm2 = re.sub(r'^https?://', '', norm)
        for key in pod_map:
            key2 = re.sub(r'^https?://', '', key)
            if norm2 == key2 or norm2 in key:
                matched = pod_map[key]
                matched_urls.add(key)
                return matched
    if matched:
        matched_urls.add(norm)
    return matched

def is_pod_table_header(line):
    return '| 仓库名 | 开发的Pod |' in line

def is_table_separator(line):
    return bool(re.match(r'^\|\s*-{3,}', line))

with open(repos_md) as f:
    lines = f.readlines()

# Pre-process: parse old Pod tables to extract row order, then strip them
ordered_rows = []  # [(repo_name, pod_name)] preserving user's exact row order
clean_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    if re.match(r'^##\s+未匹配的 Pod', line):
        i += 1
        while i < len(lines) and re.match(r'^\s*$', lines[i]):
            i += 1
        if i < len(lines) and ('| 开发的Pod |' in lines[i] or '| Pod |' in lines[i]):
            i += 1  # skip header
            if i < len(lines) and is_table_separator(lines[i]):
                i += 1
            while i < len(lines):
                l = lines[i]
                if re.match(r'^\|', l):
                    i += 1
                    continue
                if re.match(r'^\s*$', l):
                    i += 1
                    continue
                break
        continue
    if 'Pod 情况：' in line:
        i += 1
        while i < len(lines) and re.match(r'^\s*$', lines[i]):
            i += 1
        if i < len(lines) and is_pod_table_header(lines[i]):
            i += 1  # skip Pod table header
            if i < len(lines) and is_table_separator(lines[i]):
                i += 1
            # Parse and skip Pod data rows
            while i < len(lines):
                l = lines[i]
                if re.match(r'^\|[-]+', l):
                    break
                if re.match(r'^\|', l) and not has_md_link(l):
                    parts = [p.strip() for p in l.split('|')]
                    if len(parts) >= 3:
                        repo_name = parts[1]
                        pod_name = parts[2]
                        ordered_rows.append((repo_name, pod_name))
                    i += 1
                    continue
                if re.match(r'^\s*$', l):
                    i += 1
                    continue
                break
        continue
    if '子库详情' in line:
        i += 1
        while i < len(lines) and re.match(r'^\s*$', lines[i]):
            i += 1
        if i < len(lines) and '| Subspec | Summary |' in lines[i]:
            i += 1  # skip header
            if i < len(lines) and is_table_separator(lines[i]):
                i += 1
            while i < len(lines):
                l = lines[i]
                if re.match(r'^\|', l):
                    i += 1
                    continue
                if re.match(r'^\s*$', l):
                    i += 1
                    continue
                break
        continue
    clean_lines.append(line)
    i += 1
lines = clean_lines

# Main processing
out = []
chunk_lines = []
chunk_repos = []
in_table = False

def flush_chunk():
    global chunk_lines, chunk_repos
    if not chunk_lines:
        return

    # 构建 dict 类型的匹配结果，每条含 repo_name 和所有 pod 字段
    repo_match = {}
    for repo_name, repo_url in chunk_repos:
        matched = find_pods_for_repo(repo_url)
        for pod_info in matched:
            repo_match[(repo_name, pod_info['pod'])] = {
                'repo_name': repo_name,
                **pod_info
            }

    all_pods = []
    seen = set()

    # 按用户原来的行序输出
    for rn, pn in ordered_rows:
        key = (rn, pn)
        if key in repo_match:
            all_pods.append(repo_match[key])
            seen.add(key)

    # 新增的 pod（不在原有行序中）按名称排序追加
    remaining = sorted(repo_match.items(), key=lambda x: (x[0][0], x[0][1]))
    for key, row in remaining:
        if key not in seen:
            all_pods.append(row)

    out.extend(chunk_lines)

    if all_pods:
        out.append(render_project_table(all_pods))
        out.append(render_subspec_inline(all_pods, separate_subspecs=separate))

    chunk_lines = []
    chunk_repos = []

def is_new_table_header(line):
    return bool(re.match(r'^\|\s', line)) and not has_md_link(line)

for line in lines:
    is_heading = re.match(r'^#{2,6}\s', line)
    if is_heading:
        flush_chunk()
        out.append(line)
        in_table = False
    elif is_table_separator(line):
        if in_table:
            flush_chunk()
        in_table = True
        chunk_lines.append(line)
    elif in_table and is_new_table_header(line):
        flush_chunk()
        chunk_lines.append(line)
    else:
        m = has_md_link(line)
        if m and in_table:
            chunk_repos.append((m.group(1), m.group(2)))
        chunk_lines.append(line)

flush_chunk()

# 收集未匹配的 Pod（git 地址不在任何项目仓库列表中）
unmatched = []
for key, pods_list in pod_map.items():
    if key not in matched_urls:
        for pod_info in pods_list:
            unmatched.append({**pod_info, 'git': key})

if unmatched:
    out.append(render_unmatched_table(unmatched))

sys.stdout.writelines(out)
PYEOF

mv "$TMP" "$REPOS_MD"
echo "Updated: $REPOS_MD"
