#!/bin/sh

# GitHub API 操作脚本
# 用法: ./github_repos_all.sh [command] [options]
# 兼容 sh (非 bash 特有语法)

# 配置
TOKEN_FILE="${HOME}/Documents/.github_token"
SUMMARY_FILE="/tmp/github_repos_all.json"

# 清理临时文件（不删除汇总文件）
cleanup_temp() {
    rm -f /tmp/github_repos_page*.json /tmp/github_repos_user.json /tmp/github_repos_org*.json /tmp/github_repos_updated.json /tmp/github_repos_summary_tmp.json
}
# 组织列表（空格分隔的字符串）
ORGS="dvlproad dvlpCI dvlpCrack dvlpFork luckincoffee-app"

usage() {
    cat <<EOF
用法: $(basename $0) [command] [options]

命令:
    main             交互式主流程（推荐）
    token            配置 GitHub Token
    remove-token     删除保存的 Token 文件
    repos            获取仓库列表
    orgs             获取组织列表
    user             获取当前用户信息

环境变量:
    GITHUB_TOKEN  直接使用 GitHub Personal Access Token

Token 文件位置: ${HOME}/Documents/.github_token
不需要时请删除: $(basename $0) remove-token

示例:
    # 交互式主流程（推荐）
    ./github_repos_all.sh main

    # 直接获取仓库列表
    ./github_repos_all.sh repos dvlproad

    # 获取所有组织的仓库
    ./github_repos_all.sh repos --all-orgs

    # 删除保存的 Token
    ./github_repos_all.sh remove-token
EOF
    exit 1
}

echo_step() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

# 读取输入（兼容 sh）
prompt_input() {
    printf "%s" "$1"
    read -r val
    echo "$val"
}

# 静默读取密码（兼容 sh）
prompt_password() {
    printf "%s" "$1"
    stty -echo
    read -r val
    stty echo
    echo ""
    printf '%s' "$val"
}

get_github_token() {
    # 1. 优先使用环境变量
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN"
        return 0
    fi

    # 2. 尝试从 gh CLI 获取
    if command -v gh >/dev/null 2>&1; then
        gh_token=$(gh auth token 2>/dev/null || true)
        if [ -n "$gh_token" ]; then
            echo "$gh_token"
            return 0
        fi
    fi

    # 3. 尝试从 token 文件读取
    if [ -f "$TOKEN_FILE" ]; then
        cat "$TOKEN_FILE"
        return 0
    fi

    return 1
}

save_token() {
    token="$1"
    # 确保目录存在
    token_dir=$(dirname "$TOKEN_FILE")
    if [ ! -d "$token_dir" ]; then
        mkdir -p "$token_dir"
    fi
    echo "$token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "Token 已保存到: $TOKEN_FILE"
    echo "提示: 不需要时请删除此文件: rm $TOKEN_FILE"
}

remove_token() {
    if [ -f "$TOKEN_FILE" ]; then
        rm -f "$TOKEN_FILE"
        echo "Token 文件已删除: $TOKEN_FILE"
    else
        echo "Token 文件不存在"
    fi
}

cmd_token() {
    echo_step "配置 GitHub Token"

    # 先检查是否已有 token
    existing_token=$(get_github_token 2>/dev/null || true)
    if [ -n "$existing_token" ]; then
        masked="${existing_token%${existing_token#??????????}}"
        echo "已检测到 Token: ${masked}..."
        echo "是否重新输入? [y/N]: "
        read -r reinput
        case "$reinput" in
            y|Y|yes|YES) ;;
            *) echo "保持现有 Token"; return 0 ;;
        esac
    fi

    echo ""
    echo "获取 GitHub Personal Access Token:"
    echo "1. 访问: https://github.com/settings/tokens"
    echo "2. 点击 'Generate new token' 创建 token"
    echo "3. 权限需要: repo (私有仓库) 或 public_repo (仅公开仓库)"
    echo "4. 复制生成的 token 并粘贴到下方"
    echo "5. 输入 'quit' 或 'q' 退出"
    echo ""

    while true; do
        printf "GitHub Token (或 quit/q 退出): "
        read -r token_input

        case "$token_input" in
            quit|q|QUIT|Q)
                echo "已退出"
                return 1
                ;;
        esac

        if [ -z "$token_input" ]; then
            echo "错误: Token 不能为空，请重新输入"
            continue
        fi

        echo "正在验证 Token..."
        response=$(curl -s -w "\n%{http_code}" -H "Authorization: token $token_input" \
            "https://api.github.com/user")
        http_code=$(echo "$response" | tail -1)
        body=$(echo "$response" | sed '$d')
        
        # 检查 HTTP 状态码
        if [ "$http_code" != "200" ]; then
            echo "========================================"
            echo "Token 验证失败"
            echo "HTTP 状态码: $http_code"
            echo "错误详情:"
            if printf '%s' "$body" | jq '.' >/dev/null 2>&1; then
                printf '%s' "$body" | jq '.'
            else
                echo "$body"
            fi
            echo "========================================"
            echo ""
            continue
        fi
        
        # HTTP 200 即验证成功
        user_info=$(printf '%s' "$body" | jq -r '.login' 2>/dev/null || echo "unknown")
        echo "Token 验证成功! 用户: $user_info"
        save_token "$token_input"

        echo ""
        echo "后续使用:"
        echo "  export GITHUB_TOKEN=\$(cat $TOKEN_FILE)"
        echo "  ./github_repos_all.sh repos dvlproad"
        return 0
    done
    return 1
}

cmd_user() {
    token=$(get_github_token 2>/dev/null) || {
        echo "错误: 未找到 GitHub Token"
        echo "请先运行: $(basename $0) token"
        exit 1
    }

    echo "获取用户信息..."
    curl -s -H "Authorization: token $token" \
        "https://api.github.com/user" | \
        jq '{login, name, email, public_repos, private_repos, total_private_repos}'
}

init_summary() {
    echo "[]" > "$SUMMARY_FILE"
}

add_to_summary() {
    json_file="$1"
    org_name="$2"

    if [ ! -f "$json_file" ]; then
        echo "警告: 文件不存在: $json_file" >&2
        return
    fi

    echo "正在将 $json_file 添加到汇总 (org: $org_name)..." >&2

    # 为仓库添加 org 字段，直接处理文件
    if ! jq --arg org "$org_name" 'if type == "array" then map(. + {org: $org}) else . end' "$json_file" > "/tmp/github_repos_updated.json"; then
        echo "错误: 无法处理 $json_file" >&2
        return
    fi

    # 合并到汇总文件
    if ! jq -s '.[0] + .[1]' "$SUMMARY_FILE" "/tmp/github_repos_updated.json" > "${SUMMARY_FILE}.tmp"; then
        echo "错误: 无法合并到汇总文件" >&2
        return
    fi

    mv "${SUMMARY_FILE}.tmp" "$SUMMARY_FILE"
    rm -f "/tmp/github_repos_updated.json"
    
    echo "已添加到汇总. 当前汇总文件大小: $(wc -c < "$SUMMARY_FILE") 字节" >&2
}

cmd_repos() {
    target="$1"
    all_orgs=false
    token=""

    # 解析参数
    if [ "$target" = "--all-orgs" ]; then
        all_orgs=true
        target=""
    fi

    token=$(get_github_token 2>/dev/null) || {
        echo "错误: 未找到 GitHub Token"
        echo "请先运行: $(basename $0) token"
        exit 1
    }

    # 获取用户自己的仓库
    if [ -z "$target" ] || [ "$target" = "dvlproad" ]; then
        echo_step "用户仓库 (dvlproad)"

        page=1
        all_user_repos="[]"
        while true; do
            echo "获取第 $page 页..."
            response=$(curl -s -w "\n%{http_code}" -H "Authorization: token $token" \
                "https://api.github.com/user/repos?per_page=100&page=$page&sort=updated&affiliation=owner")

            http_code=$(echo "$response" | tail -1)
            body=$(echo "$response" | sed '$d')

            if [ "$http_code" != "200" ]; then
                echo "请求失败，HTTP状态码: $http_code"
                printf '%s' "$body" | jq '.' 2>/dev/null || echo "$body"
                break
            fi

            count=$(printf '%s' "$body" | jq 'length')

            if [ "$count" = "0" ]; then
                echo "没有更多数据了"
                break
            fi

            printf '%s' "$body" > "/tmp/github_repos_page${page}.json"
            echo "第 $page 页: $count 条仓库"

            # 输出仓库列表
            printf '%s' "$body" | jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | ⭐\(.stargazers_count) | \(.description // "-")"'

            # 合并到用户仓库列表
            page_data=$(cat "/tmp/github_repos_page${page}.json")
            all_user_repos=$(echo "$all_user_repos" | jq --argjson new "$page_data" '. + $new')

            if [ "$count" -lt 100 ]; then
                break
            fi

            page=$((page + 1))
        done

        # 保存用户仓库并添加到汇总
        if [ "$all_user_repos" != "[]" ]; then
            echo "$all_user_repos" > "/tmp/github_repos_user.json"
            add_to_summary "/tmp/github_repos_user.json" "dvlproad"
            echo "用户仓库已保存到: /tmp/github_repos_user.json"
        fi
    fi

    # 获取组织仓库
    if [ "$all_orgs" = "true" ] || [ -n "$target" ]; then
        # 构建组织列表
        if [ -n "$target" ] && [ "$target" != "dvlproad" ]; then
            org_list="$target"
        else
            org_list="$ORGS"
        fi

        for org in $org_list; do
            # 跳过 dvlproad（用户仓库已处理）
            if [ "$org" = "dvlproad" ] && [ "$all_orgs" = "true" ]; then
                continue
            fi

            echo_step "组织仓库 ($org)"

            page=1
            all_org_repos="[]"
            while true; do
                echo "获取第 $page 页..."
                response=$(curl -s -w "\n%{http_code}" -H "Authorization: token $token" \
                    "https://api.github.com/orgs/$org/repos?per_page=100&page=$page&sort=updated")

                http_code=$(echo "$response" | tail -1)
                body=$(echo "$response" | sed '$d')

                if [ "$http_code" != "200" ]; then
                    echo "请求失败，HTTP状态码: $http_code (可能不是组织成员)"
                    break
                fi

                count=$(printf '%s' "$body" | jq 'length')

                if [ "$count" = "0" ]; then
                    echo "没有更多数据了"
                    break
                fi

                printf '%s' "$body" > "/tmp/github_repos_${org}_page${page}.json"
                echo "第 $page 页: $count 条仓库"

                printf '%s' "$body" | jq -r '.[] | "\(.full_name) | \(.language // "-") | \(.private | tostring) | ⭐\(.stargazers_count) | \(.description // "-")"'

                # 合并到组织仓库列表
                page_data=$(cat "/tmp/github_repos_${org}_page${page}.json")
                all_org_repos=$(echo "$all_org_repos" | jq --argjson new "$page_data" '. + $new')

                if [ "$count" -lt 100 ]; then
                    break
                fi

                page=$((page + 1))
            done

            # 保存组织仓库并添加到汇总
            if [ "$all_org_repos" != "[]" ]; then
                echo "$all_org_repos" > "/tmp/github_repos_${org}.json"
                add_to_summary "/tmp/github_repos_${org}.json" "$org"
                echo "组织 $org 仓库已保存到: /tmp/github_repos_${org}.json"
            fi
        done
    fi

    # 输出汇总信息
    echo_step "汇总完成"
    
    # 验证汇总文件
    if [ ! -f "$SUMMARY_FILE" ]; then
        echo "警告: 汇总文件不存在，正在创建空文件"
        echo "[]" > "$SUMMARY_FILE"
    fi
    
    total=$(cat "$SUMMARY_FILE" | jq 'length' 2>/dev/null || echo "0")
    echo "所有仓库汇总已保存到: $SUMMARY_FILE"
    echo "总计仓库数: $total"
    
    if [ "$total" -gt 0 ]; then
        # 按组织统计
        echo ""
        echo "按组织统计:"
        cat "$SUMMARY_FILE" | jq -r 'group_by(.org) | .[] | "\(.[0].org): \(length) 个仓库"' 2>/dev/null || true
        
        # 自动打开文件
        if command -v open >/dev/null 2>&1; then
            echo ""
            echo "正在打开汇总文件..."
            open "$SUMMARY_FILE"
        fi
    else
        echo "警告: 汇总文件中没有数据"
    fi
}

cmd_orgs() {
    username="$1"
    token=""

    token=$(get_github_token 2>/dev/null) || {
        echo "错误: 未找到 GitHub Token"
        echo "请先运行: $(basename $0) token"
        exit 1
    }

    if [ -z "$username" ]; then
        echo "获取当前用户的组织..."
        curl -s -H "Authorization: token $token" \
            "https://api.github.com/user/orgs" | \
            jq -r '.[] | "\(.login) | \(.description // "-")"'
    else
        echo "获取用户 $username 的组织..."
        curl -s -H "Authorization: token $token" \
            "https://api.github.com/users/$username/orgs" | \
            jq -r '.[] | "\(.login) | \(.description // "-")"'
    fi
}

cmd_main() {
    echo_step "GitHub 仓库管理"

    # 步骤 1: 获取 Token
    echo_step "步骤 1: 获取 Token"

    # 先尝试获取已有 token
    token=""
    token=$(get_github_token 2>/dev/null || true)

    # 如果没有 token，进入输入流程
    if [ -z "$token" ]; then
        echo "未找到 Token，需要手动输入"
        echo ""
        cmd_token
        # cmd_token 执行完后，重新读取 token
        if [ -f "$TOKEN_FILE" ]; then
            token=$(cat "$TOKEN_FILE")
        fi
    fi

    # 检查是否成功获取 token
    if [ -z "$token" ]; then
        echo "错误: 无法获取 Token"
        exit 1
    fi

    masked="${token%${token#??????????}}"
    echo "Token 已就绪: ${masked}..."

    # 步骤 2: 获取用户信息
    echo_step "步骤 2: 获取用户信息"

    user_login=$(curl -s -H "Authorization: token $token" \
        "https://api.github.com/user" | jq -r '.login // empty')

    if [ -z "$user_login" ]; then
        echo "错误: Token 无效"
        exit 1
    fi

    echo "当前用户: $user_login"
    echo ""

    # 步骤 3: 选择操作
    echo_step "步骤 3: 选择操作"

    echo "请选择要执行的操作:"
    echo "1. 获取所有仓库 (用户 + 组织)"
    echo "2. 仅获取用户仓库"
    echo "3. 仅获取组织仓库"
    echo "4. 查看组织列表"
    echo ""
    echo "选择 [1-4/q]: "
    read -r action

    case "$action" in
        1)
            cmd_repos --all-orgs
            ;;
        2)
            cmd_repos dvlproad
            ;;
        3)
            # 仅获取组织仓库（排除 dvlproad）
            for org in $ORGS; do
                if [ "$org" != "dvlproad" ]; then
                    cmd_repos "$org"
                fi
            done
            ;;
        4)
            cmd_orgs "$user_login"
            ;;
        q|Q)
            echo "已退出"
            exit 0
            ;;
        *)
            echo "无效选择"
            exit 1
            ;;
    esac

    echo_step "完成"
    echo "数据已保存到 /tmp/github_repos_*.json"
}

# 主命令处理
case "${1:-}" in
    main)
        cmd_main
        cleanup_temp
        ;;
    token)
        cmd_token
        ;;
    remove-token)
        remove_token
        ;;
    repos)
        cmd_repos "$2"
        cleanup_temp
        ;;
    orgs)
        cmd_orgs "$2"
        ;;
    user)
        cmd_user
        ;;
    *)
        usage
        ;;
esac
