#!/usr/bin/env bash
# 一键卸载 Claude Code 全局配置（macOS / Linux）
# 默认行为：从最近一次备份恢复（如果存在），并删除本次安装写入的文件
# 用法：
#   ./uninstall.sh                回滚到上次备份（无备份则删除）
#   ./uninstall.sh --purge        完全删除所有相关文件（含所有备份）
#   ./uninstall.sh --dry-run      预览操作，不实际执行
#   ./uninstall.sh --help         查看帮助

set -euo pipefail

# 目标目录 = 用户家目录下的 .claude
TARGET_DIR="${HOME}/.claude"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
DRY_RUN=false
PURGE=false

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
用法：./uninstall.sh [选项]

选项：
  --purge      完全删除所有相关文件，包括所有 .bak.<时间戳> 备份
  --dry-run    预览将要执行的操作，不实际修改文件
  -h, --help   显示本帮助

默认行为：
  - 找到最近一次备份，恢复到 \${HOME}/.claude/
  - 如果无备份（首次安装），直接删除目标文件/目录
  - 删除本次安装写入的内容：CLAUDE.md、rules/ 及其备份
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --purge)   PURGE=true ;;
        -h|--help) show_help; exit 0 ;;
        *) log_error "未知参数：$arg"; show_help; exit 1 ;;
    esac
done

run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        printf "  [DRY-RUN] %s\n" "$*"
    else
        "$@"
    fi
}

# 删除单个路径（文件或目录）
remove_path() {
    local path="$1"
    if [[ -e "$path" ]]; then
        log_info "删除：$path"
        run_cmd rm -rf "$path"
    fi
}

# 恢复最新备份：找到 <path>.bak.* 中时间戳最大的那个，重命名为 <path>
restore_latest_backup() {
    local target_path="$1"
    # 仅匹配直接子项的备份：CLAUDE.md.bak.*，不会误匹配 CLAUDE.md.bak.xxxx.bak.*（理论上不存在）
    local pattern="${target_path}.bak.*"
    # 按文件名排序（时间戳格式 yyyyMMddHHmmss，字符串排序即为时间顺序）
    local latest
    latest=$(ls -1t $pattern 2>/dev/null | head -n 1 || true)
    if [[ -n "$latest" ]]; then
        log_info "恢复备份：$latest -> $target_path"
        # 若目标位置已存在（首次安装无备份的情况），先删再恢复
        if [[ -e "$target_path" ]]; then
            run_cmd rm -rf "$target_path"
        fi
        run_cmd mv "$latest" "$target_path"
    fi
}

# 删除所有 .bak.<时间戳> 备份（仅 --purge 模式调用）
purge_all_backups() {
    local pattern="$1"
    local backups
    backups=$(ls -1t $pattern 2>/dev/null || true)
    if [[ -n "$backups" ]]; then
        echo "$backups" | while read -r b; do
            [[ -n "$b" ]] && log_info "清理备份：$b" && [[ "$DRY_RUN" == false ]] && rm -rf "$b"
        done
    fi
}

main() {
    echo "Claude Code 全局配置卸载器"
    echo "  目标目录：$TARGET_DIR"
    if [[ "$DRY_RUN" == true ]]; then echo "  模式：干跑"; fi
    if [[ "$PURGE"  == true ]]; then echo "  模式：完全删除（含所有备份）"; fi
    echo

    if [[ ! -d "$TARGET_DIR" ]]; then
        log_warn "目标目录不存在：$TARGET_DIR，无需卸载"
        exit 0
    fi

    if [[ "$PURGE" == true ]]; then
        # 完全删除：清掉当前文件 + 所有备份
        remove_path "$TARGET_DIR/CLAUDE.md"
        remove_path "$TARGET_DIR/rules"
        purge_all_backups "$TARGET_DIR/CLAUDE.md.bak.*"
        # rules 目录下是递归备份，统一清理
        if [[ -d "$TARGET_DIR/rules" ]]; then
            find "$TARGET_DIR/rules" -name '*.bak.*' -exec rm -rf {} +
        fi
        # 若整个 .claude 目录为空，可顺手删除
        if [[ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
            remove_path "$TARGET_DIR"
        fi
    else
        # 默认：尝试从最新备份恢复，再删除本次安装的内容
        restore_latest_backup "$TARGET_DIR/CLAUDE.md"
        # rules 是目录，备份名形如 rules.bak.<时间戳>
        if [[ -d "$TARGET_DIR/rules" ]]; then
            # 先恢复目录级备份（如果存在）
            restore_latest_backup "$TARGET_DIR/rules"
            # 然后清理 rules 内部各文件的 .bak.*（install 脚本对每个规则文件都会备份）
            local inner_backups
            inner_backups=$(find "$TARGET_DIR/rules" -name '*.bak.*' 2>/dev/null || true)
            if [[ -n "$inner_backups" ]]; then
                echo "$inner_backups" | while read -r b; do
                    [[ -n "$b" ]] && log_info "清理文件级备份：$b" && [[ "$DRY_RUN" == false ]] && rm -rf "$b"
                done
            fi
        fi

        # 若本次没有备份可恢复（首次安装），直接删除当前文件
        remove_path "$TARGET_DIR/CLAUDE.md"
        remove_path "$TARGET_DIR/rules"

        # 顺带清理目录级的 .bak.*（如果 install 备份过 rules 目录）
        purge_all_backups "$TARGET_DIR/rules.bak.*"
        purge_all_backups "$TARGET_DIR/CLAUDE.md.bak.*"

        # 若整个 .claude 目录为空，可顺手删除
        if [[ -z "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]]; then
            remove_path "$TARGET_DIR"
        fi
    fi

    echo
    log_info "卸载完成"
    if [[ "$DRY_RUN" == true ]]; then
        log_warn "本次为干跑模式，未实际修改任何文件"
    fi
}

main