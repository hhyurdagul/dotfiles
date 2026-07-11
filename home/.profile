
. "$HOME/.local/share/../bin/env"

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

case ":$PATH:" in
    *:/home/hhyurdagul/.juliaup/bin:*)
        ;;

    *)
        export PATH=/home/hhyurdagul/.juliaup/bin${PATH:+:${PATH}}
        ;;
esac

# <<< juliaup initialize <<<


# Added by Antigravity CLI installer
export PATH="/home/hhyurdagul/.local/bin:$PATH"
