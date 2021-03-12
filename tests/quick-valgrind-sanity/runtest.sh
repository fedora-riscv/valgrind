#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/valgrind/Sanity/quick-valgrind-sanity
#   Description: Very fast check that valgrind is working
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2013 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
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

# Include Beaker environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

VALGRIND="${VALGRIND:-$(which valgrind)}"
PACKAGES="${PACKAGES:-$(rpm --qf '%{name}\n' -qf $(which $VALGRIND) | head -1)}"

rlJournalStart
    rlPhaseStartSetup
        rlLogInfo "VALGRIND=$VALGRIND"
        rlLogInfo "PACKAGES=$PACKAGES"
        rlLogInfo "REQUIRES=$REQUIRES"
        rlLogInfo "$(type valgrind)"
        rlLogInfo "$(type gcc)"

        rlLogInfo "SKIP_COLLECTION_METAPACKAGE_CHECK=$SKIP_COLLECTION_METAPACKAGE_CHECK"

                # We optionally need to skip checking for the presence of the metapackage
                # because that would pull in all the dependent toolset subrpms.  We do not
                # always want that, especially in CI.
                _COLLECTIONS="$COLLECTIONS"
                if ! test -z $SKIP_COLLECTION_METAPACKAGE_CHECK; then
                    for c in $SKIP_COLLECTION_METAPACKAGE_CHECK; do
                        rlLogInfo "ignoring metapackage check for collection $c"
                        export COLLECTIONS=$(shopt -s extglob && echo ${COLLECTIONS//$c/})
                    done
                fi

                rlLogInfo "(without skipped) COLLECTIONS=$COLLECTIONS"

                rlAssertRpm --all

                export COLLECTIONS="$_COLLECTIONS"

        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp unitialized.c rv.c alloc.c $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -g unitialized.c -o unitialized"
    rlPhaseEnd

    rlPhaseStartTest "good"
        rlRun "valgrind --log-file=./log0 ./unitialized 0" 42
        rlAssertNotGrep 'contains uninitialised byte' ./log0
        rlAssertGrep 'ERROR SUMMARY: 0' ./log0
        rlLog "$(<log0)"
    rlPhaseEnd

    rlPhaseStartTest "bad"
        rlRun "valgrind --log-file=./log2 ./unitialized 2" 0-41,43-255
        rlAssertGrep 'contains uninitialised byte' ./log2
        rlAssertGrep 'ERROR SUMMARY: 1' ./log2
        rlLog "$(<log2)"
    rlPhaseEnd

    rlPhaseStartTest "client request"
        rlRun "gcc -g rv.c -o rv"
        rlRun "valgrind ./rv > with-valgrind"
        rlAssertGrep "I'm running on valgrind" with-valgrind
        rlLog "$(<with-valgrind)"
        rlRun "./rv > without-valgrind"
        rlAssertGrep "I'm not running on valgrind" without-valgrind
        rlLog "$(<without-valgrind)"
    rlPhaseEnd

    rlPhaseStartTest "client request with leak checking"
        rlRun "gcc -g alloc.c -o alloc"
        rlRun "valgrind --log-file=./log ./alloc 42"
        rlAssertGrep 'still reachable: 42 bytes in 1 blocks' log
        rlLog "$(<log)"
    rlPhaseEnd

    rlPhaseStartCleanup
        rlRun "popd" # $TmpDir
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
