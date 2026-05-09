#!/bin/sh
# pod_match2_repos.sh - 在每个有 pod 的 section 下按主表追加 Pod 情况表格
# 用法: sh pod_match2_repos.sh <项目列表.md> [pod数据.json]

REPOS_MD="${1}"
POD_JSON="${2:-$(pwd)/github_pod_all.json}"

[ -z "$REPOS_MD" ] && { echo "用法: sh pod_match2_repos.sh <项目列表.md> [pod数据.json]"; exit 1; }
[ ! -f "$REPOS_MD" ] && { echo "文件不存在: $REPOS_MD"; exit 1; }
[ ! -f "$POD_JSON" ] && { echo "文件不存在: $POD_JSON，请先运行 github_pod_all.sh"; exit 1; }

TMP=$(mktemp)
python3 - "$REPOS_MD" "$POD_JSON" > "$TMP" << 'PYEOF'
import json, re, sys

repos_md = sys.argv[1]
pod_json = sys.argv[2]

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
    pod_map[norm].append((
        p['pod'],
        p.get('version', 'N/A'),
        p.get('summary', ''),
        p.get('source', ''),
        p.get('visibility', ''),
        p.get('language', '')
    ))

def find_pods_for_repo(repo_url):
    norm = norm_url(repo_url)
    matched = pod_map.get(norm, [])
    if not matched:
        norm2 = re.sub(r'^https?://', '', norm)
        for key in pod_map:
            key2 = re.sub(r'^https?://', '', key)
            if norm2 == key2 or norm2 in key:
                matched = pod_map[key]
                break
    return matched

def is_pod_table_header(line):
    return '| 仓库名 | 开发的Pod |' in line

def is_table_separator(line):
    return bool(re.match(r'^\|\s*-{3,}', line))

with open(repos_md) as f:
    lines = f.readlines()

# Pre-process: parse old Pod tables to extract row order, then strip them
ordered_pods = {}  # repo_name -> [pod_name, ...] preserving user's order
clean_lines = []
i = 0
while i < len(lines):
    line = lines[i]
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
                        if repo_name not in ordered_pods:
                            ordered_pods[repo_name] = []
                        if pod_name not in ordered_pods[repo_name]:
                            ordered_pods[repo_name].append(pod_name)
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

    all_pods = []
    for repo_name, repo_url in chunk_repos:
        matched = find_pods_for_repo(repo_url)
        if repo_name in ordered_pods:
            existing = ordered_pods[repo_name]
            existing_set = set(existing)
            matched_dict = {m[0]: m for m in matched}
            ordered = []
            for name in existing:
                if name in matched_dict:
                    ordered.append(matched_dict[name])
            new_pods = [m for m in matched if m[0] not in existing_set]
            new_pods.sort(key=lambda x: x[0])
            ordered.extend(new_pods)
            for pod_info in ordered:
                all_pods.append((repo_name,) + pod_info)
        else:
            matched.sort(key=lambda x: x[0])
            for pod_info in matched:
                all_pods.append((repo_name,) + pod_info)

    out.extend(chunk_lines)

    if all_pods:
        out.append('**📦 Pod 情况：**\n\n')
        out.append('| 仓库名 | 开发的Pod | 描述 | 版本 | 来源 | 可见 | 语言 |\n')
        out.append('|--------|-----------|------|------|------|--------|------|\n')
        for row in all_pods:
            repo_name, pod, ver, summary, source, visibility, language = row
            esc_summary = summary.replace('|', '\\|')
            out.append(f'| {repo_name} | {pod} | {esc_summary} | {ver} | {source} | {visibility} | {language} |\n')
        out.append('\n')

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

sys.stdout.writelines(out)
PYEOF

mv "$TMP" "$REPOS_MD"
echo "Updated: $REPOS_MD"
