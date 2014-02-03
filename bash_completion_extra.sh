# Extra bash completion helper functions.

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
    [ ${#toks[@]} -ne 0 ] && _compopt_o_filenames
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
    # Remove basedir from completions
    COMPREPLY=( "${COMPREPLY[@]}" "${toks[@]/$1\//}" )
}
