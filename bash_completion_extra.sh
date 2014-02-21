#!/bin/bash

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

# This function performs completion of file paths rooted at a user specified directory,
# and allows filtering of those completions by regular expressions.
# It depends on some functions in /etc/bash_completion so you need to make sure that file has
# been sourced first.
# The function should not be used directly (it takes different arguments to normal completion functions),
# but should be called by another completion function.
#
# @param $1  The directory to start in.
# @param $2  A regular expression matching filenames/dirs to keep in the completions
#            (after first param has been removed from their pathnames)
# @param $3  A regular expression matching filenames/dirs to remove from the completions
#            (after first param has been removed from their pathnames)
#
# EXAMPLE 
#     complete jpeg files and non-hidden directories within ~/temp: _firedir_rooted ~/temp "(.jpg|.JPG|/)$" "^\."

_filedir_rooted_filtered()
{
    #debugme set -x
    local i IFS=$'\n' cur="${COMP_WORDS[COMP_CWORD]}" 
    _tilde "$cur" || return 0
    local -a dirs files files2 all all2 all3 i elem
    local quoted
    # _quote_readline_by_ref should be defined in /etc/bash_completion
    _quote_readline_by_ref "$1/$cur" quoted

    all=( $( compgen -f -- "$quoted" ) )
    # Add / to end of directory names
    for (( i = 0 ; i < "${#all[@]}" ; i++ )); do
        if [[ -d "${all[$i]}" ]]; then
            all[$i]="${all[$i]}/"
        fi
    done
    # Remove 1st arg from paths (so we can do regexp matching)
    all=( "${all[@]/$1\//}" )
    # Keep only files/dirs matching 2nd arg
    for elem in "${all[@]}"; do
        if ( [[ -z "$2" ]] || [[ "$elem" =~ $2  ]] ); then
            all2+=("$elem")
        fi
    done
    # Remove files/dirs matching 3rd arg
    for elem in "${all2[@]}"; do
        if [[ -z "$3" ]] || ! [[ "$elem" =~ $3 ]]; then
            all3+=("$elem")
        fi
    done
    # Don't put space after completions (want to be able to continue completing)
    compopt -o nospace -o filenames
    COMPREPLY=( "${COMPREPLY[@]}" "${all3[@]}" )
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
    local cur cur2 allvars matches
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
        cur2=${cur##$}        
        COMPREPLY=( $(compgen -P "$" -W "$matches" -- ${cur2}) )
    fi
}

