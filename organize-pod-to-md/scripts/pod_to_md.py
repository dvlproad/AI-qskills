"""
Pod 数据渲染工具 — 可独立使用，也可被其他脚本 import

所有渲染函数统一接收 list[dict]，每条 dict 字段说明：

  pod             - Pod 名（必填）
  version         - 版本号（必填）
  summary         - 描述（必填）
  git             - Git 地址（overview/unmatched 用于生成链接）
  source          - 来源：CocoaPods / dvlproadSpecs（必填）
  visibility      - 可见性：公有 / 私有（必填）
  language        - 语言：OC / Swift（必填）
  repo_name       - 仓库名（project 模式必填）
  subspec_count   - 子库数（overview/project 必填）
  subspecs        - 子库列表，每项 {"name": "...", "summary": "..."}

用法:
  cat data.json | python3 pod_to_md.py --type overview      # 总览表 + 子库信息
  cat data.json | python3 pod_to_md.py --type project       # 项目内嵌 Pod 表
  cat data.json | python3 pod_to_md.py --type unmatched     # 未匹配 Pod 表
  python3 pod_to_md.py --help                               # 帮助信息

示例:
  # 生成总览页面（github_pod_all.json 每条已含 subspecs 字段）
  cat github_pod_all.json | python3 pod_to_md.py --type overview > result.md

  # 单个对象也支持（自动包成数组处理）
  echo '{"pod":"Test","version":"1.0","source":"CocoaPods","visibility":"公有","language":"OC","subspec_count":0,"subspecs":[]}' | python3 pod_to_md.py --type overview

  # 引用方式使用
  from pod_render import render_project_table
  result = render_project_table(pods)
"""

import argparse
import sys
import json

# 需要展示子库详情的 Pod 列表（不管子库数多少都展示，可被参数覆盖）
ALWAYS_SHOW_SUBSPECS = ['CJBaseHelper', 'CJBaseUtil', 'CJBaseUIKit']

# 子库数超过此值时自动展示详情（默认值，可被参数覆盖）
SUBSPEC_MIN_COUNT = 2


def should_show_detail(pod_name, subspec_count, subspec_min_count=None, always_show_subspecs=None):
    """判断是否需要展示该 Pod 的子库详情"""
    threshold = subspec_min_count if subspec_min_count is not None else SUBSPEC_MIN_COUNT
    pods_list = always_show_subspecs if always_show_subspecs is not None else ALWAYS_SHOW_SUBSPECS
    return pod_name in pods_list or subspec_count >= threshold


def _git_link(url):
    """生成 [仓库名](git_url) 格式的 markdown 链接，url 为 N/A 则直接返回 N/A"""
    if url == 'N/A':
        return 'N/A'
    repo = url.rstrip('/').split('/')[-1].replace('.git', '')
    return f'[{repo}]({url})'


def render_overview(pods, subspec_min_count=None, always_show_subspecs=None):
    """
    渲染总览页面（github_pod_all.md）
    pods: list[dict]，每项需含 pod/version/summary/git/source/visibility/language/subspec_count/subspecs
    subspec_min_count: 子库详情展示阈值，为 None 则使用 SUBSPEC_MIN_COUNT
    always_show_subspecs: 总是展示子库详情的 Pod 列表，为 None 则使用 ALWAYS_SHOW_SUBSPECS
    返回：完整 markdown 字符串（主表 + ## 📋 子库信息 尾部）
    """
    buf = ['# GitHub Pod All\n\n']
    buf.append('| Pod | # | Summary | Version | Git URL | Source | Visibility | Language |\n')
    buf.append('| --- | - | ------- | ------- | ------- | ------ | ---------- | -------- |\n')
    for d in pods:
        pod = d['pod']
        sc = d.get('subspec_count', 0)
        ver = d.get('version', 'N/A')
        git = d.get('git', 'N/A')
        summary = d.get('summary', '').replace('|', '\\|')
        src = d.get('source', '')
        vis = d.get('visibility', '')
        lang = d.get('language', '')
        sc_str = '-' if not sc else str(sc)
        buf.append(f'| {pod} | {sc_str} | {summary} | {ver} | {_git_link(git)} | {src} | {vis} | {lang} |\n')

    # 子库详情尾部：筛选需要展示的子库
    subspec_details = {}
    for d in pods:
        name = d['pod']
        subspecs = d.get('subspecs', [])
        if subspecs and should_show_detail(name, len(subspecs), subspec_min_count, always_show_subspecs):
            subspec_details[name] = subspecs
    if subspec_details:
        buf.append('\n## 📋 子库信息\n\n')
        for pod_name in sorted(subspec_details.keys()):
            ver = ''
            for d in pods:
                if d['pod'] == pod_name:
                    ver = d.get('version', '')
                    break
            buf.append(f'### {pod_name} ({ver})\n\n')
            buf.append('| Subspec | Summary |\n')
            buf.append('| ------- | ------- |\n')
            for s in subspec_details[pod_name]:
                esc = s.get('summary', '').replace('|', '\\|')
                buf.append(f'| {pod_name}/{s.get("name", "")} | {esc} |\n')
            buf.append('\n')

    return ''.join(buf)


def render_project_table(pods):
    """
    渲染项目列表内嵌的 Pod 表（📦 Pod 情况：）
    pods: list[dict]，每项需含 repo_name/pod/version/summary/source/visibility/language
    返回：表头 + 数据行 + 尾换行
    """
    buf = ['**📦 Pod 情况：**\n\n']
    buf.append('| 仓库名 | 开发的Pod | 描述 | 版本 | 来源 | 可见 | 语言 |\n')
    buf.append('|--------|-----------|------|------|------|--------|------|\n')
    for d in pods:
        repo_name = d.get('repo_name', '')
        pod = d['pod']
        ver = d.get('version', 'N/A')
        summary = d.get('summary', '').replace('|', '\\|')
        src = d.get('source', '')
        vis = d.get('visibility', '')
        lang = d.get('language', '')
        buf.append(f'| {repo_name} | {pod} | {summary} | {ver} | {src} | {vis} | {lang} |\n')
    buf.append('\n')
    return ''.join(buf)


def render_unmatched_table(pods):
    """
    渲染未匹配 Pod 表（## 未匹配的 Pod）
    pods: list[dict]，每项需含 pod/version/summary/git/source/visibility/language
    返回：标题 + 表头 + 数据行（按 pod 名排序）
    """
    buf = ['\n## 未匹配的 Pod\n\n']
    buf.append('| Pod | Summary | Version | Git URL | Source | Visibility | Language |\n')
    buf.append('| --- | ------- | ------- | ------- | ------ | ---------- | -------- |\n')
    for d in sorted(pods, key=lambda x: (x['pod'], x.get('git', ''))):
        pod = d['pod']
        ver = d.get('version', 'N/A')
        summary = d.get('summary', '').replace('|', '\\|')
        git = d.get('git', 'N/A')
        src = d.get('source', '')
        vis = d.get('visibility', '')
        lang = d.get('language', '')
        buf.append(f'| {pod} | {summary} | {ver} | {_git_link(git)} | {src} | {vis} | {lang} |\n')
    return ''.join(buf)


def render_subspec_inline(pods, separate_subspecs=False, subspec_min_count=None, always_show_subspecs=None):
    """
    渲染项目列表内联子库详情（📋 子库详情：）
    pods: list[dict]，每项需含 pod/subspec_count/subspecs
    separate_subspecs: True → 每个 pod 独立表头+分隔线；False → 共享一个表头
    subspec_min_count: 子库详情展示阈值，为 None 则使用 SUBSPEC_MIN_COUNT
    always_show_subspecs: 总是展示子库详情的 Pod 列表，为 None 则使用 ALWAYS_SHOW_SUBSPECS
    只有子库数 > subspec_min_count 或在 always_show_subspecs 列表中的才展示
    返回：表头 + 数据行，若无符合条件的子库则返回空字符串
    """
    buf = []
    main_header_written = False  # **📋 子库详情：** 是否已输出
    table_header_written = False  # | Subspec | Summary | 是否已输出
    for d in pods:
        pod = d['pod']
        subspecs = d.get('subspecs', [])
        if subspecs and should_show_detail(pod, len(subspecs), subspec_min_count, always_show_subspecs):
            if not main_header_written:
                buf.append('**📋 子库详情：**\n\n')
                main_header_written = True
            if separate_subspecs or not table_header_written:
                buf.append('| Subspec | Summary |\n')
                buf.append('| ------- | ------- |\n')
                table_header_written = True
            for s in subspecs:
                esc = s.get('summary', '').replace('|', '\\|')
                buf.append(f'| {pod}/{s.get("name", "")} | {esc} |\n')
            buf.append('\n')
    if main_header_written:
        buf.append('\n')
    return ''.join(buf)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Pod 数据渲染工具',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument('--type', choices=['overview', 'project', 'unmatched'],
                        help='渲染类型：overview(总览) / project(项目表) / unmatched(未匹配)')
    parser.add_argument('--subspec-min-count', type=int, default=2,
                        help='子库数至少为此值时展示详情，默认 2')
    parser.add_argument('--subspec-force-show', type=str, default=None,
                        help='强制展示子库详情的 Pod（逗号分隔），默认 CJBaseHelper,CJBaseUtil,CJBaseUIKit')
    args = parser.parse_args()

    if not args.type:
        parser.print_help()
        sys.exit(0)

    # 从 stdin 读取 JSON 数据
    data = json.load(sys.stdin)
    # 单对象自动包装为数组
    if isinstance(data, dict):
        data = [data]

    always_show_subspecs = args.subspec_force_show.split(',') if args.subspec_force_show else None

    if args.type == 'overview':
        sys.stdout.write(render_overview(data, subspec_min_count=args.subspec_min_count, always_show_subspecs=always_show_subspecs))
    elif args.type == 'project':
        sys.stdout.write(render_project_table(data))
    elif args.type == 'unmatched':
        sys.stdout.write(render_unmatched_table(data))
