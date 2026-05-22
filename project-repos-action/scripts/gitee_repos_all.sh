#!/bin/bash

# Gitee API 操作脚本
# 用法: ./gitee_repos_all.sh [command] [options]

set -e

# 配置
CLIENT_ID="${GITEE_CLIENT_ID:-}"
CLIENT_SECRET="${GITEE_CLIENT_SECRET:-}"
REDIRECT_URI="${GITEE_REDIRECT_URI:-https://example.com/callback}"
TOKEN_FILE="${HOME}/.gitee_token"

usage() {
    cat <<EOF
用法: $(basename $0) [command] [options]

命令:
    main         交互式主流程（推荐）
    auth         开始 OAuth 授权流程
    token        使用授权码获取 token
    token-file   从文件加载 token
    repos       获取仓库列表
    orgs        获取组织列表

环境变量:
    GITEE_CLIENT_ID       OAuth 应用 Client ID
    GITEE_CLIENT_SECRET  OAuth 应用 Client Secret
    GITEE_REDIRECT_URI  Redirect URI
    GITEE_TOKEN        直接使用 token

示例:
    # 交互式主流程（推荐）
    ./gitee_repos_all.sh main
EOF
    exit 1
}

echo_step() {
    echo ""
    echo "========================================"
    echo "$1"
    echo "========================================"
}

prompt_yes() {
    local prompt="$1"
    local default="$2"
    local answer
    
    while true; do
        echo "$prompt [y/N/q]: "
        read -r answer
        answer="${answer:-$default}"
        
        case "$answer" in
            y|Y|yes|YES)
                echo "yes"
                return 0
                ;;
            n|N|no|NO)
                echo "no"
                return 0
                ;;
            q|QUIT)
                echo "quit"
                return 0
                ;;
            *)
                echo "请输入 y、n 或 q"
                ;;
        esac
    done
}

prompt_input() {
    local prompt="$1"
    local default="$2"
    local value=""
    
    while true; do
        if [[ -n "$default" ]]; then
            echo "$prompt [$default]: "
        else
            echo "$prompt: "
        fi
        read -r value
        value="${value:-$default}"
        
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    done
}

cmd_main() {
    echo_step "Gitee OAuth 授权流程"
    
    # ========== 步骤 0: 检查是否已有 Token ==========
    echo_step "步骤 0: 输入 Access Token"
    echo "如果已有 Access Token，请直接输入（输入 no 则进行 OAuth 授权）:"
    echo ""
    echo "Access Token: "
    read -r token_input
    
    if [[ -z "$token_input" ]]; then
        echo "已退出"
        exit 0
    fi
    
    if [[ "$token_input" == "no" ]] || [[ "$token_input" == "NO" ]]; then
        echo "继续 OAuth 授权流程..."
    else
        # 使用用户输入的 token，直接进入数据获取步骤
        access_token="$token_input"
        echo "$access_token" > "$TOKEN_FILE"
        chmod 600 "$TOKEN_FILE"
        echo "Token 已保存到: $TOKEN_FILE"
        
        # 直接进入仓库列表获取
        echo ""
        echo "请输入要查询的用户名 [留空则查询自己]: "
        read -r username_input
        username="${username_input:-}"
        echo "请输入每页数量 [50]: "
        read -r per_page_input
        per_page="${per_page_input:-50}"
        
        local api_url
        if [[ -z "$username" ]]; then
            echo "获取自己的仓库列表..."
            api_url="https://gitee.com/api/v5/user/repos"
        else
            echo "仓库列表 ($username):"
            api_url="https://gitee.com/api/v5/users/${username}/repos"
        fi
        
        local page=1
        while true; do
            local repos_data
            repos_data=$(curl -s -w "\n%{http_code}" -H "Authorization: token $access_token" \
                "${api_url}?per_page=${per_page}&page=$page")
            local http_code
            http_code=$(echo "$repos_data" | tail -1)
            local body
            body=$(echo "$repos_data" | sed '$d')
            echo "[DEBUG] HTTP状态码: $http_code" >&2
            if [[ "$http_code" != "200" ]]; then
                echo "请求失败，HTTP状态码: $http_code"
                printf '%s' "$body" > "/tmp/gitee_repos_page${page}.json"
                echo "数据已保存到: /tmp/gitee_repos_page${page}.json" >&2
                break
            fi
printf '%s' "$body" > "/tmp/gitee_repos_page${page}.json"
            echo "数据已保存到: /tmp/gitee_repos_page${page}.json" >&2
            echo "DEBUG: 计算count..." >&2
            local count
            local count_output
            count_output=$(printf '%s' "$body" | tr -d '\000-\037' | jq 'length' 2>&1) || count_output="0"
            if [[ "$count_output" == "0" ]] || [[ -z "$count_output" ]]; then
                count="0"
            else
                count="$count_output"
            fi
            echo "DEBUG: count=$count, per_page=$per_page" >&2
            if [[ "$count" == "0" ]]; then
                echo "没有更多数据了" || true
                break || true
            fi
            echo "DEBUG: 准备输出仓库列表..." >&2 || true
            local jq_output
            jq_output=$(printf '%s' "$body" | tr -d '\000-\037' | jq -r '.[] | "\(.full_name)[\(.language // "-")]"' 2>&1) || true
            echo "$jq_output" || true
            echo "DEBUG: 准备循环下一页, page=$page" >&2 || true
            page=$((page + 1)) || true
            echo "DEBUG: page now is $page" >&2 || true
            echo "DEBUG: 判断是否继续, count=$count, per_page=$per_page" >&2 || true
            if [[ "$count" -ge "$per_page" ]]; then
                echo "--- 第 $((page-1)) 页完成($count条)，继续获取下一页..." || true
            else
                echo "--- 第 $((page-1)) 页完成，继续获取下一页? [y/n]: "
                read -r continue_input
                continue_input="${continue_input:-y}"
                case "$continue_input" in
                    y|Y|yes|YES)
                        ;;
                    *)
                        break
                        ;;
                esac
            fi
        done
        echo "获取完成，共 $((page-1)) 页" || true
        
        # 合并所有JSON文件
        if [[ $page -gt 1 ]]; then
            local all_repos="[]"
            local first=true
            for ((i=1; i<page; i++)); do
                if [[ -f "/tmp/gitee_repos_page${i}.json" ]]; then
                    local page_data
                    page_data=$(cat "/tmp/gitee_repos_page${i}.json" | tr -d '\000-\037')
                    if [[ "$first" == "true" ]]; then
                        all_repos="$page_data"
                        first=false
                    else
                        all_repos=$(printf '%s\n%s' "$all_repos" "$page_data" | jq -s '.[0] + .[1]' 2>/dev/null) || all_repos="$all_repos"
                    fi
                fi
            done
            printf '%s' "$all_repos" > "/tmp/gitee_repos_all.json"
            echo "所有仓库数据已保存到: /tmp/gitee_repos_all.json"
            open "/tmp/gitee_repos_all.json"
        fi
        
        exit 0
    fi
    
    # ========== 步骤 1: 输入 Client ID ==========
    echo_step "步骤 1: 输入 Client ID"
    
    if [[ -n "$CLIENT_ID" ]]; then
        echo "Client ID [$CLIENT_ID]: "
        read -r client_id_input
        CLIENT_ID="${client_id_input:-$CLIENT_ID}"
    else
        cat <<'EOF'

首次使用? 请先在 https://gitee.com/oauth/applications 创建 OAuth 应用:

- 应用名称：任意（如 opencode）
- 应用主页：任意（如 https://example.com）
- Redirect URI：https://example.com/callback
- 权限：需要 projects 和 groups

创建完成后，输入上面的 Client ID:

EOF
        echo ""
        read -r CLIENT_ID
    fi
    
    echo ""
    
    # ========== 步骤 2: 输入 Redirect URI ==========
    echo_step "步骤 2: 输入 Redirect URI"
    
    if [[ -n "$REDIRECT_URI" ]] && [[ "$REDIRECT_URI" != "https://example.com/callback" ]]; then
        echo "Redirect URI [$REDIRECT_URI]: "
        read -r redirect_uri_input
        REDIRECT_URI="${redirect_uri_input:-$REDIRECT_URI}"
    else
        echo "Redirect URI [https://example.com/callback]: "
        read -r redirect_uri_input
        REDIRECT_URI="${redirect_uri_input:-https://example.com/callback}"
    fi
    
    # ========== 步骤 3: 确认信息 ==========
    echo_step "步骤 3: 确认"
    echo "Client ID: $CLIENT_ID"
    echo "Redirect URI: $REDIRECT_URI"
    echo ""
    
    local confirm
    echo "确认? [y/n/q]: "
    read -r confirm
    confirm="${confirm:-y}"
    
    case "$confirm" in
        y|Y|yes|YES)
            ;;
        n|N|no|NO)
            echo ""
            echo "请重新输入正确的信息"
            CLIENT_ID=""
            REDIRECT_URI=""
            exec "$0" main
            ;;
        q|Q|QUIT)
            echo "已退出"
            exit 0
            ;;
        *)
            echo "请输入 y、n 或 q"
            exec "$0" main
            ;;
    esac
    
    # ========== 步骤 4: 获取授权链接 ==========
    echo_step "步骤 4: 获取授权链接"
    
    local auth_url="https://gitee.com/oauth/authorize?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=projects+groups+user_info"
    echo "授权链接: $auth_url"
    echo ""
    
    local open_auth
    echo "是否在浏览器中打开此链接? [y/n/q]: "
    read -r open_auth
    open_auth="${open_auth:-y}"
    
    case "$open_auth" in
        y|Y|yes|YES)
            echo "正在打开..."
            open "$auth_url"
            ;;
        n|N|no|NO)
            ;;
        q|Q|QUIT)
            echo "已退出"
            exit 0
            ;;
    esac
    
# ========== 步骤 5: 输入授权码 ==========
    echo_step "步骤 5: 输入授权码"
    echo "授权后，浏览器会跳转到: ${REDIRECT_URI}?code=xxx"
    echo "请输入 URL 或 code 的值:"
    echo ""
    echo "Code: "
    read -r auth_code_input
    
    if [[ -z "$auth_code_input" ]]; then
        echo "错误: Code 不能为空"
        exit 1
    fi
    
    # 如果输入的是完整URL，提取code参数
    if [[ "$auth_code_input" == *"code="* ]]; then
        auth_code=$(echo "$auth_code_input" | sed -n 's/.*code=\([^&]*\).*/\1/p')
        echo "提取的 Code: $auth_code"
    else
        auth_code="$auth_code_input"
    fi
    
    # ========== 步骤 6: 输入 Client Secret ==========
    echo_step "步骤 6: 输入 Client Secret"
    echo "请输入 OAuth 应用的 Client Secret:"
    echo ""
    echo "Client Secret: "
    read -r -s client_secret_input
    echo ""
    
    if [[ -z "$client_secret_input" ]]; then
        echo "错误: Client Secret 不能为空"
        exit 1
    fi
    CLIENT_SECRET="$client_secret_input"
    
    # ========== 步骤 7: 获取 Access Token ==========
    echo_step "步骤 7: 获取 Access Token"
    echo "正在获取 token..."
    
    local response
    response=$(curl -s -X POST "https://gitee.com/oauth/token" \
        -d "grant_type=authorization_code" \
        -d "code=$auth_code" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "redirect_uri=$REDIRECT_URI")
    
    local access_token
    access_token=$(printf '%s' "$response" | jq -r '.access_token // empty')
    
    if [[ -z "$access_token" ]]; then
        echo "获取 token 失败，请检查以下信息:"
        echo "$response"
        echo ""
        echo "请重新输入 yes 重新获取，或 quit/q 退出: "
        read -r retry_input
        
        case "$retry_input" in
            y|Y|yes|YES)
                exec "$0" main
                ;;
            q|Q|QUIT)
                echo "已退出"
                exit 0
                ;;
            *)
                exec "$0" main
                ;;
        esac
    fi
    
    # 保存 token
    echo "$access_token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    
    echo "========================================"
    echo "获取 Token 成功！"
    echo "Token 已保存到: $TOKEN_FILE"
    echo "========================================"
    
    # ========== 步骤 8: 测试并获取数据 ==========
    echo_step "步骤 8: 测试获取仓库列表"
    
    local username
    echo "请输入要查询的用户名 [留空则查询自己]: "
    read -r username
    
    if [[ -z "$username" ]]; then
        echo "获取自己的仓库列表..."
        curl -s -H "Authorization: token $access_token" \
            "https://gitee.com/api/v5/user" | \
            jq -r '.login, .name, .email'
        echo ""
        echo "仓库列表:"
        curl -s -H "Authorization: token $access_token" \
            "https://gitee.com/api/v5/user/repos?per_page=200" | \
            jq '.' 2>/dev/null || true
    else
        echo "仓库列表 ($username):"
        curl -s -H "Authorization: token $access_token" \
            "https://gitee.com/api/v5/users/${username}/repos?per_page=200" | \
            jq '.' 2>/dev/null || true
    fi
    
    echo_step "完成"
    echo "后续使用:"
    echo "  export GITEE_TOKEN=\$(cat $TOKEN_FILE)"
    echo "  ./gitee_repos_all.sh repos dvlproad"
    echo "  ./gitee_repos_all.sh orgs dvlproad"
}

cmd_auth() {
    if [[ -z "$CLIENT_ID" ]]; then
        echo "错误: 请设置 GITEE_CLIENT_ID 环境变量"
        exit 1
    fi
    
    local auth_url="https://gitee.com/oauth/authorize?client_id=${CLIENT_ID}&redirect_uri=${REDIRECT_URI}&response_type=code&scope=projects+groups+user_info"
    echo "请访问以下链接授权:"
    echo "$auth_url"
    echo ""
    echo "授权后会跳转到: ${REDIRECT_URI}?code=xxx"
    echo "获取 code 后运行: $(basename $0) token <code>"
}

cmd_token() {
    local code="$1"
    if [[ -z "$code" ]]; then
        echo "错误: 缺少授权码"
        echo "用法: $(basename $0) token <authorization_code>"
        exit 1
    fi
    
    if [[ -z "$CLIENT_ID" ]] || [[ -z "$CLIENT_SECRET" ]]; then
        echo "错误: 请设置 GITEE_CLIENT_ID 和 GITEE_CLIENT_SECRET 环境变量"
        exit 1
    fi
    
    echo "正在获取 token..." >&2
    
    local response
    response=$(curl -s -X POST "https://gitee.com/oauth/token" \
        -d "grant_type=authorization_code" \
        -d "code=$code" \
        -d "client_id=$CLIENT_ID" \
        -d "client_secret=$CLIENT_SECRET" \
        -d "redirect_uri=$REDIRECT_URI")
    
    local access_token
    access_token=$(printf '%s' "$response" | jq -r '.access_token // empty')
    
    if [[ -z "$access_token" ]]; then
        echo "获取 token 失败: $response" >&2
        exit 1
    fi
    
    echo "$access_token" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    echo "Token 已保存到: $TOKEN_FILE"
    echo "$access_token"
}

cmd_token_file() {
    if [[ -f "$TOKEN_FILE" ]]; then
        cat "$TOKEN_FILE"
    else
        echo "错误: Token 文件不存在: $TOKEN_FILE" >&2
        exit 1
    fi
}

get_token() {
    if [[ -n "$GITEE_TOKEN" ]]; then
        echo "$GITEE_TOKEN"
    elif [[ -f "$TOKEN_FILE" ]]; then
        cat "$TOKEN_FILE"
    else
        echo "错误: 未设置 token" >&2
        exit 1
    fi
}

cmd_repos() {
    local username="${1:-}"
    local token
    token=$(get_token)
    
    if [[ -z "$username" ]]; then
        echo "错误: 请指定用户名"
        echo "用法: $(basename $0) repos <username>" >&2
        exit 1
    fi
    
    curl -s -H "Authorization: token $token" \
        "https://gitee.com/api/v5/users/${username}/repos?per_page=200" | \
        jq -r '.[] | "\(.full_name)[\(.language // "-")]"' 2>&1 || cat
}

cmd_orgs() {
    local username="${1:-}"
    local token
    token=$(get_token)
    
    if [[ -z "$username" ]]; then
        echo "错误: 请指定用户名"
        echo "用法: $(basename $0) orgs <username>" >&2
        exit 1
    fi
    
    curl -s -H "Authorization: token $token" \
        "https://gitee.com/api/v5/users/${username}/orgs" | \
        jq -r '.[] | "\(.login)[\(.description // "-")]"' 2>&1 || cat
}

# 主命令处理
case "${1:-}" in
    main)
        cmd_main
        ;;
    auth)
        cmd_auth
        ;;
    token)
        cmd_token "$2"
        ;;
    token-file)
        cmd_token_file
        ;;
    repos)
        cmd_repos "$2"
        ;;
    orgs)
        cmd_orgs "$2"
        ;;
    *)
        usage
        ;;
esac
