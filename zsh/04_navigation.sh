# Function to go up x directories
function up() {
    # Default to 1 if no argument is provided
    local x=${1:-1}
    # do cd .. x times
    for ((i=0; i<x; i++)); do
        cd ..
    done
}

# directory shortcuts
alias docs="cd ~/Documents"
alias down="cd ~/Downloads"
alias desk="cd ~/Desktop"
alias repos="cd ~/Repositories"
alias dotfiles="charm ~/Repositories/dotfiles"

# PyCharm
alias charm="pycharm"

# misc
alias h='history'
alias c='clear'
alias l='ls -lahF --color=auto'
alias rdf='rm -rf'
alias o='open .'