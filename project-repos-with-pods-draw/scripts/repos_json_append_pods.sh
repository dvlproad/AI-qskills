#!/bin/sh
# repos_json_append_pods.sh — 合并 repos_all.json + pods_all.json → repos_with_pods.json
# 每个 repo 节点追加 pods 字段，顶层含 unmatched_pods 列表
# 面向数据：输出 JSON 中间格式，可供后续渲染 md/html 等
# 用法: sh repos_json_append_pods.sh --repos <repos_all.json> --pods <pods_all.json> --output <输出.json>

while [ $# -gt 0 ]; do
  case "$1" in
    --repos) REPOS_JSON="$2"; shift 2 ;;
    --pods)  POD_JSON="$2";   shift 2 ;;
    --output) OUT_JSON="$2";  shift 2 ;;
    *) echo "未知参数: $1"; exit 1 ;;
  esac
done

[ -z "$REPOS_JSON" ] && { echo "用法: sh repos_json_append_pods.sh --repos <repos_all.json> --pods <pods_all.json> --output <输出.json>"; exit 1; }
[ -z "$POD_JSON" ]    && { echo "用法: sh repos_json_append_pods.sh --repos <repos_all.json> --pods <pods_all.json> --output <输出.json>"; exit 1; }
[ -z "$OUT_JSON" ]    && { echo "用法: sh repos_json_append_pods.sh --repos <repos_all.json> --pods <pods_all.json> --output <输出.json>"; exit 1; }
[ ! -f "$REPOS_JSON" ] && { echo "文件不存在: $REPOS_JSON"; exit 1; }
[ ! -f "$POD_JSON" ]   && { echo "文件不存在: $POD_JSON"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp)

python3 - "$REPOS_JSON" "$POD_JSON" "$SCRIPT_DIR" > "$TMP" << 'PYEOF'
import json, sys
sys.path.insert(0, sys.argv[3])
from repo_find_pod import build_pod_map, find_pods_for_repo

with open(sys.argv[1]) as f:
    repos = json.load(f)

with open(sys.argv[2]) as f:
    pods = json.load(f)

pod_map = build_pod_map(pods)
matched_all_urls = set()

def has_url(node):
    return isinstance(node, dict) and 'url' in node and 'repo_name' in node

def attach_pods(node):
    """递归遍历树，对叶子节点附上 pods"""
    if has_url(node):
        matched, urls = find_pods_for_repo(node['url'], pod_map)
        matched_all_urls.update(urls)
        if matched:
            node = dict(node, pods=matched)
        return node

    if isinstance(node, list):
        return [attach_pods(item) for item in node]

    if isinstance(node, dict):
        out = {}
        for k, v in node.items():
            out[k] = attach_pods(v)
        return out

    return node

result = attach_pods(repos)

# 收集未匹配的 Pod
unmatched = []
for key, pods_list in pod_map.items():
    if key not in matched_all_urls:
        for pod_info in pods_list:
            unmatched.append({
                'git': key,
                'pod': pod_info['pod'],
                'version': pod_info['version'],
                'summary': pod_info['summary'],
                'source': pod_info['source'],
                'visibility': pod_info['visibility'],
                'language': pod_info['language'],
                'subspec_count': pod_info['subspec_count'],
                'subspecs': pod_info['subspecs'],
            })

result = {
    'repos': result,
    'unmatched_pods': unmatched,
}

sys.stdout.write(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
PYEOF

mv "$TMP" "$OUT_JSON"
echo "Updated: $OUT_JSON"
