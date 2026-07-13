# fish config (converted from zsh)
set -g fish_theme_mode "light"  # or "dark"
set -u TERM_PROGRAM
set -l theme_file ~/.config/fish/theme_mode
if test -f $theme_file
    read -g fish_theme_mode < $theme_file
    set -gx fish_theme_mode $fish_theme_mode
else
    set -gx fish_theme_mode "light"
end

set -gx HIGHLIGHT "#CDC1FF"
set -x FZF_DEFAULT_OPTS "\
--color=fg:#DDDDDD,hl:$HIGHLIGHT \
--color=fg+:$HIGHLIGHT,hl+:$HIGHLIGHT \
--color=info:#898989,prompt:$HIGHLIGHT,pointer:$HIGHLIGHT \
--color=marker:$HIGHLIGHT,spinner:#66A5AD,header:#EC8FB0 \
--color=border:#403833"

if status is-interactive
    source ~/.config/fish/colors.fish
end


function st
    set -l theme_file ~/.config/fish/theme_mode
    if test "$fish_theme_mode" = "light"
        set -gx fish_theme_mode "dark"
    else
        set -gx fish_theme_mode "light"
    end
    echo $fish_theme_mode > $theme_file

    # Update git delta.dark to match the theme
    if test $fish_theme_mode = "light"
        git config --global delta.dark false
        git config --global delta.light true
        git config --global delta.syntax-theme GitHub
    else
        git config --global delta.dark true
        git config --global delta.light false
        git config --global delta.syntax-theme Dracula
    end

    # Optionally, re-source your colors
    source ~/.config/fish/config.fish
    echo $fish_theme_mode
end

# set -x FZF_DEFAULT_OPTS "\
# --color=fg:#DDDDDD,bg:#1C1917,hl:#CDC1FF \
# --color=fg+:#DDDDDD,bg+:#403833,hl+:#CDC1FF \
# --color=info:#898989,prompt:#CDC1FF,pointer:#EC8FB0 \
# --color=marker:#CDC1FF,spinner:#66A5AD,header:#B77E64 \
# --color=gutter:#1C1917,border:#403833"
function fish_command_not_found
    echo "fish: Unknown command '$argv'"
    return 127
end

# fish_config theme choose "Dracula"
set -g fish_greeting
set -g fish_prompt_pwd_dir_length 0
set -g hydro_color_pwd $fish_color_cwd
set -g hydro_color_jj $fish_color_user
set -g hydro_color_prompt $fish_color_command
set -g hydro_color_duration $fish_color_comment
set -g hydro_color_error $fish_color_error
set -gx EDITOR "nvim"

function n
    nvim $PWD
end

function open
    if test (count $argv) -eq 1
        if test (uname -s) = "Linux"
            explorer.exe (wslpath -w $argv[1])
        else
            echo "Not on WSL"
        end
    else
        command open $argv
    end
end
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
fish_add_path -gP "$PNPM_HOME"

set -gx BUN_INSTALL $HOME/.bun
set -gx PATH $PATH $BUN_INSTALL/bin /usr/local/bin

function nv
    pushd ~/.config/nvim
    nvim .
    popd
end

alias ns "nvim ~/.config/fish/config.fish"
alias rs "source ~/.config/fish/config.fish"

alias ls "eza --icons"

set -gx PATH $HOME/.local/bin $PATH
set -gx DIRENV_LOG_FORMAT ""


# Source cargo env
if test -d $HOME/.cargo
    set -gx PATH $HOME/.cargo/bin $PATH
end


# Interactive-only initialization (skipped for `fish -c …` invocations from
# scripts, hooks, etc.). zoxide/direnv/starship inits are cached on first run.
function _fzf_cd
    set -l dir
    if command -q fd
        set dir (fd --type d --hidden --exclude .git 2>/dev/null | fzf --preview 'eza --icons --color=always {}' +m)
    else
        set dir (find . -type d -not -path '*/.git/*' 2>/dev/null | fzf --preview 'ls {}' +m)
    end
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end

function _fzf_file
    set -l files
    if command -q fd
        set files (fd --type f --hidden --exclude .git 2>/dev/null | fzf --multi --preview 'bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || sed -n "1,200p" {}')
    else
        set files (find . -type f -not -path '*/.git/*' 2>/dev/null | fzf --multi --preview 'sed -n "1,200p" {}')
    end
    if test (count $files) -gt 0
        commandline -it (string join ' ' (string escape -- $files))
        commandline -f repaint
    end
end

function _fzf_cd_home
    set -l dir
    if command -q fd
        set dir (fd --type d --hidden --exclude .git . $HOME 2>/dev/null | fzf --preview 'eza --icons --color=always {}' +m)
    else
        set dir (find $HOME -type d -not -path '*/.git/*' 2>/dev/null | fzf --preview 'ls {}' +m)
    end
    if test -n "$dir"
        cd $dir
        commandline -f repaint
    end
end

if status is-interactive
    set -l _cache ~/.config/fish/cache
    test -d $_cache; or mkdir -p $_cache
    test -f $_cache/zoxide.fish; or command zoxide init fish > $_cache/zoxide.fish
    test -f $_cache/direnv.fish; or command direnv hook fish > $_cache/direnv.fish
    # test -f $_cache/starship.fish; or command starship init fish --print-full-init > $_cache/starship.fish
    source $_cache/zoxide.fish
    source $_cache/direnv.fish
    # source $_cache/starship.fish

    # fzf-style defaults: Ctrl-T inserts selected file(s), Alt-C cd's locally.
    # Ctrl-B keeps the home-wide cd search.
    bind \ct _fzf_file
    bind \ec _fzf_cd
    bind \cb _fzf_cd_home

    # jj completions are lazy-loaded by fish from ~/.config/fish/completions/jj.fish
    # To regenerate: rm ~/.config/fish/completions/jj.fish && exec fish
    if not test -f ~/.config/fish/completions/jj.fish
        mkdir -p ~/.config/fish/completions
        command jj util completion fish > ~/.config/fish/completions/jj.fish
        cat ~/.config/fish/jj.fish >> ~/.config/fish/completions/jj.fish
    end
end

set -x XDG_DATA_DIRS ~/.local/share:$XDG_DATA_DIRS
set -gx PATH /run/wrappers/bin $PATH
set -gx VIRTUAL_ENV ".venv"

function jsb
set -gx CURRENT_BRANCH ( \
  jj b l \
  | string match -rv '^\s' \
  | fzf \
  | string replace -r '^(.*?):.*' '$1' \
)
end

function jin
    jsb
    jj new $CURRENT_BRANCH
end

function jie
    jsb
    jj edit $CURRENT_BRANCH
end

function jbn
    # If the current branch is empty, error
    if test ($CURRENT_BRANCH = "")
        echo "Error: Current branch is empty. Please run jsb first."
        return 1
    end

    jj new $CURRENT_BRANCH
    set -gx CURRENT_BRANCH ""
end

function jbe
    if test ($CURRENT_BRANCH = "")
        echo "Error: Current branch is empty. Please run jsb first."
        return 1
    end

    jj edit $CURRENT_BRANCH
    set -gx CURRENT_BRANCH ""
end

function tms
    set HL "#CDC1FF"
    set selected (tmux list-sessions \
        -f '#{?#{==:#{session_name},__HIDDEN__},0,#{?#{==:#{session_name},POPUP},0,1}}' \
        -F '#{session_name}' \
        | sk --tmux center,50%,40% \
             --layout=default --no-info --no-clear \
             --color none \
             --color "fg:#DDDDDD,hl:$HL,fg+:$HL,hl+:$HL,info:#898989,prompt:$HL,pointer:$HL,marker:$HL,spinner:#66A5AD,header:#EC8FB0,border:#403833")
    if test -n "$selected"
        if set -q TMUX
            tmux switch-client -t "$selected"
        else
            tmux attach-session -t "$selected"
        end
    end
end
