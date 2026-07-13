# Bare `zellij` names the session after the current directory and re-attaches
# if it already exists. Any invocation with arguments passes through.
function zellij --wraps zellij
    if test (count $argv) -eq 0
        set -l name (basename $PWD | string upper | string replace -ra '[^A-Z0-9_.-]' '-')
        command zellij attach --create $name
    else
        command zellij $argv
    end
end
