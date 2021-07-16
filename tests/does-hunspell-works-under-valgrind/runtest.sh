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

    rlRun "echo \"NEWSX\"|hunspell -a;echo -e '#include <time.h>\nclock_t clock(void) { return 0; }'|gcc -o libclock.so -Wall -g -shared -fPIC -x c -;echo "NEWSX"|LD_PRELOAD=./libclock.so hunspell -a > out"

    rlRun "echo \"NEWSX\"|hunspell -a;echo -e '#include <time.h>\nclock_t clock(void) { return 0; }'|gcc -o libclock.so -Wall -g -shared -fPIC -x c -;echo \"NEWSX\"|LD_PRELOAD=./libclock.so valgrind -q hunspell -a > valgrind_out"

    # Remove dictionary to avoid possibility of different results with
    # already present dictionary. After this all commands start with
    # the clean sheet.
    rlRun "rm -f $HOME/.hunspell_en_US"

    rlAssertNotDiffer "out" "valgrind_out"
    [ "$?" -ne 0 ] && rlLogWarning "$(diff out valgrind_out)"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd" # $TmpDir
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
