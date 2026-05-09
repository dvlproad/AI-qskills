#!/bin/sh

OUT_BASE="${1:-github_pod_all}"
OUT_MD="${OUT_BASE}.md"
OUT_JSON="${OUT_BASE}.json"

PUBLIC_LIST=$(mktemp)
PRIVATE_LIST=$(mktemp)

PUBLIC_SPECS=$(mktemp)

PODS=$(pod trunk me 2>/dev/null | awk '/Pods:/ {flag=1; next} flag && /^    - / {sub(/^    - /, ""); print} flag && /^  - / && !/^    - / {exit}')
[ -z "$PODS" ] && { echo "No pods found via 'pod trunk me'"; exit 1; }

echo "Found $(echo "$PODS" | wc -l | tr -d ' ') public pods"

echo "$PODS" > "$PUBLIC_LIST"

find "$HOME/.cocoapods/repos/trunk" -name '*.podspec.json' -maxdepth 7 2>/dev/null > "$PUBLIC_SPECS"
echo "Found $(wc -l < "$PUBLIC_SPECS" | tr -d ' ') public spec files in trunk"

find "$HOME/.cocoapods/repos/gitee-dvlproad-dvlproadspecs" -name '*.podspec' -maxdepth 3 2>/dev/null > "$PRIVATE_LIST"
echo "Found $(wc -l < "$PRIVATE_LIST" | tr -d ' ') private podspec files"

python3 - "$OUT_JSON" "$OUT_MD" "$PUBLIC_LIST" "$PUBLIC_SPECS" "$PRIVATE_LIST" << 'PYEOF'
import sys, json, os, re

out_json = sys.argv[1]
out_md = sys.argv[2]
public_list_path = sys.argv[3]
public_specs_path = sys.argv[4]
private_list_path = sys.argv[5]

# Parse public pod names
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
            swift = d.get('swift_versions', [])
            if isinstance(swift, list):
                has_swift = len(swift) > 0
            else:
                has_swift = bool(swift)
            if not has_swift:
                sv = d.get('swift_version', '')
                has_swift = bool(sv)
            language = 'Swift' if has_swift else 'OC'
            if fn not in public_specs or parse_version(ver) > parse_version(public_specs[fn]['version']):
                public_specs[fn] = {
                    'pod': fn,
                    'version': ver,
                    'git': git,
                    'summary': summary,
                    'source': 'CocoaPods',
                    'visibility': '公有',
                    'language': language
                }
        except:
            pass

# For pods not found in trunk, try cocoapods repo with targeted lookup
cocoapods_root = os.path.expanduser('~/.cocoapods/repos/cocoapods')
remaining = [n for n in public_pod_names if n not in public_specs]
if remaining and os.path.isdir(cocoapods_root):
    for name in remaining:
        pod_dir = os.path.join(cocoapods_root, name)
        if not os.path.isdir(pod_dir):
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
                    public_specs[name] = {
                        'pod': name,
                        'version': ver,
                        'git': git,
                        'summary': summary,
                        'source': 'CocoaPods',
                        'visibility': '公有',
                        'language': language
                    }
                    break
                except:
                    pass

# Parse private podspec files (.podspec Ruby format)
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
    return name, version, git, summary, language

private_raw = {}
with open(private_list_path) as f:
    for line in f:
        path = line.strip()
        if not path:
            continue
        result = parse_podspec(path)
        name, version, git, summary, language = result
        if not name or not version:
            continue
        if name not in private_raw or parse_version(version) > parse_version(private_raw[name][1]):
            private_raw[name] = (name, version, git, summary, language)

private_specs = {}
for name, (_, version, git, summary, language) in private_raw.items():
    private_specs[name] = {
        'pod': name,
        'version': version,
        'git': git,
        'summary': summary,
        'source': 'dvlproadSpecs',
        'visibility': '私有',
        'language': language
    }

# Merge: public takes precedence
public_names = set(public_specs.keys())
merged = list(public_specs.values())
for name, data in private_specs.items():
    if name not in public_names:
        merged.append(data)

merged.sort(key=lambda x: x['pod'])

# Output JSON
with open(out_json, 'w') as f:
    json.dump(merged, f, ensure_ascii=False, indent=2)

# Output MD
with open(out_md, 'w') as f:
    f.write('# GitHub Pod All\n\n')
    f.write('| Pod | Version | Git URL | Source | Visibility | Language |\n')
    f.write('| --- | ------- | ------- | ------ | ---------- | -------- |\n')
    for d in merged:
        pod = d['pod']
        ver = d['version']
        git = d['git']
        src = d['source']
        vis = d['visibility']
        lang = d['language']
        if git == 'N/A':
            f.write(f'| {pod} | {ver} | N/A | {src} | {vis} | {lang} |\n')
        else:
            repo = git.rstrip('/').split('/')[-1].replace('.git', '')
            f.write(f'| {pod} | {ver} | [{repo}]({git}) | {src} | {vis} | {lang} |\n')

print(f'Saved: {os.path.abspath(out_md)}')
print(f'Saved: {os.path.abspath(out_json)}')
print(f'Total: {len(merged)} pods (public: {len(public_specs)}, private: {len(private_specs)}, merged: {len(merged)})')
PYEOF

rm "$PUBLIC_LIST" "$PUBLIC_SPECS" "$PRIVATE_LIST"
