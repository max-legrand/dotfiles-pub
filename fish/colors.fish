# --- Palette definitions ---
# Dark
set -l dark_fg "#DDDDDD"
set -l dark_fg1 "#A8A8A8"
set -l dark_bg "#1C1917"
set -l dark_bg1 "#403833"
set -l dark_pink $HIGHLIGHT
set -l dark_green "#00FFAA"
set -l dark_yellow "#D6C5A5"
set -l dark_red "#EC8FB0"
set -l dark_gray "#898989"
set -l dark_sky "#656EA4"
set -l dark_water "#7E86B4"
set -l dark_wood "#B77E64"

# Light
set -l light_fg "#22223b"
set -l light_fg1 "#6c6f93"
set -l light_bg "#ece7f6"
set -l light_bg1 "#d1cbe7"
set -l light_pink "#a18fff"
set -l light_green "#00b894"
set -l light_yellow "#bfa05a"
set -l light_red "#e57373"
set -l light_gray "#bdbdbd"
set -l light_sky "#66A5AD"
set -l light_water "#6099C0"
set -l light_wood "#B77E64"

# --- Assign palette ---
set -l fg fg1 bg bg1 pink green yellow red gray sky water wood
if test "$fish_theme_mode" = "light"
    set fg $light_fg
    set fg1 $light_fg1
    set bg $light_bg
    set bg1 $light_bg1
    set pink $light_pink
    set green $light_green
    set yellow $light_yellow
    set red $light_red
    set gray $light_gray
    set sky $light_sky
    set water $light_water
    set wood $light_wood
else
    set fg $dark_fg
    set fg1 $dark_fg1
    set bg $dark_bg
    set bg1 $dark_bg1
    set pink $dark_pink
    set green $dark_green
    set yellow $dark_yellow
    set red $dark_red
    set gray $dark_gray
    set sky $dark_sky
    set water $dark_water
    set wood $dark_wood
end

# --- Set Fish colors ---
set -g fish_color_autosuggestion $gray
set -g fish_color_cancel $red
set -g fish_color_command $pink
set -g fish_color_comment $gray
set -g fish_color_cwd $pink
set -g fish_color_cwd_root $red
set -g fish_color_end $water
set -g fish_color_error $red
set -g fish_color_escape $green
set -g fish_color_history_current --bold
set -g fish_color_host $fg
set -g fish_color_host_remote $pink
set -g fish_color_keyword $water
set -g fish_color_normal $fg
set -g fish_color_operator $sky
set -g fish_color_param $fg
set -g fish_color_quote $yellow
set -g fish_color_redirection $water --bold
set -g fish_color_search_match bryellow --background=$bg1
set -g fish_color_selection white --bold --background=$bg1
set -g fish_color_status $red
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline
set -g fish_color_option $sky

# Pager colors
set -g fish_pager_color_completion normal
set -g fish_pager_color_description $gray $fg -i
set -g fish_pager_color_prefix normal --bold --underline
set -g fish_pager_color_progress brwhite --background=$gray
set -g fish_pager_color_selected_background $bg1
