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
# @param $2  A quoted regular expression matching filenames/dirs to keep in the completions
#            (after first param has been removed from their pathnames).
# @param $3  A quoted regular expression matching filenames/dirs to remove from the completions
#            (after first param has been removed from their pathnames).
# @param $4  The maximum depth allowed (below the starting directory) for completions.
#
# EXAMPLE 
#     complete jpeg files and non-hidden directories within ~/temp at depth <= 2:
#                _firedir_rooted ~/temp "(.jpg|.JPG|/)$" "^\." 2
_filedir_rooted_filtered()
{
    #debugme set -x
    local i IFS=$'\n' cur="${COMP_WORDS[COMP_CWORD]}" slashes
    _tilde "$cur" || return 0
    local -a dirs files files2 all all2 all3 i elem
    local quoted 
    # _quote_readline_by_ref should be defined in /etc/bash_completion
    _quote_readline_by_ref "$1/$cur" quoted
    # count the number of /'s in the current completion and check
    # it is less than the specified amount
    slashes="${cur//[^\/]}"
    if [[ -z "$4" ]] || [[ "${#slashes}" < "$4" ]]; then
        all=( $( compgen -f -- "$quoted" ) )
    else
        all=()
        all2=()
        all3=()
    fi
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
        if [[ -z "$2" ]] || [[ "$elem" =~ $2  ]]; then
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
    COMPREPLY=( $(compgen -W "$opts" -- "${cur}") )
}

# Set current list of completions to all shell variables whose names
# match the regexp in the 2nd argument, but not the one in the
# 3rd argument. The 1st argument indicates whether the completions should
# be quoted or not - if it is y then they will be quoted, otherwise
# they wont be.
_matching_variables()
{
    local cur cur2 var
    local -a allvars matches matches2
    COMPREPLY=() # reset completion list
    cur="${COMP_WORDS[COMP_CWORD]}" # current word at cursor
    # Make sure arrays are properly initialized
    allvars=(`compgen -v`)
    matches=()
    matches2=()
    # Keep only variables matching 2nd arg
    for var in "${allvars[@]}"; do
        if [[ -z "$2" ]] || [[ "$var" =~ $2 ]]; then
            matches+=("$var")
        fi
    done
    # Remove variables matching 3rd arg
    for var in "${matches[@]}"; do
        if [[ -z "$3" ]] || ! [[ "$var" =~ $3 ]] ; then
            matches2+=("$var")
        fi
    done
    # If 1st arg is t then quote the variables 
    if [[ "$1" == y ]]; then
        cur2=${cur##\"$}
        COMPREPLY=( $(compgen -P "\"$" -S "\"" -W "${matches2[*]}" -- "${cur2}") )
    else # otherwise don't quote them (but put a $ at the beginning of their names)
        cur2=${cur##$}
        COMPREPLY=( $(compgen -P "$" -W "${matches2[*]}" -- "${cur2}") )
    fi
}

