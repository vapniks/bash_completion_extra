# Extra bash completion helper functions.
# Requires bash version >= 4

## LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street, Fifth
# Floor, Boston, MA 02110-1301, USA.


## CODE

# This function performs completion of file paths rooted at a user specified directory
# Most of the code is copied from _filedir in /etc/bash_completion, and it depends on some
# other functions in that file, so you should make sure that /etc/bash_completion has been sourced first.
# The function should not be used directly (it takes different arguments to normal completion functions),
# but should be called by another completion function.
# @param $1  The directory to start in.
# @param $2  If `-d', complete only on directories.  Otherwise filter/pick only
#            completions with `.$1' and the uppercase version of it as file
#            extension.
_filedir_rooted()
{
    local i IFS=$'\n' cur="${COMP_WORDS[COMP_CWORD]}" xspec
    _tilde "$cur" || return 0
    local -a toks # array to hold filepath completions
    local quoted tmp
    # _quote_readline_by_ref should be defined in /etc/bash_completion
    _quote_readline_by_ref "$1/$cur" quoted
    toks=( ${toks[@]-} $(
        compgen -d -- "$quoted" | {
            while read -r tmp; do
                # TODO: I have removed a "[ -n $tmp ] &&" before 'printf ..',
                #       and everything works again. If this bug suddenly
                #       appears again (i.e. "cd /b<TAB>" becomes "cd /"),
                #       remember to check for other similar conditionals (here
                #       and _filedir_xspec()). --David
                printf '%s\n' $tmp
            done
        }
    ))
    # Filter file extensions 
    if [[ "$2" != -d ]]; then
        # Munge xspec to contain uppercase version too
        [[ ${BASH_VERSINFO[0]} -ge 4 ]] && \
            xspec=${2:+"!*.@($2|${2^^})"} || \
            xspec=${2:+"!*.@($2|$(printf %s $2 | tr '[:lower:]' '[:upper:]'))"}
        toks=( ${toks[@]-} $( compgen -f -X "$xspec" -- $quoted) )
    fi
    # If the filter failed to produce anything, try w/o it (LP: #533985)
    if [[ -n "$2" ]] && [[ "$2" != -d ]] && [[ ${#toks[@]} -lt 1 ]] ; then
        toks=( ${toks[@]-} $( compgen -f -X -- $quoted) )
    fi
    # Put / at end of directory names
    for (( i = 0 ; i < ${#toks[@]} ; i++ )) 
    do
        if [ -d ${toks[$i]} ]; then
            toks[$i]=${toks[$i]}/
        fi
    done
    compopt -o nospace -o filenames    
    # Remove basedir from completions
    COMPREPLY=( "${COMPREPLY[@]}" "${toks[@]/$1\//}" )
}


# Set current list of completions to the list of network interfaces
# (there is also _available_interfaces, but it doesn't work well for me).
_network_interfaces() 
{
    local cur opts
    COMPREPLY=() # reset completion list
    cur="${COMP_WORDS[COMP_CWORD]}" # current word at cursor
    opts=`ls /sys/class/net`
    COMPREPLY=( $(compgen -W "$opts" -- ${cur}) )
}

# Set current list of completions to all shell variables whose names
# match the regular expression used as the first argument.
# If a second argument is supplied then quote the variables.
_matching_variables()
{
    local cur opts allvars matches
    COMPREPLY=() # reset completion list
    cur="${COMP_WORDS[COMP_CWORD]}" # current word at cursor
    allvars=(`compgen -v`)
    matches=()
    for var in ${allvars[@]}; do
        if [[ "$var" =~ $1 ]]; then
            matches+=("$var")
        fi
    done
    if [ $2 ]; then
        cur2=${cur##\"$}
        COMPREPLY=( $(compgen -P "\"$" -S "\"" -W "${matches[*]}" -- ${cur2}) )
    else
        COMPREPLY=( $(compgen -P "$" -W "$matches" -- ${cur}) )
    fi
}

