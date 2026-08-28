#!/usr/bin/env bash
# 一键安装 Claude Code 全局配置（macOS / Linux）
# 用法：
#   ./install.sh              正常安装
#   ./install.sh --dry-run    预览变更，不实际操作
#   ./install.sh --help       查看帮助

set -euo pipefail

# 源目录 = 脚本所在目录（不依赖调用时的 cwd）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude"
MAX_BACKUPS=3
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
DRY_RUN=false

# 颜色（仅当输出到终端时启用）
if [[ -t 1 ]]; then
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_RED='\033[0;31m'
    C_RESET='\033[0m'
else
    C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

log_info()  { printf "${C_GREEN}[OK]${C_RESET} %s\n" "$1"; }
log_warn()  { printf "${C_YELLOW}[WARN]${C_RESET} %s\n" "$1"; }
log_error() { printf "${C_RED}[ERROR]${C_RESET} %s\n" "$1" >&2; }

show_help() {
    cat <<EOF
用法：./install.sh [选项]

选项：
  --dry-run    预览将要执行的操作，不实际修改文件
  -h, --help   显示本帮助

说明：
  - 源目录：脚本所在目录（包含 CLAUDE.md 和 rules/）
  - 目标目录：\${HOME}/.claude
  - 已存在的目标文件会自动备份为 *.bak.<时间戳>，最多保留最近 ${MAX_BACKUPS} 个备份
EOF
}

# 解析参数
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help) show_help; exit 0 ;;
        *) log_error "未知参数：$arg"; show_help; exit 1 ;;
    esac
done

run_cmd() {
    # 干跑模式下只打印命令，不执行
    if [[ "$DRY_RUN" == true ]]; then
        printf "  [DRY-RUN] %s\n" "$*"
    else
        "$@"
    fi
}

# 备份已存在的文件，保留最近 N 个同名备份
backup_if_exists() {
    local file="$1"
    if [[ -e "$file" ]]; then
        local bak="${file}.bak.${TIMESTAMP}"
        log_warn "已存在：$file（备份为 $(basename "$bak")）"
        run_cmd mv "$file" "$bak"
        # 清理超出数量限制的旧备份
        if [[ "$DRY_RUN" == false ]]; then
            local old_backups
            old_backups=$(ls -1t "${file}.bak."* 2>/dev/null | tail -n +$((MAX_BACKUPS + 1)) || true)
            if [[ -n "$old_backups" ]]; then
                echo "$old_backups" | while read -r old; do
                    [[ -n "$old" ]] && rm -f "$old" && log_info "清理旧备份：$(basename "$old")"
                done
            fi
        fi
    fi
}

# 复制单个文件（先备份再覆盖）
install_file() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
        log_error "源文件不存在：$src"
        exit 1
    fi
    backup_if_exists "$dst"
    log_info "安装：$dst"
    run_cmd cp "$src" "$dst"
}

# 复制整个目录（先备份再覆盖）
install_dir() {
    local src="$1" dst="$2"
    if [[ ! -d "$src" ]]; then
        log_error "源目录不存在：$src"
        exit 1
    fi
    backup_if_exists "$dst"
    log_info "安装目录：$dst"
    run_cmd mkdir -p "$dst"
    # 复制目录内容（保留子目录结构）
    run_cmd cp -r "$src"/. "$dst"/
}

main() {
    echo "Claude Code 全局配置安装器"
    echo "  源目录：$SCRIPT_DIR"
    echo "  目标目录：$TARGET_DIR"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  模式：干跑（不实际修改文件）"
    fi
    echo

    # 前置检查
    if [[ ! -f "$SCRIPT_DIR/CLAUDE.md" ]]; then
        log_error "源目录缺少 CLAUDE.md，请确认脚本与 CLAUDE.md 同目录"
        exit 1
    fi
    if [[ ! -d "$SCRIPT_DIR/rules" ]]; then
        log_error "源目录缺少 rules/，请确认脚本与 rules/ 同目录"
        exit 1
    fi

    # 创建目标根目录
    run_cmd mkdir -p "$TARGET_DIR"

    # 安装 CLAUDE.md
    install_file "$SCRIPT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

    # 安装 rules 目录
    install_dir "$SCRIPT_DIR/rules" "$TARGET_DIR/rules"

    echo
    log_info "安装完成"
    echo
    echo "后续步骤："
    echo "  1. 重启 Claude Code"
    echo "  2. 在任意 C# 项目中提问验证，例如："
    echo "       告诉我本项目的代码注释规范有哪些禁止项？"
    echo "     如果 Claude 能答出「禁止版本号、装饰符号、元信息」等内容，说明已生效"
    echo
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "本次为干跑模式，未实际修改任何文件"
    fi
}

main