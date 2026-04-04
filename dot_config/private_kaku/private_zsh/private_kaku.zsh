# Kaku Zsh Integration - DO NOT EDIT MANUALLY
# This file is managed by Kaku.app. Any changes may be overwritten.

export KAKU_ZSH_DIR="$HOME/.config/kaku/zsh"

# Add Kaku managed bin to PATH (kaku wrapper and user tools)
export PATH="$KAKU_ZSH_DIR/bin:$PATH"

# Initialize Starship (Cross-shell prompt)
# Use system installation managed by Homebrew (or user PATH).
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"

    # Kaku workaround: Fix Zsh + Starship bug where Ctrl-C prints the literal RPROMPT string.
    # When Zsh receives SIGINT during prompt evaluation, it aborts the command
    # substitution and prints the literal $(starship...) string. Pre-evaluating
    # the right prompt in precmd avoids this entirely.
    _kaku_render_starship_rprompt() {
        command starship prompt --right             --terminal-width="${COLUMNS:-}"             --keymap="${KEYMAP:-}"             --status="${STARSHIP_CMD_STATUS:-}"             --pipestatus="${STARSHIP_PIPE_STATUS[*]:-}"             --cmd-duration="${STARSHIP_DURATION:-}"             --jobs="${STARSHIP_JOBS_COUNT:-0}" 2>/dev/null
    }

    _kaku_fix_starship_rprompt() {
        # Check if RPROMPT currently holds a dynamic starship command
        if [[ "${RPROMPT:-}" == *'$('*'starship'*'prompt --right'* ]]; then
            # Capture it and save it as our template
            _kaku_starship_rprompt_cmd="$RPROMPT"
        fi

        # If we have a saved starship command template, we should evaluate it.
        # BUT we only overwrite RPROMPT if RPROMPT is exactly what we set it to last time,
        # or if it is the original starship command itself.
        # If the user sets RPROMPT="foo", we leave it alone.
        if [[ -n "${_kaku_starship_rprompt_cmd:-}" ]]; then
            if [[ "${RPROMPT:-}" == "${_kaku_starship_rprompt_cmd}" ]] || [[ "${RPROMPT:-}" == "${_kaku_last_injected_rprompt:-}" ]]; then
                local evaled
                if [[ "${_kaku_starship_rprompt_cmd}" == *starship*'prompt --right'* ]]; then
                    evaled="$(_kaku_render_starship_rprompt)"
                else
                    local cmd="${_kaku_starship_rprompt_cmd}"
                    # Avoid zsh pattern parsing here; strip a literal $(
                    # prefix and trailing ) via slicing instead.
                    if [[ "${cmd[1]}" == '$' && "${cmd[2]}" == '(' && "${cmd[-1]}" == ')' ]]; then
                        cmd="${cmd[3,-2]}"
                    fi
                    evaled="$(eval "$cmd" 2>/dev/null)"
                fi
                RPROMPT="$evaled"
                _kaku_last_injected_rprompt="$evaled"
            fi
        fi
    }
    if [[ ${precmd_functions[(Ie)_kaku_fix_starship_rprompt]} -eq 0 ]]; then
        precmd_functions+=(_kaku_fix_starship_rprompt)
    fi
fi

# Enable color output for ls
export CLICOLOR=1
export LSCOLORS="gxfxcxdxbxegedabagacad"

# Smart History Configuration
HISTSIZE="${HISTSIZE:-50000}"
SAVEHIST="${SAVEHIST:-50000}"
if [[ -z "${HISTFILE:-}" ]]; then
    HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
fi
setopt HIST_IGNORE_ALL_DUPS      # Remove older duplicate when new entry is added
setopt HIST_FIND_NO_DUPS         # Do not display duplicates when searching history
setopt HIST_REDUCE_BLANKS        # Remove blank lines from history
setopt HIST_IGNORE_SPACE         # Skip commands that start with a space
setopt SHARE_HISTORY             # Share history between all sessions
setopt APPEND_HISTORY            # Append history to the history file (no overwriting)
setopt INC_APPEND_HISTORY        # Write each command to history file immediately
setopt EXTENDED_HISTORY          # Include timestamps in saved history

# Set default Zsh options
setopt interactive_comments
bindkey -e

# Prefix history search on Up/Down (e.g. type "curl" then press Up)
# This is shell behavior, not terminal behavior, so Kaku configures it here.
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
zmodload zsh/terminfo 2>/dev/null || true
for _kaku_keymap in emacs viins; do
    [[ -n "${terminfo[kcuu1]:-}" ]] && bindkey -M "$_kaku_keymap" "${terminfo[kcuu1]}" up-line-or-beginning-search
    [[ -n "${terminfo[kcud1]:-}" ]] && bindkey -M "$_kaku_keymap" "${terminfo[kcud1]}" down-line-or-beginning-search
    bindkey -M "$_kaku_keymap" '^[[A' up-line-or-beginning-search
    bindkey -M "$_kaku_keymap" '^[[B' down-line-or-beginning-search
    bindkey -M "$_kaku_keymap" '^[OA' up-line-or-beginning-search
    bindkey -M "$_kaku_keymap" '^[OB' down-line-or-beginning-search
done
unset _kaku_keymap

# Kaku line-selection widgets for modified arrows in prompt editing.
_kaku_select_left_char() {
    emulate -L zsh
    if (( ! REGION_ACTIVE )); then
        zle set-mark-command
    fi
    zle backward-char
}
_kaku_select_right_char() {
    emulate -L zsh
    if (( ! REGION_ACTIVE )); then
        zle set-mark-command
    fi
    zle forward-char
}
_kaku_select_line_start() {
    emulate -L zsh
    if (( ! REGION_ACTIVE )); then
        zle set-mark-command
    fi
    zle beginning-of-line
}
_kaku_select_line_end() {
    emulate -L zsh
    if (( ! REGION_ACTIVE )); then
        zle set-mark-command
    fi
    zle end-of-line
}
_kaku_has_active_region() {
    emulate -L zsh
    # Require both an active region flag and a non-empty span. Either one can
    # be stale on its own and would cause false-positive kill-region deletes.
    (( REGION_ACTIVE && MARK != CURSOR ))
}
_kaku_deactivate_region() {
    emulate -L zsh
    if ! _kaku_has_active_region; then
        return 1
    fi
    if (( ${+widgets[deactivate-region]} )); then
        zle deactivate-region
    else
        MARK=$CURSOR
        REGION_ACTIVE=0
        zle redisplay
    fi
    return 0
}
# Unconditional region deactivation helper (not bound to any key; called from
# _kaku_mv_* widgets below). Unlike _kaku_deactivate_region this always clears
# REGION_ACTIVE without checking MARK vs CURSOR, ensuring stale region flags
# are removed even when the selection span is empty.
_kaku_force_deactivate_region() {
    emulate -L zsh
    (( ! REGION_ACTIVE )) && return
    if (( ${+widgets[deactivate-region]} )); then
        zle deactivate-region
    else
        REGION_ACTIVE=0
        MARK=$CURSOR
        zle redisplay
    fi
}
# Movement widgets that auto-deactivate any active region before moving.
# The Kaku GUI sends ^B/^F/^A/^E when collapsing a selection with a plain or
# Cmd+arrow key; these wrappers ensure zsh clears REGION_ACTIVE in the same
# keystroke, preventing spurious region-extension or stale region highlights.
_kaku_mv_backward_char() {
    emulate -L zsh
    _kaku_force_deactivate_region
    zle backward-char
}
_kaku_mv_forward_char() {
    emulate -L zsh
    _kaku_force_deactivate_region
    zle forward-char
}
_kaku_mv_beginning_of_line() {
    emulate -L zsh
    _kaku_force_deactivate_region
    zle beginning-of-line
}
_kaku_mv_end_of_line() {
    emulate -L zsh
    _kaku_force_deactivate_region
    zle end-of-line
}
zle -N _kaku_mv_backward_char
zle -N _kaku_mv_forward_char
zle -N _kaku_mv_beginning_of_line
zle -N _kaku_mv_end_of_line
zle -N _kaku_select_left_char
zle -N _kaku_select_right_char
zle -N _kaku_select_line_start
zle -N _kaku_select_line_end

# Terminal-assisted selection shortcuts (Kaku GUI sends these directly).
_kaku_cmd_a_select_all() {
    emulate -L zsh
    # Move to beginning first so MARK is anchored there, then extend to end.
    # If set-mark-command were called first, MARK would be at the current cursor
    # position and only the text after it would be selected.
    zle beginning-of-line
    zle set-mark-command
    zle end-of-line
}
_kaku_cmd_shift_left() {
    emulate -L zsh
    zle set-mark-command
    zle beginning-of-line
}
_kaku_cmd_shift_right() {
    emulate -L zsh
    zle set-mark-command
    zle end-of-line
}
zle -N _kaku_cmd_a_select_all
zle -N _kaku_cmd_shift_left
zle -N _kaku_cmd_shift_right

# Cancel selection without moving cursor (ESC key in Kaku GUI).
_kaku_cancel_selection() {
    emulate -L zsh
    _kaku_force_deactivate_region
}
zle -N _kaku_cancel_selection

# Shift+Left/Right: char expand; Shift+Home/End: to line boundary.
bindkey '^[[1;2D' _kaku_select_left_char
bindkey '^[[1;2C' _kaku_select_right_char
bindkey '^[[1;2H' _kaku_select_line_start
bindkey '^[[1;2F' _kaku_select_line_end

# Terminal-assisted selection shortcuts (distinct CSI sequences from Kaku GUI).
bindkey '^[[990~' _kaku_cmd_a_select_all
bindkey '^[[991~' _kaku_cmd_shift_left
bindkey '^[[992~' _kaku_cmd_shift_right
bindkey '^[[995~' _kaku_cancel_selection

# Emacs movement keys wrapped to auto-deactivate any active region.
# ^B/^F/^A/^E are sent by the Kaku GUI when collapsing a selection with a
# plain or Cmd+arrow key. Wrapping them (rather than using a custom CSI escape)
# avoids stray characters if the sequence is received in an unexpected context.
bindkey '^B' _kaku_mv_backward_char
bindkey '^F' _kaku_mv_forward_char
bindkey '^A' _kaku_mv_beginning_of_line
bindkey '^E' _kaku_mv_end_of_line

# Bind delete keys to native zsh widgets. The Kaku GUI handles selection-aware
# deletion directly (sending kill sequences via line_editor_selection), so the
# shell side does not need a wrapper here.
bindkey '^?' backward-delete-char
bindkey '^H' backward-delete-char
bindkey '^[[3~' delete-char
bindkey '^G' send-break

# Directory Navigation Options
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# Common Aliases (Intuitive defaults)
alias ll='ls -lhF'   # Detailed list (human-readable sizes, no hidden files)
alias la='ls -lAhF'  # List all (including hidden, except . and ..)
alias l='ls -CF'     # Compact list

# Directory Navigation
alias ...='../..'
alias ....='../../..'
alias .....='../../../..'
alias ......='../../../../..'

alias md='mkdir -p'
alias rd=rmdir

# Grep Colors
alias grep='grep --color=auto'
alias egrep='grep -E --color=auto'
alias fgrep='grep -F --color=auto'

# Common Git Aliases (The Essentials)
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gbd='git branch -d'
alias gc='git commit -v'
alias gcmsg='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gd='git diff'
alias gds='git diff --staged'
alias gf='git fetch'
alias gl='git pull'
alias gp='git push'
alias gst='git status'
alias gss='git status -s'
alias glo='git log --oneline --decorate'
alias glg='git log --stat'
alias glgp='git log --stat -p'

# yazi launcher — cd into the directory yazi is in when you exit.
'y'() {
    emulate -L zsh
    setopt local_options no_sh_word_split

    local yazi_cmd="$KAKU_ZSH_DIR/bin/yazi"
    if [[ ! -x "$yazi_cmd" ]]; then
        yazi_cmd="$(command -v yazi 2>/dev/null || true)"
    fi

    if [[ -z "$yazi_cmd" ]]; then
        echo "yazi not found. Install it with: brew install yazi"
        return 127
    fi

    local tmp cwd
    tmp="$(mktemp -t 'yazi-cwd.XXXXXX')"
    "$yazi_cmd" "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}

# Load Plugins (Performance Optimized)

# Load zsh-completions into fpath before compinit.
# If the user already added this path, do not duplicate it.
if [[ -d "$KAKU_ZSH_DIR/plugins/zsh-completions/src" ]] && (( ${fpath[(Ie)$KAKU_ZSH_DIR/plugins/zsh-completions/src]} == 0 )); then
    fpath=("$KAKU_ZSH_DIR/plugins/zsh-completions/src" $fpath)
fi

# Optimized compinit:
# - If completion system is already initialized by user config/plugin manager, skip.
# - Otherwise use cache and only rebuild when needed.
autoload -Uz compinit
if ! (( ${+functions[_main_complete]} )) || ! (( ${+_comps} )); then
    if [[ -n "${ZDOTDIR:-$HOME}/.zcompdump"(#qN.mh+24) ]]; then
        # Rebuild completion cache if older than 24 hours
        compinit
    else
        # Load from cache (much faster)
        compinit -C
    fi
fi

# Load zsh-z (smart directory jumping) if not already provided by user config.
if [[ -f "$KAKU_ZSH_DIR/plugins/zsh-z/zsh-z.plugin.zsh" ]] && ! (( ${+functions[zshz]} )); then
    # Default to smart case matching so `z kaku` prefers `Kaku` over lowercase
    # path entries. Users can still override this in their own shell config.
    : "${ZSHZ_CASE:=smart}"
    export ZSHZ_CASE
    source "$KAKU_ZSH_DIR/plugins/zsh-z/zsh-z.plugin.zsh"
fi

# cd + Tab falls back to zsh-z frecency history when filesystem completion
# has no match. Delegate ranking to zshz --complete so behavior stays aligned
# with the plugin (frecency ordering, smart-case, future plugin changes).
if (( ${+functions[zshz]} )); then
    _kaku_cd_history_complete() {
        emulate -L zsh
        setopt extended_glob no_sh_word_split

        _cd
        local ret=$?
        local nmatches="${compstate[nmatches]:-0}"
        if (( nmatches > 0 )); then
            return $ret
        fi

        local token="${PREFIX:-}"
        [[ -n "$token" ]] || return $ret
        [[ "$token" != -* ]] || return $ret

        (( ${+functions[zshz]} )) || return $ret

        local -a matches
        local match
        while IFS= read -r match; do
            [[ -n "$match" ]] || continue
            matches+=("$match")
        done < <(zshz --complete -- "$token" 2>/dev/null)

        (( ${#matches[@]} )) || return $ret

        compadd -Q -U -X "zsh-z history dirs" -- "${matches[@]}"
        return 0
    }

    if (( ${+functions[compdef]} )); then
        compdef _kaku_cd_history_complete cd
    fi
fi

# Detect if any autosuggest system is already active (e.g., Kiro CLI, Fig, etc.)
# These systems wrap zle widgets with names containing "autosuggest", which would
# conflict with zsh-autosuggestions and cause FUNCNEST recursion errors.
_kaku_has_autosuggest_system() {
    local w
    for w in ${(k)widgets}; do
        case "${w:l}" in
            autosuggest-*) continue ;;  # zsh-autosuggestions' own widgets
            *autosuggest*) return 0 ;;  # third-party (Kiro CLI, Fig, etc.)
        esac
    done
    return 1
}

# Load zsh-autosuggestions only if:
# 1. User config has not loaded it yet (_zsh_autosuggest_start not defined)
# 2. No other autosuggest system is active (to avoid widget wrapping conflicts)
if ! (( ${+functions[_zsh_autosuggest_start]} )) && ! _kaku_has_autosuggest_system && [[ -f "$KAKU_ZSH_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$KAKU_ZSH_DIR/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
unset -f _kaku_has_autosuggest_system 2>/dev/null

# Smart Tab behavior:
# - Use completion while typing arguments/path-like tokens
# - Accept inline suggestion first only for the first command token
# - Only claim Tab inside Kaku sessions unless explicitly disabled
if [[ -z "${KAKU_SMART_TAB_DISABLE:-}" ]] && [[ "${TERM_PROGRAM:-}" == "Kaku" ]]; then
    _kaku_tab_widget() {
        emulate -L zsh

        local has_suggestion=0
        if (( ${+widgets[autosuggest-accept]} )) && [[ -n "${POSTDISPLAY:-}" ]]; then
            has_suggestion=1
        fi

        # Use completion while typing arguments (e.g. 'vim READ<Tab>')
        # and for path-like command tokens ('./scr<Tab>').
        local lbuf="${LBUFFER}"
        local trimmed="${lbuf#${lbuf%%[![:space:]]*}}"
        local current_token="${lbuf##*[[:space:]]}"

        if [[ -z "$trimmed" || "$trimmed" == *[[:space:]]* || "$current_token" == */* ]]; then
            zle expand-or-complete
            return
        fi

        if (( has_suggestion )); then
            zle autosuggest-accept
        else
            zle expand-or-complete
        fi
    }
    zle -N _kaku_tab_widget
    bindkey '^I' _kaku_tab_widget
fi

# Defer fast-syntax-highlighting to first prompt (~40ms saved at startup)
# This plugin must be loaded LAST, and we delay it for faster shell startup.
# If user config already loaded it, skip to avoid overriding user settings.
if ! (( ${+functions[_zsh_highlight]} )) && [[ -f "$KAKU_ZSH_DIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]]; then
    # Defer loading until first prompt display
    fast_syntax_highlighting_defer() {
        source "$KAKU_ZSH_DIR/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

        # Override comment color: fsh default (fg=8) is invisible on dark backgrounds.
        typeset -gA FAST_HIGHLIGHT_STYLES
        FAST_HIGHLIGHT_STYLES[comment]='fg=244'

        # Remove this hook after first run
        precmd_functions=("${precmd_functions[@]:#fast_syntax_highlighting_defer}")
    }

    # Hook into precmd (runs before prompt is displayed)
    precmd_functions+=(fast_syntax_highlighting_defer)
fi

# Kaku AI fix hooks (error-only):
# - preexec captures the command text
# - precmd captures the previous command exit code
# Lua listens to these user vars and only suggests fixes when exit code != 0.
_kaku_set_user_var() {
    local name="$1"
    local value="$2"

    # Kaku defaults TERM to xterm-256color for SSH compatibility.
    # Use WEZTERM_PANE presence to detect Kaku/WezTerm panes reliably.
    if [[ "$TERM" != "kaku" && -z "${WEZTERM_PANE:-}" ]]; then
        return
    fi

    if [[ "${WEZTERM_SHELL_SKIP_USER_VARS:-}" == "1" ]]; then
        return
    fi

    local encoded=""
    if command -v base64 >/dev/null 2>&1; then
        encoded="$(printf '%s' "$value" | base64 | tr -d '\r\n')"
    else
        return
    fi

    if [[ -n "${TMUX:-}" ]]; then
        printf "\033Ptmux;\033\033]1337;SetUserVar=%s=%s\007\033\\" "$name" "$encoded"
    else
        printf "\033]1337;SetUserVar=%s=%s\007" "$name" "$encoded"
    fi
}

# Only emit exit code when a real command was executed.
# Empty Enter should not re-trigger AI suggestions for the previous failure.
typeset -g _kaku_ai_cmd_pending=0

_kaku_ai_preexec() {
    if [[ -n "${KAKU_AUTO_DISABLE:-}" ]]; then
        return
    fi
    _kaku_ai_cmd_pending=1
    _kaku_set_user_var "kaku_last_cmd" "$1"
}

_kaku_ai_precmd() {
    local last_exit_code="$?"
    if [[ -n "${KAKU_AUTO_DISABLE:-}" ]]; then
        _kaku_ai_cmd_pending=0
        return 0
    fi
    if [[ "${_kaku_ai_cmd_pending:-0}" != "1" ]]; then
        return 0
    fi
    _kaku_set_user_var "kaku_last_exit_code" "$last_exit_code"
    _kaku_ai_cmd_pending=0
}

if [[ ${preexec_functions[(Ie)_kaku_ai_preexec]} -eq 0 ]]; then
    preexec_functions+=(_kaku_ai_preexec)
fi
if [[ ${precmd_functions[(Ie)_kaku_ai_precmd]} -eq 0 ]]; then
    precmd_functions=(_kaku_ai_precmd "${precmd_functions[@]}")
fi

# Cancel AI suggestions when user starts typing (before pressing Enter).
# This prevents AI notices from appearing after the user has already begun
# entering a new command, avoiding interruption.
typeset -g _kaku_ai_cancel_sent=0

_kaku_cancel_ai_on_typing() {
    if [[ "$_kaku_ai_cancel_sent" == "0" && -n "$BUFFER" ]]; then
        _kaku_set_user_var "kaku_user_typing" "1"
        _kaku_ai_cancel_sent=1
    fi
}

_kaku_reset_ai_cancel_flag() {
    _kaku_ai_cancel_sent=0
}

autoload -Uz add-zle-hook-widget 2>/dev/null
if (( $+functions[add-zle-hook-widget] )); then
    add-zle-hook-widget line-pre-redraw _kaku_cancel_ai_on_typing
    add-zle-hook-widget line-init _kaku_reset_ai_cancel_flag
fi

# AI generate: intercept Enter on "# query" lines via accept-line widget.
# preexec does not fire for comment-only lines (zsh strips them before execution),
# so we wrap accept-line instead. Registration is deferred to first prompt so it
# runs after zsh-autosuggestions finishes binding its own widgets.
_kaku_ai_waiting=0
_kaku_ai_waiting_ts=0
_kaku_ai_reset_waiting() { _kaku_ai_waiting=0; }
add-zsh-hook precmd _kaku_ai_reset_waiting

_kaku_ai_query_accept_line() {
    # Block repeat Enter only while buffer still shows the # query.
    # Auto-reset after 30 seconds to prevent permanent blocking if Lua side fails.
    if (( _kaku_ai_waiting )); then
        if [[ "${BUFFER[1]}" == '#' ]]; then
            local now=$EPOCHSECONDS
            if (( now - _kaku_ai_waiting_ts > 30 )); then
                _kaku_ai_waiting=0
            else
                return
            fi
        else
            _kaku_ai_waiting=0
        fi
    fi
    # Only intercept a single-line comment (no newlines in buffer)
    if [[ -z "${KAKU_AUTO_DISABLE:-}" && -n "$BUFFER" && "${BUFFER[1]}" == '#' && "$BUFFER" != *$'\n'* ]]; then
        local query="${BUFFER:1}"
        query="${query# }"
        if [[ -n "$query" ]]; then
            print -s -- "${BUFFER}"
            _kaku_set_user_var "kaku_ai_query" "$query"
            _kaku_ai_waiting=1
            _kaku_ai_waiting_ts=$EPOCHSECONDS
            # Keep # query visible; Lua sends \x15 to clear it when result arrives
            zle reset-prompt
            return
        fi
    fi
    zle .accept-line
}

_kaku_ai_query_register_widget() {
    zle -N accept-line _kaku_ai_query_accept_line
    precmd_functions=("${precmd_functions[@]:#_kaku_ai_query_register_widget}")
}
precmd_functions+=(_kaku_ai_query_register_widget)

# Auto-set TERM to xterm-256color for SSH connections when running under kaku,
# since remote hosts typically lack the kaku terminfo entry.
# Also auto-detect 1Password SSH agent and add IdentitiesOnly=yes to prevent
# "Too many authentication failures" caused by 1Password offering all stored keys.
# Set KAKU_SSH_SKIP_1PASSWORD_FIX=1 to disable the 1Password behavior.
# Guard: only define if no existing ssh function is present, so user-defined
# wrappers (e.g. from fzf-ssh, autossh plugins) are not silently replaced.
_kaku_wrapped_ssh() {
    local -a extra_opts=()

    # 1Password SSH agent fix: auto-add IdentitiesOnly=yes to prevent
    # "Too many authentication failures" when 1Password offers all stored keys.
    # Set KAKU_SSH_SKIP_1PASSWORD_FIX=1 to disable.
    if [[ -z "${KAKU_SSH_SKIP_1PASSWORD_FIX-}" ]]; then
        local sock="${SSH_AUTH_SOCK:-}"
        if [[ "$sock" == *1password* || "$sock" == *2BUA8C4S2C* ]]; then
            local has_identitiesonly=false prev=""
            for arg in "$@"; do
                [[ "$prev" == "-o" && "$arg" == IdentitiesOnly=* ]] && has_identitiesonly=true
                [[ "$arg" == -oIdentitiesOnly=* ]] && has_identitiesonly=true
                prev="$arg"
            done
            $has_identitiesonly || extra_opts+=(-o "IdentitiesOnly=yes")
        fi
    fi

    if [[ "$TERM" == "kaku" ]]; then
        TERM=xterm-256color command ssh "${extra_opts[@]}" "$@"
    else
        command ssh "${extra_opts[@]}" "$@"
    fi
}
if (( $+aliases[ssh] )); then
    typeset _kaku_existing_ssh_alias="${aliases[ssh]}"
    function ssh {
        local -a extra_opts=()
        local -a _kaku_alias_words

        if [[ -z "${KAKU_SSH_SKIP_1PASSWORD_FIX-}" ]]; then
            local sock="${SSH_AUTH_SOCK:-}"
            if [[ "$sock" == *1password* || "$sock" == *2BUA8C4S2C* ]]; then
                local has_identitiesonly=false prev=""
                for arg in "$@"; do
                    [[ "$prev" == "-o" && "$arg" == IdentitiesOnly=* ]] && has_identitiesonly=true
                    [[ "$arg" == -oIdentitiesOnly=* ]] && has_identitiesonly=true
                    prev="$arg"
                done
                $has_identitiesonly || extra_opts+=(-o "IdentitiesOnly=yes")
            fi
        fi

        _kaku_alias_words=(${(z)_kaku_existing_ssh_alias})
        if [[ "${_kaku_alias_words[1]-}" == "ssh" ]]; then
            _kaku_wrapped_ssh "${(@)_kaku_alias_words[2,-1]}" "$@"
        elif [[ "${_kaku_alias_words[1]-}" == "command" && "${_kaku_alias_words[2]-}" == "ssh" ]]; then
            _kaku_wrapped_ssh "${(@)_kaku_alias_words[3,-1]}" "$@"
        elif [[ "$TERM" == "kaku" ]]; then
            TERM=xterm-256color "${_kaku_alias_words[@]}" "${extra_opts[@]}" "$@"
        else
            "${_kaku_alias_words[@]}" "${extra_opts[@]}" "$@"
        fi
    }
    unalias ssh
elif ! typeset -f ssh > /dev/null 2>&1; then
function ssh {
    _kaku_wrapped_ssh "$@"
}
fi

# Auto-set TERM to xterm-256color for sudo commands when running under kaku.
# sudo usually resets TERMINFO_DIRS, so root processes (e.g. nano) can fail
# with "unknown terminal type 'kaku'" even though Kaku set TERMINFO_DIRS for the
# user shell. Set KAKU_SUDO_SKIP_TERM_FIX=1 to disable this behavior.
# Guard: only define if no existing sudo function is present.
# If sudo is an alias, zsh expands it during function-definition parsing and
# raises a syntax error ("defining function based on alias"). Unalias first.
if ! typeset -f sudo > /dev/null 2>&1; then
unalias sudo 2>/dev/null || true
function sudo {
    if [[ -z "${KAKU_SUDO_SKIP_TERM_FIX-}" && "$TERM" == "kaku" ]]; then
        TERM=xterm-256color command sudo "$@"
    else
        command sudo "$@"
    fi
}
fi
