#!/usr/bin/env bash
# Claude 与 Codex 全局规则卸载器（macOS / Linux）

set -euo pipefail

DRY_RUN=false
PURGE=false
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
用法：./uninstall.sh [--target claude|codex|all] [--purge] [--dry-run]

选项：
  --target    卸载目标。未指定时在交互式终端中选择。
  --purge     删除本包入口、rules 和对应备份，不恢复旧配置。
  --dry-run   预览操作，不修改文件。
  -h, --help  显示本帮助。

默认行为恢复最近备份；没有备份时只删除本包安装的入口与 rules。
非交互环境必须指定 --target。
EOF
}

while (($# > 0)); do
    case "$1" in
        --target)
            [[ $# -ge 2 ]] || { log_error "--target 缺少参数"; exit 1; }
            TARGET="$2"
            shift 2
            ;;
        --purge)
            PURGE=true
            shift
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
    echo "请选择卸载目标："
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

remove_path() {
    local path="$1"
    if [[ -e "$path" ]]; then
        log_info "删除：$path"
        run_cmd rm -rf "$path" || return 1
    fi
}

restore_latest_backup() {
    local target_path="$1"
    local directory base latest
    directory="$(dirname "$target_path")"
    base="$(basename "$target_path")"
    latest="$(find "$directory" -maxdepth 1 -name "$base.bak.*" -print 2>/dev/null | sort -r | head -n 1 || true)"
    if [[ -z "$latest" ]]; then
        return 1
    fi
    log_info "恢复备份：$latest -> $target_path"
    if [[ -e "$target_path" ]]; then
        run_cmd rm -rf "$target_path" || return 1
    fi
    run_cmd mv "$latest" "$target_path" || return 1
}

remove_all_backups() {
    local target_path="$1"
    local directory base backup
    directory="$(dirname "$target_path")"
    base="$(basename "$target_path")"
    while IFS= read -r backup; do
        [[ -n "$backup" ]] || continue
        log_info "清理备份：$backup"
        run_cmd rm -rf "$backup" || return 1
    done < <(find "$directory" -maxdepth 1 -name "$base.bak.*" -print 2>/dev/null)
}

uninstall_target() {
    local name="$1"
    local root entry entry_path rules_path
    case "$name" in
        claude) root="$HOME/.claude"; entry="CLAUDE.md" ;;
        codex) root="$HOME/.codex"; entry="AGENTS.md" ;;
        *) log_error "未知目标：$name"; return 1 ;;
    esac
    entry_path="$root/$entry"
    rules_path="$root/rules"

    echo
    echo "卸载目标：$name"
    if [[ ! -d "$root" ]]; then
        log_warn "目标目录不存在：$root，无需卸载。"
        return 0
    fi

    if [[ "$PURGE" == true ]]; then
        remove_path "$entry_path" || return 1
        remove_path "$rules_path" || return 1
        remove_all_backups "$entry_path" || return 1
        remove_all_backups "$rules_path" || return 1
    else
        if ! restore_latest_backup "$entry_path"; then
            remove_path "$entry_path" || return 1
        fi
        if ! restore_latest_backup "$rules_path"; then
            remove_path "$rules_path" || return 1
        fi
        remove_all_backups "$entry_path" || return 1
        remove_all_backups "$rules_path" || return 1
    fi

    if [[ "$DRY_RUN" == false ]] && [[ -z "$(ls -A "$root" 2>/dev/null)" ]]; then
        remove_path "$root" || return 1
    fi
}

resolve_target
validate_target

echo "Claude 与 Codex 全局规则卸载器"
echo "  目标：$TARGET"
[[ "$PURGE" == true ]] && echo "  模式：完全删除（含备份）"
[[ "$DRY_RUN" == true ]] && echo "  模式：干跑"

if [[ "$TARGET" == all ]]; then
    names="claude codex"
else
    names="$TARGET"
fi

failures=""
for name in $names; do
    if ! uninstall_target "$name"; then
        log_error "$name 卸载失败。"
        failures="$failures $name"
    fi
done

echo
if [[ -n "$failures" ]]; then
    log_error "卸载未完全成功，失败目标：$failures"
    exit 1
fi

log_info "卸载完成。"
[[ "$DRY_RUN" == true ]] && log_warn "本次为干跑模式，未实际修改文件。"
