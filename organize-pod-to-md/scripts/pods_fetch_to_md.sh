#!/bin/sh
# pods_fetch_to_md.sh — 采集指定 CocoaPods repo 的 Pod 数据，可顺便输出 JSON/Markdown
#
# 主职是采集（从 trunk、CDN 缓存、私有 specs 获取 pod 数据并去重合并），
# 输出 Markdown 时底层调用 pod_to_md.py 渲染。

# 用法:
#   sh pods_fetch_to_md.sh --repos <repo1,repo2,...> --json path [--md path]
#   sh pods_fetch_to_md.sh --repos <repo1,repo2,...> --md path [--json path]
#
# 必传参数:
#   --repos  逗号分隔的 CocoaPods repo 目录名
#            trunk/cocoapods → 公有（CocoaPods）
#            其他 → 私有（从目录名最后一段推导来源标记）
#
# 可选参数（至少指定一个）:
#   --json   输出 JSON 路径（相对于当前工作目录）
#   --md     输出 Markdown 路径（相对于当前工作目录）
#            --json 和 --md 各自独立，不自动推导
#
# 数据源:
#   公有 - pod trunk me + trunk CDN 缓存 + cocoapods Specs 兜底（需 --repos 包含 cocoapods）
#   私有 - ~/.cocoapods/repos/<目录名> 下的 .podspec 文件
#
# 示例:
#   sh pods_fetch_to_md.sh --repos trunk --json pods.json                 # 输出到当前目录
#   sh pods_fetch_to_md.sh --repos trunk --json ../output/pods.json       # 相对路径
#   sh pods_fetch_to_md.sh --repos trunk --json /tmp/pods.json            # 绝对路径（目录必须存在）
#   sh pods_fetch_to_md.sh --repos trunk,dvlproad --json data.json --md pods.md  # 同时输出 JSON 和 MD

REPOS=""
OUT_JSON=""
OUT_MD=""

while [ $# -gt 0 ]; do
    case "$1" in
        --repos) REPOS="$2"; shift 2 ;;
        --json)  OUT_JSON="$2"; shift 2 ;;
        --md)    OUT_MD="$2";   shift 2 ;;
        --help|-h)
            echo "用法: sh pods_fetch_to_md.sh --repos <repo1,repo2,...> (--json path | --md path | both)"
            echo ""
            echo "必传参数:"
            echo "  --repos  逗号分隔的 CocoaPods repo 目录名"
            echo "           如: trunk,dvlproad,gitee-dvlproad-dvlproadspecs"
            echo ""
            echo "可选参数（至少指定一个）:"
            echo "  --json   输出 JSON 路径（相对于当前工作目录）"
            echo "  --md     输出 Markdown 路径（相对于当前工作目录）"
            echo "           --json 和 --md 各自独立，不自动推导"
            echo ""
            echo "示例:"
            echo "  sh pods_fetch_to_md.sh --repos trunk --json pods.json                 # 当前目录"
            echo "  sh pods_fetch_to_md.sh --repos trunk --json ../output/pods.json       # 相对路径"
            echo "  sh pods_fetch_to_md.sh --repos trunk --json /tmp/pods.json            # 绝对路径（目录必须存在）"
            echo "  sh pods_fetch_to_md.sh --repos trunk,dvlproad --json data.json --md report.md  # 同时输出 JSON 和 MD"
            exit 0 ;;
        *) echo "未知参数: $1 (使用 --help 查看帮助)"; exit 1 ;;
    esac
done

[ -z "$REPOS" ] && { echo "错误: --repos 是必传参数"; exit 1; }

# 至少指定 --json 或 --md 之一
if [ -z "$OUT_JSON" ] && [ -z "$OUT_MD" ]; then
    echo "错误: 至少指定 --json 或 --md 之一"
    exit 1
fi

validate_path() {
    local dir
    dir=$(dirname "$1")
    [ "$dir" = "." ] && return 0
    [ -d "$dir" ] && return 0
    echo "错误: 目录 '$dir' 不存在"
    exit 1
}
[ -n "$OUT_JSON" ] && validate_path "$OUT_JSON"
[ -n "$OUT_MD" ] && validate_path "$OUT_MD"

PUBLIC_LIST=$(mktemp)
PRIVATE_LIST=$(mktemp)
PUBLIC_SPECS=$(mktemp)

# 始终从 pod trunk me 获取公有 Pod 名（属于我的 pod）
PODS=$(pod trunk me 2>/dev/null | awk '/Pods:/ {flag=1; next} flag && /^    - / {sub(/^    - /, ""); print} flag && /^  - / && !/^    - / {exit}')
[ -z "$PODS" ] && { echo "No pods found via 'pod trunk me'"; exit 1; }
echo "Found $(echo "$PODS" | wc -l | tr -d ' ') public pods (pod trunk me)"
echo "$PODS" > "$PUBLIC_LIST"

# 按 repo 类型构建文件列表
use_cocoapods_fallback=false
OLD_IFS="$IFS"; IFS=','
for repo in $REPOS; do
    repo_dir="$HOME/.cocoapods/repos/$repo"
    [ -d "$repo_dir" ] || { echo "警告: repo 目录不存在: $repo_dir"; continue; }

    case "$repo" in
        trunk|cocoapods)
            # 公有 repo：扫描 .podspec.json，供 Python 按 pod name 过滤
            find "$repo_dir" -name '*.podspec.json' -maxdepth 7 2>/dev/null >> "$PUBLIC_SPECS"
            [ "$repo" = "cocoapods" ] && use_cocoapods_fallback=true
            ;;
        *)
            # 私有 repo：扫描所有 .podspec（Ruby 格式）
            find "$repo_dir" -name '*.podspec' -maxdepth 3 2>/dev/null >> "$PRIVATE_LIST"
            ;;
    esac
done
IFS="$OLD_IFS"

echo "Found $(wc -l < "$PUBLIC_SPECS" | tr -d ' ') public spec files"
echo "Found $(wc -l < "$PRIVATE_LIST" | tr -d ' ') private podspec files"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 - "$OUT_JSON" "$OUT_MD" "$PUBLIC_LIST" "$PUBLIC_SPECS" "$PRIVATE_LIST" "$SCRIPT_DIR" "$use_cocoapods_fallback" << 'PYEOF'
# ---------- Python 数据采集 + 渲染 ----------
import sys, json, os, re
sys.path.insert(0, sys.argv[6])  # 添加 scripts 目录到 Python 路径
from pod_to_md import render_overview  # 渲染模块（独立可用的库）

out_json = sys.argv[1]
out_md = sys.argv[2]
public_list_path = sys.argv[3]
public_specs_path = sys.argv[4]
private_list_path = sys.argv[5]
use_fallback = sys.argv[7] == 'true'  # 是否启用 cocoapods Specs 兜底搜索

# 读取公有 Pod 名称列表（从 pod trunk me 输出）
public_pod_names = set()
with open(public_list_path) as f:
    for line in f:
        public_pod_names.add(line.strip())

# Parse public pod spec files
def parse_version(v):
    try:
        parts = v.split('.')
        return tuple(int(x) for x in parts)
    except:
        return (0,)

# 读取公有 Pod spec 文件（本地 trunk CDN 缓存）
# trunk CDN 包含下过 pod install 的 pod，非全部，所以后面有兜底
public_specs = {}
with open(public_specs_path) as f:
    for line in f:
        path = line.strip()
        if not path or not path.endswith('.podspec.json'):
            continue
        fn = os.path.basename(path).replace('.podspec.json', '')
        if fn not in public_pod_names:
            continue
        try:
            with open(path) as sf:
                d = json.load(sf)
            ver = d.get('version', 'N/A')
            git = d.get('source', {}).get('git', 'N/A')
            summary = d.get('summary', '')
            # 判断语言：有 swift_version/swift_versions 字段则标记为 Swift
            swift = d.get('swift_versions', [])
            if isinstance(swift, list):
                has_swift = len(swift) > 0
            else:
                has_swift = bool(swift)
            if not has_swift:
                sv = d.get('swift_version', '')
                has_swift = bool(sv)
            language = 'Swift' if has_swift else 'OC'
            # 取最高版本（同名 pod 可能有多个版本缓存）
            if fn not in public_specs or parse_version(ver) > parse_version(public_specs[fn]['version']):
                subspecs_list = d.get('subspecs', [])
                public_specs[fn] = {
                    'pod': fn,
                    'version': ver,
                    'git': git,
                    'summary': summary,
                    'source': 'CocoaPods',
                    'visibility': '公有',
                    'language': language,
                    'subspec_count': len(subspecs_list),
                    'subspecs': subspecs_list
                }
        except:
            pass

# `pod trunk me` 有该 pod 但本地 trunk CDN 缓存里没有
#（从未被任何项目的 pod install 拉取过，所以无缓存）。
# 兜底方案：去完整 git clone 的 cocoapods 仓库 Specs/ 里查找。
# 仅当 --repos 包含 cocoapods 时启用（由 use_fallback 控制）。
#
# 目录结构：
#   ~/.cocoapods/repos/cocoapods/Specs/{a}/{b}/{c}/{PodName}/
#   不是 ~/.cocoapods/repos/cocoapods/{PodName}/  ← 原代码走的路径，永远查不到
#
# 用 find -maxdepth 4 搜索（Specs/{a}/{b}/{c}/{PodName}/ 共 4 层）。
# depth 4 约有 ~10.6 万个 pod 目录，macOS 上每个 pod 约 ~0.2 秒。
remaining = [n for n in public_pod_names if n not in public_specs]
if remaining and use_fallback:
    cocoapods_specs = os.path.expanduser('~/.cocoapods/repos/cocoapods/Specs')
    for name in remaining:
        if not os.path.isdir(cocoapods_specs):
            break
        with os.popen(f'find {cocoapods_specs} -maxdepth 4 -type d -name "{name}" -print -quit') as pipe:
            pod_dir = pipe.read().strip()
        if not pod_dir:
            continue
        versions = sorted(
            [d for d in os.listdir(pod_dir) if os.path.isdir(os.path.join(pod_dir, d))],
            reverse=True
        )
        if not versions:
            continue
        for ver_dir in versions:
            spec_path = os.path.join(pod_dir, ver_dir, f'{name}.podspec.json')
            if os.path.exists(spec_path):
                try:
                    with open(spec_path) as sf:
                        d = json.load(sf)
                    ver = d.get('version', ver_dir)
                    git = d.get('source', {}).get('git', 'N/A')
                    summary = d.get('summary', '')
                    swift = d.get('swift_versions', [])
                    if isinstance(swift, list):
                        has_swift = len(swift) > 0
                    else:
                        has_swift = bool(swift)
                    if not has_swift:
                        sv = d.get('swift_version', '')
                        has_swift = bool(sv)
                    language = 'Swift' if has_swift else 'OC'
                    subspecs_list = d.get('subspecs', [])
                    public_specs[name] = {
                        'pod': name,
                        'version': ver,
                        'git': git,
                        'summary': summary,
                        'source': 'CocoaPods',
                        'visibility': '公有',
                        'language': language,
                        'subspec_count': len(subspecs_list),
                        'subspecs': subspecs_list
                    }
                    break
                except:
                    pass

# ---------- 来源标记推导 ----------
# 从 .podspec 文件路径提取 repo 名，返回 (source, visibility)
# trunk/cocoapods → CocoaPods/公有
# 其他 → 目录名 split('-')[-1] 去掉 specs 后 + Specs（如 gitee-dvlproad-dvlproadspecs → dvlproadSpecs）
def derive_source(path):
    m = re.search(r'/\.cocoapods/repos/([^/]+)/', path)
    if not m:
        return 'dvlproadSpecs', '私有'
    repo_name = m.group(1)
    if repo_name in ('trunk', 'cocoapods'):
        return 'CocoaPods', '公有'
    last_seg = repo_name.split('-')[-1]
    if last_seg.endswith('specs'):
        base = last_seg[:-5]
        source = base + 'Specs'
    else:
        source = last_seg
    return source, '私有'

# ---------- 私有库解析 ----------
# .podspec 是 Ruby 格式（非 JSON），用正则手动解析
def parse_podspec(path):
    with open(path, encoding='utf-8', errors='ignore') as f:
        content = f.read()
    content = re.sub(r'^\s*#.*$', '', content, flags=re.MULTILINE)
    m = re.search(r's\.name\s*=\s*["\'](.+?)["\']', content)
    name = m.group(1) if m else None
    m = re.search(r's\.version\s*=\s*["\'](.+?)["\']', content)
    version = m.group(1) if m else None
    m = re.search(r's\.summary\s*=\s*["\'](.*?)["\']', content)
    summary = m.group(1) if m else ''
    m = re.search(r':git\s*=>\s*["\'](.+?)["\']', content)
    git = m.group(1) if m else 'N/A'
    m = re.search(r's\.swift_version[s]?\s*=\s*["\'](.+?)["\']', content)
    language = 'Swift' if m else 'OC'
    # Parse subspecs from Ruby podspec
    subspecs = []
    for m in re.finditer(
        r"s{1,2}\.subspec\s+['\"]([^'\"]+)['\"]\s+do\s*(?:\|(.+?)\||)(.*?)end",
        content, re.DOTALL
    ):
        body_var = m.group(2)
        body = m.group(3)
        sm = re.search(rf'{re.escape(body_var)}\.summary\s*=\s*["\']([^"\']*)["\']', body) if body_var else None
        if not sm:
            sm = re.search(r'ss?\.summary\s*=\s*["\']([^"\']*)["\']', body)
        summary_sub = sm.group(1) if sm else ''
        subspecs.append({'name': m.group(1), 'summary': summary_sub})
    return name, version, git, summary, language, subspecs

private_raw = {}  # key: (pod_name, source) — 同名 pod 可能来自不同私有 repo
with open(private_list_path) as f:
    for line in f:
        path = line.strip()
        if not path:
            continue
        source, visibility = derive_source(path)
        result = parse_podspec(path)
        name, version, git, summary, language, subspecs = result
        if not name or not version:
            continue
        key = (name, source)
        if key not in private_raw or parse_version(version) > parse_version(private_raw[key]['version']):
            private_raw[key] = {
                'pod': name, 'version': version, 'git': git, 'summary': summary,
                'source': source, 'visibility': visibility, 'language': language,
                'subspec_count': len(subspecs), 'subspecs': subspecs,
            }

private_specs = {}
for key, data in private_raw.items():
    private_specs[key] = data

# ---------- 合并公有 + 私有，公有优先 ----------
# 同一 Pod 在公有和私有都存在时，标记为 CocoaPods / 公有
public_names = set(public_specs.keys())
merged = list(public_specs.values())
for key, data in private_specs.items():
    if data['pod'] not in public_names:
        merged.append(data)

merged.sort(key=lambda x: x['pod'])

# ---------- 输出 JSON（供 pod_match2_repos.sh / pod_to_md.py 使用）----------
if out_json:
    with open(out_json, 'w') as f:
        json.dump(merged, f, ensure_ascii=False, indent=2)
    print(f'Saved: {os.path.abspath(out_json)}')

# Output MD — render_overview 内部自行处理子库过滤与渲染
if out_md:
    with open(out_md, 'w') as f:
        f.write(render_overview(merged))
    print(f'Saved: {os.path.abspath(out_md)}')

print(f'Total: {len(merged)} pods (public: {len(public_specs)}, private: {len(private_specs)}, merged: {len(merged)})')
PYEOF

rm "$PUBLIC_LIST" "$PUBLIC_SPECS" "$PRIVATE_LIST"
