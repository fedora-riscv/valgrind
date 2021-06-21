#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Description: Testing sanity of valgrind by comparing outputs of hunspell with/without valgrind.
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2011 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2 or later.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include rhts environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

    SPELL_CHECKER="${SPELL_CHECKER:-hunspell}"

VALGRIND="${VALGRIND:-$(which valgrind)}"
PACKAGES="${PACKAGES:-$(rpm --qf '%{name}\n' -qf $(which $VALGRIND) | head -1)}"
REQUIRES="${REQUIRES:-$SPELL_CHECKER}"

rlJournalStart
    rlPhaseStartSetup
        rlLogInfo "VALGRIND=$VALGRIND"
        rlLogInfo "PACKAGES=$PACKAGES"
        rlLogInfo "REQUIRES=$REQUIRES"
        rlLogInfo "SPELL_CHECKER=$SPELL_CHECKER"
        rlLogInfo "$(type valgrind)"

        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "pushd $TmpDir"
    rlPhaseEnd

    rlPhaseStartTest

    out="$TmpDir/spell_check.out"
    err="$TmpDir/spell_check.err"
    vout="$TmpDir/spell_check.valgrind.out"
    verr="$TmpDir/spell_check.valgrind.err"

    spell_checker_command=""
    spell_checker_command="echo \"hackerx\" | $SPELL_CHECKER -a > $out 2> $err"

    # Remove dictionary to avoid possibility of different results with
    # already present dictionary. After this all commands start with
    # the clean sheet.
    rlRun "rm -f $HOME/.hunspell_en_US"

    rlRun "$spell_checker_command" 0-255

    if [ "$?" -eq "0" ]; then
        spell_checker_command="${spell_checker_command/$out/$vout}"
        spell_checker_command="${spell_checker_command/$err/$verr}"

        rlRun "rm -f $HOME/.hunspell_en_US"
        rlRun "valgrind $spell_checker_command" 0-255
        if [ "$?" -ne 0 ]; then
            rlLogWarning "Valgrind check failed"
            rlLogWarning "$(cat $verr)"
        else
            rlAssertNotDiffer "$out" "$vout"
            [ "$?" -ne 0 ] && rlLogWarning "$(diff $out $vout)"
        fi
    else
        ((skipped++))

        rlLogWarning "Regular check failed"
        rlLogWarning "$(cat $err)"
    fi

    rlRun "rm -f $out $err $vout $verr"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd" # $TmpDir
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
