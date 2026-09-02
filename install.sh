#!/usr/bin/env bash
# Claude 与 Codex 全局规则安装器（macOS / Linux）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_BACKUPS=3
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
DRY_RUN=false
TARGET=""

if [[ -t 1 ]]; then
    C_GREEN='\033[0;32m'
    C_YELLOW='\033[0;33m'
    C_RED='\033[0;31m'
    C_RESET='\033[0m'
else
    C_GREEN=''; C_YELLOW=''; C_RED=''; C_RESET=''
fi

log_info() { printf '%b[OK]%b %s\n' "$C_GREEN" "$C_RESET" "$1"; }
log_warn() { printf '%b[WARN]%b %s\n' "$C_YELLOW" "$C_RESET" "$1"; }
log_error() { printf '%b[ERROR]%b %s\n' "$C_RED" "$C_RESET" "$1" >&2; }

show_help() {
    cat <<EOF
用法：./install.sh [--target claude|codex|all] [--dry-run]

选项：
  --target    安装目标。claude 写入 ~/.claude，codex 写入 ~/.codex。
  --dry-run   预览操作，不修改文件。
  -h, --help  显示本帮助。

未指定 --target 时，交互式终端会要求选择目标；非交互环境必须指定 --target。
已有入口文件和 rules 目录会备份为 *.bak.<时间戳>，最多保留最近 3 份。
EOF
}

while (($# > 0)); do
    case "$1" in
        --target)
            [[ $# -ge 2 ]] || { log_error "--target 缺少参数"; exit 1; }
            TARGET="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "未知参数：$1"
            show_help
            exit 1
            ;;
    esac
done

resolve_target() {
    if [[ -n "$TARGET" ]]; then
        return
    fi
    if [[ ! -t 0 ]]; then
        log_error "非交互环境必须通过 --target 指定 claude、codex 或 all。"
        exit 1
    fi
    echo "请选择安装目标："
    echo "  1. Claude"
    echo "  2. Codex"
    echo "  3. Claude 和 Codex"
    read -r -p "输入 1、2 或 3: " choice
    case "$choice" in
        1) TARGET="claude" ;;
        2) TARGET="codex" ;;
        3) TARGET="all" ;;
        *) log_error "无效选择，请重新执行并输入 1、2 或 3。"; exit 1 ;;
    esac
}

validate_target() {
    case "$TARGET" in
        claude|codex|all) ;;
        *) log_error "--target 只能是 claude、codex 或 all。"; exit 1 ;;
    esac
}

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        printf "  [DRY-RUN]"
        printf " %q" "$@"
        printf "\n"
    else
        "$@"
    fi
}

backup_if_exists() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        return 0
    fi
    if [[ -d "$path" ]] && [[ -z "$(ls -A "$path" 2>/dev/null)" ]]; then
        return 0
    fi

    local backup_path="$path.bak.$TIMESTAMP"
    local sequence=1
    while [[ -e "$backup_path" ]]; do
        backup_path="$path.bak.$TIMESTAMP.$sequence"
        sequence=$((sequence + 1))
    done
    log_warn "已存在：$path（备份为 $(basename "$backup_path")）"
    run_cmd mv "$path" "$backup_path" || return 1
    if [[ "$DRY_RUN" == false ]]; then
        local backup_count=0
        local backup
        while IFS= read -r backup; do
            backup_count=$((backup_count + 1))
            if ((backup_count > MAX_BACKUPS)); then
                rm -rf "$backup"
                log_info "清理旧备份：$(basename "$backup")"
            fi
        done < <(find "$(dirname "$path")" -maxdepth 1 -name "$(basename "$path").bak.*" -print | sort -r)
    fi
}

install_file() {
    local source="$1"
    local destination="$2"
    run_cmd mkdir -p "$(dirname "$destination")" || return 1
    backup_if_exists "$destination" || return 1
    log_info "安装：$destination"
    run_cmd cp "$source" "$destination" || return 1
}

install_directory() {
    local source="$1"
    local destination="$2"
    run_cmd mkdir -p "$(dirname "$destination")" || return 1
    backup_if_exists "$destination" || return 1
    log_info "安装目录：$destination"
    if [[ -e "$destination" ]]; then
        run_cmd rm -rf "$destination" || return 1
    fi
    run_cmd cp -R "$source" "$destination" || return 1
}

install_target() {
    local name="$1"
    local root entry
    case "$name" in
        claude) root="$HOME/.claude"; entry="CLAUDE.md" ;;
        codex) root="$HOME/.codex"; entry="AGENTS.md" ;;
        *) log_error "未知目标：$name"; return 1 ;;
    esac

    local source_entry="$SCRIPT_DIR/$entry"
    [[ -f "$source_entry" ]] || { log_error "源文件不存在：$source_entry"; return 1; }
    [[ -d "$SCRIPT_DIR/rules" ]] || { log_error "源目录不存在：$SCRIPT_DIR/rules"; return 1; }

    echo
    echo "安装目标：$name"
    echo "  规则入口：$root/$entry"
    echo "  详细规则：$root/rules"
    install_file "$source_entry" "$root/$entry" || return 1
    install_directory "$SCRIPT_DIR/rules" "$root/rules" || return 1
}

resolve_target
validate_target

echo "Claude 与 Codex 全局规则安装器"
echo "  源目录：$SCRIPT_DIR"
echo "  目标：$TARGET"
[[ "$DRY_RUN" == true ]] && echo "  模式：干跑"

if [[ "$TARGET" == all ]]; then
    names="claude codex"
else
    names="$TARGET"
fi

failures=""
for name in $names; do
    if ! install_target "$name"; then
        log_error "$name 安装失败。"
        failures="$failures $name"
    fi
done

echo
if [[ -n "$failures" ]]; then
    log_error "安装未完全成功，失败目标：$failures"
    exit 1
fi

log_info "安装完成。重启所选工具后即可生效。"
[[ "$DRY_RUN" == true ]] && log_warn "本次为干跑模式，未实际修改文件。"
