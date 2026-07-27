#!/bin/bash
#
# catalog_merge_ratings.sh（参数化版本）
# 将 rating_*.json 合并到 catalog.json，输出 catalog_with_ratings.json
#
# 用法:
#   ./catalog_merge_ratings.sh --catalog <catalog.json> --output <catalog_with_ratings.json> --json <rating文件...>
#
# 示例:
#   ./catalog_merge_ratings.sh \
#     --catalog /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/catalog.json \
#     --output /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/catalog_with_ratings.json \
#     --json /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/rating_iOS.json \
#            /Users/qian/Project/dvlproadHexo/source/_posts/总目录/data/rating_Flutter.json
#
# 输出: catalog_with_ratings.json
#   每条文章增加 rating (总分) 和 scores (各维度分) 字段
#   未匹配到的文章保持原样（无 rating 字段）
#
# 依赖: jq (https://stedolan.github.io/jq/)
#
# 匹配优先级:
#   1. catalog.url === rating.path (去掉 .md)
#   2. catalog.title 在手动映射表中找到对应 rating.title
#   3. catalog.title === rating.title（限同一顶级分类）

set -euo pipefail

# -- 手动映射表 ------------------------------------------------
# 当 catalog 的 URL / title 与评分文件中的 path / title 不一致时，
# 在此添加映射: catalog_title → rating_title
MANUAL_MAP='{
  "架构模式-②MVC与MVVM": "架构模式-④MVC与MVVM",
  "架构模式-③组件化": "框架设计模式-⑦组件化",
  "设计模式-④适配器、策略、责任链模式(Adapter、Strategy、Chain of Responsibility)": "设计模式-④适配器、策略、责任链模式",
  "编程范式-面向协议(POP)": "编程思想-面向协议",
  "定位位置权限": "定位权限",
  "性能监控：卡顿监控": "性能监控-①卡顿监控",
  "性能优化：搜索优化": "搜索优化"
}'
# -------------------------------------------------------------

# 解析参数
CATALOG=""
OUTPUT=""
RATING_FILES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --catalog)
      CATALOG="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --json)
      shift
      while [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; do
        RATING_FILES+=("$1")
        shift
      done
      ;;
    -h|--help)
      echo "用法: $0 --catalog <catalog.json> --output <catalog_with_ratings.json> --json <rating文件...>"
      echo ""
      echo "参数:"
      echo "  --catalog    catalog.json 输入路径（必需）"
      echo "  --output     catalog_with_ratings.json 输出路径（必需）"
      echo "  --json       评分文件路径（可多个，空格分隔）"
      exit 0
      ;;
    *)
      echo "❌ 未知参数: $1" >&2
      echo "用法: $0 --catalog <catalog.json> --output <catalog_with_ratings.json> --json <rating文件...>" >&2
      exit 1
      ;;
  esac
done

# 验证必需参数
if [ -z "$CATALOG" ]; then
  echo "错误: 缺少 --catalog 参数" >&2
  exit 1
fi

if [ -z "$OUTPUT" ]; then
  echo "错误: 缺少 --output 参数" >&2
  exit 1
fi

if [ ${#RATING_FILES[@]} -eq 0 ]; then
  echo "错误: 缺少 --json 参数" >&2
  exit 1
fi

# 验证文件存在
if [ ! -f "$CATALOG" ]; then
  echo "❌ 未找到 catalog: $CATALOG" >&2
  exit 1
fi

for f in "${RATING_FILES[@]}"; do
  if [ ! -f "$f" ]; then
    echo "❌ 评分文件不存在: $f" >&2
    exit 1
  fi
done

echo "📄 catalog: $CATALOG"
echo "📊 rating:  ${#RATING_FILES[@]} 个文件"
for f in "${RATING_FILES[@]}"; do
  echo "    - $f"
done
echo "📝 output:  $OUTPUT"
echo ""

jq -s --argjson manual "$MANUAL_MAP" '
  # 第一个输入是 catalog，其余是评分文件（格式: {"rating_version":"...","ratings":[...]}）

  # 构建大分类元数据映射：取首篇文章 path 的第一段 → 分类名，关联版本信息
  ([
    .[1:] | .[] | select(.ratings | length > 0) |
    {key: (.ratings[0].path / "/")[0],
     value: {rating_version: .rating_version, rating_rated_at: .rating_rated_at, rating_standard: .rating_standard, rating_standard_version: .rating_standard_version}}
  ] | from_entries) as $meta_map |

  # 合并所有评分数据
  (.[1:] | map(.ratings) | add) as $all_ratings |

  # 按 path 去后缀建索引
  ($all_ratings | map({key: .path | rtrimstr(".md"), value: .}) | from_entries) as $by_url |

  # 按 title 建索引
  ($all_ratings | map({key: .title, value: .}) | from_entries) as $by_title |

  # 递归遍历 catalog
  {catalog: (.[0].catalog | walk(
    if type == "object" then
      if has("url") then
        # 文章级：匹配 rating 注入（跳过无 title 的条目）
        (if has("title") then
          $by_url[.url] //                                    # 1. URL 精确匹配
          $by_title[$manual[.title] // ""] //                  # 2. 手动映射
          ($by_title[.title] // null) as $t |                  # 3. title 匹配（限同分类）
          if $t and (.url / "/")[0] == ($t.path / "/")[0] then $t else null end
        else
          $by_url[.url]                                      # 无 title 时只走 URL 匹配
        end) as $match |
        if $match then
          . + {rating: $match.total, scores: $match.scores}
        else .
        end
      elif has("type") and has("children") and $meta_map[.type] then
        # 大分类：注入评分元数据（type → rating_* → 其余字段）
        {type} + $meta_map[.type] + (del(.type))
      else .
      end
    else .
    end
  ))}
' "$CATALOG" "${RATING_FILES[@]}" > "$OUTPUT"

echo "✅ 已写入 $OUTPUT"
