"""
repo_find_pod.py — 按 git URL 匹配 repo 和 pod

用法:
    from repo_find_pod import build_pod_map, find_pods_for_repo

    pod_map = build_pod_map(pods_all_json)
    pods, _ = find_pods_for_repo("https://github.com/dvlproad/CJUIKit", pod_map)

匹配规则:
1. 归一化（去掉 .git 后缀、末尾 /）
2. 精确匹配
3. 去掉协议前缀（https://）后匹配
4. 含匹配（归一化后 url 是 pod git 的子串）

被 repos_md_append_pods.sh 和 repos_json_append_pods.sh 共用。
"""

import re


def norm_url(url):
    u = url.rstrip('/')
    u = re.sub(r'\.git$', '', u)
    return u


def build_pod_map(pods):
    """从 pods_all.json 构建 git_url → [pod] 映射"""
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
    return pod_map


def find_pods_for_repo(repo_url, pod_map):
    """按 git URL 匹配 repo 对应的 pod，返回 (matched_pods, {matched_urls})"""
    matched_urls = set()
    norm = norm_url(repo_url)
    matched = pod_map.get(norm, [])
    if not matched:
        norm2 = re.sub(r'^https?://', '', norm)
        for key in pod_map:
            key2 = re.sub(r'^https?://', '', key)
            if norm2 == key2 or norm2 in key:
                matched = pod_map[key]
                matched_urls.add(key)
                return matched, matched_urls
    if matched:
        matched_urls.add(norm)
    return matched, matched_urls
