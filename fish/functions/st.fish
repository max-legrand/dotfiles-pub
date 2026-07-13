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
