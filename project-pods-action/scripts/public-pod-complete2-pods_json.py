#!/usr/bin/env python3
"""
public-pod-complete2-pods_json.py — 单条更新：从本地 podspec 解析数据并合并到 pods_all.json

适用场景: 更新单个 pod 的信息到已有的 pods_all.json（如修改了 podspec 后同步）
不适用:   全量获取应使用 pods_fetch_to_md.sh

用法:
  python3 public-pod-complete2-pods_json.py <本地podspec路径> <pods_all.json路径>

流程:
  1. pod ipc spec <文件> → 将 Ruby podspec 转为 JSON
  2. 解析 version / summary / git / subspecs / language（递归支持嵌套子库）
  3. 读取 pods_all.json，按 pod 名匹配 → upsert
  4. 写回 pods_all.json
"""

import json
import re
import sys
import subprocess


def fetch_spec(spec_path):
    """调用 pod ipc spec 将本地 podspec 转为 JSON"""
    try:
        result = subprocess.run(
            ['pod', 'ipc', 'spec', spec_path],
            capture_output=True, text=True, check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"❌ pod ipc spec {spec_path} 失败:\n{e.stderr}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"❌ 解析本地 podspec JSON 失败: {e}")
        sys.exit(1)


def extract_subspec_comments(spec_path):
    """从 .podspec 提取 subspec 上方的 # 注释，返回 {subspec_name: comment}"""
    with open(spec_path, encoding='utf-8', errors='ignore') as f:
        content = f.read()
    comments = {}
    for m in re.finditer(
        r'^\s*#\s*(.+?)\s*\n\s*s{1,2}\.subspec\s+[\'"]([^\'"]+)[\'"]\s+do',
        content, re.MULTILINE
    ):
        comments[m.group(2)] = m.group(1).strip()
    return comments


def parse_subspecs(subspecs_raw, subspec_comments=None):
    """将原始 subspecs 递归转为 {name, summary, source_files, resources, dependencies, subspecs?} 格式"""
    result = []
    for s in subspecs_raw:
        name = s.get('name', '')
        summary = s.get('summary', '')
        if not summary and subspec_comments:
            summary = subspec_comments.get(name, '')
        entry = {'name': name, 'summary': summary}
        source_files = s.get('source_files', '')
        if source_files:
            entry['source_files'] = source_files
        resources = s.get('resources', '')
        if resources:
            entry['resources'] = resources
        deps = s.get('dependencies', [])
        if deps:
            entry['dependencies'] = deps
        nested = s.get('subspecs', [])
        if nested:
            entry['subspecs'] = parse_subspecs(nested, subspec_comments)
        result.append(entry)
    return result


def detect_language(spec):
    """根据 swift_versions / swift_version 判断语言"""
    swift = spec.get('swift_versions', [])
    if isinstance(swift, list):
        if len(swift) > 0:
            return 'Swift'
    elif swift:
        return 'Swift'
    sv = spec.get('swift_version', '')
    if sv:
        return 'Swift'
    return 'OC'


def build_entry(spec, subspec_comments=None):
    """从 spec dict 构建 pods_all.json 条目，subspec summary 优先用注释补"""
    name = spec.get('name', '')
    version = spec.get('version', 'N/A')
    summary = spec.get('summary', '')
    git = spec.get('source', {}).get('git', 'N/A')
    subspecs_raw = spec.get('subspecs', [])
    subspecs = parse_subspecs(subspecs_raw, subspec_comments)
    language = detect_language(spec)

    return {
        'pod': name,
        'version': version,
        'git': git,
        'summary': summary,
        'source': 'CocoaPods',
        'visibility': '公有',
        'language': language,
        'subspec_count': len(subspecs),
        'subspecs': subspecs
    }


def merge_into_pods_json(pods_path, new_entry):
    """读取 pods_all.json，按 pod 名匹配，直接 upsert"""
    try:
        with open(pods_path, 'r', encoding='utf-8') as f:
            all_pods = json.load(f)
    except FileNotFoundError:
        print(f"⚠️ 文件不存在，将创建新文件: {pods_path}")
        all_pods = []
    except json.JSONDecodeError as e:
        print(f"❌ 解析 {pods_path} 失败: {e}")
        sys.exit(1)

    pod_name = new_entry['pod']
    found = False
    for i, entry in enumerate(all_pods):
        if entry.get('pod') == pod_name:
            all_pods[i] = new_entry
            print(f"✅ 更新 {pod_name} v{new_entry['version']}")
            found = True
            break

    if not found:
        all_pods.append(new_entry)
        print(f"✅ 新增 {pod_name} v{new_entry['version']}")

    all_pods.sort(key=lambda x: x.get('pod', ''))

    with open(pods_path, 'w', encoding='utf-8') as f:
        json.dump(all_pods, f, ensure_ascii=False, indent=2)

    print(f"📝 已写入 {len(all_pods)} 条到 {pods_path}")
    return new_entry


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    spec_path = sys.argv[1]
    pods_json_path = sys.argv[2]

    if not spec_path.endswith('.podspec'):
        print(f"❌ 参数不是 .podspec 文件: {spec_path}")
        print(__doc__)
        sys.exit(1)

    print(f"🔍 正在读取本地 podspec: {spec_path}")
    spec = fetch_spec(spec_path)
    print(f"  版本: {spec.get('version', 'N/A')}")
    print(f"  子库数: {len(spec.get('subspecs', []))}")

    comments = extract_subspec_comments(spec_path)
    entry = build_entry(spec, comments)
    merge_into_pods_json(pods_json_path, entry)


if __name__ == '__main__':
    main()
