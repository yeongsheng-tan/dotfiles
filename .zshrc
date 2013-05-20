# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
#ZSH_THEME="powerline"
#ZSH_THEME="agnoster"
#ZSH_THEME="fino"
ZSH_THEME="bira"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(ap command-not-found debian git git-extras github ruby bundler gem gradle grails heroku history jruby last-working-dir mvn python rails rails3 rake rbenv rsync ssh-agent svn tmux vi-mode)

source $ZSH/oh-my-zsh.sh

export TERM="xterm-256color"

#powerline theme settings
POWERLINE_RIGHT_A="date replacement"
POWERLINE_RIGHT_B="time replacement"
POWERLINE_FULL_CURRENT_PATH="true"
POWERLINE_SHOW_GIT_ON_RIGHT="true"
POWERLINE_DETECT_SSH="true"


# Originally from Jonathan Penn, with modifications by Gary Bernhardt
function whodoneit() {
    (set -e &&
        for x in $(git grep -I --name-only $1); do
            git blame -f -- $x | grep $1;
        done
    )
}

# Customize to your needs...
#[[ -s /etc/profile.d/autojump.sh ]] && . /etc/profile.d/autojump.sh
export JAVA_HOME=/usr/lib/jvm/java-7-oracle
export PATH=/home/yeongsheng/.gvm/groovy/current/bin:/home/yeongsheng/.gvm/grails/current/bin:/home/yeongsheng/.gvm/griffon/current/bin:/home/yeongsheng/.gvm/gradle/current/bin:/home/yeongsheng/.gvm/vertx/current/bin:/home/yeongsheng/.gvm/bin:/home/yeongsheng/.gvm/ext:$JAVA_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
export PATH="$HOME/.rbenv/bin:$PATH"
export RUBY_BUILD_BUILD_PATH="$HOME/tmp"
eval "$(rbenv init -)"

#THIS MUST BE AT THE END OF THE FILE FOR GVM TO WORK!!!
[[ -s "/home/yeongsheng/.gvm/bin/gvm-init.sh" && -z $(which gvm-init.sh | grep '/gvm-init.sh') ]] && source "/home/yeongsheng/.gvm/bin/gvm-init.sh"

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
### vert.x
export VERTX_HOME=/home/yeongsheng/vert.x-1.3.1.final
export PATH="$VERTX_HOME/bin:$PATH"

bindkey -v
bindkey '\e[3~' delete-char
bindkey '^R' history-incremental-search-backward
