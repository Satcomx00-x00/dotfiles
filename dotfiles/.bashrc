# User-specific configurations for the Bash shell

# Set up environment variables
export EDITOR='code'
export VISUAL='code'
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ll='ls -la'
alias gs='git status'
alias gp='git pull'
alias gc='git commit'
alias gca='git commit --amend'
alias gl='git log --oneline --graph --decorate'

# Custom prompt
PS1='[\u@\h \W]\$ ' 

# Source additional scripts if they exist
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

if [ -f ~/.bash_functions ]; then
    . ~/.bash_functions
fi