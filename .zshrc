# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
  export ZSH=/home/david/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="robbyrussell"
#ZSH_THEME="random"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# autojump file
source /etc/profile.d/autojump.zsh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliase
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#
# Import colorscheme from 'wal'
#(wal -r &) 


alias v="vim"
alias vi="vim"

#alias sudo='nocorrect sudo '
alias scst='sudo systemctl start'
alias scsp='sudo systemctl stop'
alias scrl='sudo systemctl reload'
alias scrt='sudo systemctl restart'
alias sce='sudo systemctl enable'
alias scd='sudo systemctl disable'
alias scs='systemctl status'

alias ap="ansible-playbook"
alias ans="cd ~/git/ansible-project/roles && ls"
alias dap="cd ~/git/david-playbooks/roles/"
alias zshrc="vim ~/.zshrc && source ~/.zshrc"
alias hist="history | grep"
set -o vi



################################################################################
# ssh
################################################################################
#function s () {
#	local lastarg host domain fqdn user ip args
#	lastarg="${@:${#@}}"
#	host="${lastarg#*@}"
#	user="${lastarg%${host}}"
#	args="${@:1:$((${#@}-1))}"
#	for domain in "" "flyeralarm" "flyeralarm.com" "vm"; do
#		fqdn=${host}${domain:+.${domain}}
#		ip=$(dig +noall +answer "${fqdn}"|head -1|awk '{print $5}')
#        if [[ ${ip} =~ ^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\. ]]
#		    [ -n "${ip}" ] && break;
#		    fqdn=""
#	done
#	[ -z "${fqdn}" ] && { echo "${host} not found" >&2; return 1; }
#	ssh -t ${args:-} "${user:-root@}${fqdn}" "TERM=xterm bash -o vi"
#}

function s () {
    local hostnames domain fqdn ip opt
    hostnames=()
    for domain in "flyeralarm" "flyeralarm.com" "vm"; do
        fqdn=$1.$domain
        ip=$(dig +noall +answer "${fqdn}"|head -1|awk '{print $5}')
        if [[ ${ip} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            hostnames+=($fqdn)
        fi
    done
    if [[ ${#hostnames[@]} -eq 0 ]]; then
        echo "$1 not found"
        return 1
    elif [[ ${#hostnames[@]} -gt 1 ]]; then
        echo "multiple hosts exist with that name:"
        select opt in ${hostnames[@]}
        do
            ssh -t root@$opt "TERM=xterm bash -o vi"
            return 0
        done
    else
        ssh -t root@${hostnames[1]} "TERM=xterm bash -o vi"
    fi
}

################################################################################
# pastebin
################################################################################

_pastebin_host=${_pastebin_host:-https://pastebin.flyeralarm}

function pastebin () {
	local _url=$(curl -k -X POST -s --data-binary @- "${_pastebin_host:?}/documents"|\
		awk -v "host=${_pastebin_host}" -F '"' '{print host "/" $4}')
	if [[ -p /dev/stdout ]]; then
		echo "${_url}" 1>&2
	fi
	echo "${_url}"
}

function showpaste() {
	local _url
	if [[ ! -p /dev/stdin ]]; then
		_url="${1:?URL is missing}"
	else
		_url=$(cat)
	fi
	_url=$(echo "${_url}"|sed -e 's@^\(.*\)\(/[^/[:space:]]\+\)$@\1/raw\2@')
	curl -ks ${_url}
}

################################################################################
# icinga
################################################################################
# schdeule downtime for a host and all it's services
# Arguments:
#     1 - host name
#     2 - duration, such that `date -d 'now + $2'` can understand it.
#         e.g: '3hours' or '45minutes'
#     3 - comment
# Returns:
#     None

function icinga_schedule_downtime () {
	local url
	local data
	url="https://status.flyeralarm:5665/v1/actions/schedule-downtime?filter="
	url+="host.name==%22${1:?hostname missing}%22&type="
	data='{ "start_time": '$(date +"%s")', "end_time": '$(date +"%s" -d "now + ${2:?duration missing}")
	data+=', "author": "NAME"'${3+', "comment": "'${3}'"'}' }'
	for t in Host Service; do
		curl -kL -s -u "dashing:D4sH1N9" -H 'Accept: application/json' \
		     -H 'Content-Type: application/json' -X POST "${url}${t}" -d "${data}" &>/dev/null ||\
		{ echo "error for type=${t}"; return 1; }
	done
}

# remove downtime for a host and all it's services
# Arguments:
#     1 - host name
# Returns:
#     None
#
function icinga_remove_downtime () {
	local url
	url="https://status.flyeralarm:5665/v1/actions/remove-downtime?filter="
	url+="host.name==%22${1:?hostname missing}%22&type="
	for t in Host Service; do
		curl -kL -s -u "dashing:D4sH1N9" -H 'Accept: application/json' \
			 -X POST "${url}${t}" &>/dev/null ||\
		{ echo "error for type=${t}"; return 1; }
	done
}


# ldapquery

function ldapquery () {
#    ldapsearch -x -D "TOWERGROUP\d.popp" -W -p 389 -h 10.0.20.101 -b \
#        "dc=TOWERGROUP,dc=local" -s sub "(sAMAccountName=${1})" cn \
#        sAMAccountName mail whenCreated whenChanged ipPhone
ldapsearch -x -D "TOWERGROUP\d.popp" -W -p 389 -h 10.0.20.101 -b "dc=TOWERGROUP,dc=local" -s sub "(sAMAccountName=${1})" cn sAMAccountName mail whenCreated whenChanged ipPhone | awk 'BEGIN { RS="\n[[:space:]]*\n"; FS="\n" } $1 !~ /^# (search |extended LDIF|numResponses:)/ { print $0 }'
}


# mpw
 #source bashlib
mpw() {
    _copy() {
        if hash pbcopy 2>/dev/null; then
            pbcopy
        elif hash xclip 2>/dev/null; then
            xclip -selection clip
        else
            cat; echo 2>/dev/null
            return
        fi
        echo >&2 "Copied!"
    }

    # Empty the clipboard
    :| _copy 2>/dev/null

    # Ask for the user's name and password if not yet known.
    #MPW_FULLNAME=${MPW_FULLNAME:-$(ask 'Your Full Name:')}
    MPW_FULLNAME="David Popp"

    # Start Master Password and copy the output.
    printf %s "$(MPW_FULLNAME=$MPW_FULLNAME command mpw "$@")" | _copy
}
