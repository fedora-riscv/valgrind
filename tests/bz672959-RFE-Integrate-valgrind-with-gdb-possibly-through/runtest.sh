#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/valgrind/Sanity/bz672959-RFE-Integrate-valgrind-with-gdb-possibly-through
#   Description: Test for BZ#672959 ([RFE] Integrate valgrind with gdb possibly through)
#   Author: Miroslav Franc <mfranc@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2012 Red Hat, Inc. All rights reserved.
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
. /usr/share/beakerlib/beakerlib.sh

PACKAGE=$(rpm --qf "%{name}\n" -qf $(which valgrind) | head -1)
PACKAGES=(valgrind gcc gdb)

# Expect 1th argument as a path to binary to test with
_test_routine()
{
    local binary=$1

    rlPhaseStartTest "$binary error"
    rlAssertExists "$binary"
        rlLog "valgrind gdb server..."
        valgrind --vex-iropt-register-updates=allregs-at-mem-access --vgdb-error=0 ./$binary > vloge 2>&1 &
        vpid=$!
        sleep 5
        rlRun "gdb -x error.gdb ./$binary > gloge 2>&1"
        [[ -d /proc/$vpid ]] && { kill -9 $vpid; rlFail "oops: valgrind still running..."; }
        rlRun "wait $vpid"
        rlAssertGrep '19.*if(x)' gloge
        rlAssertGrep '$1 = 42' gloge
        # there should be exactly one error
        rlAssertGrep 'ERROR SUMMARY: 1 errors from 1 contexts' vloge
        rlLog "> gdb output <"
        rlLog "$(<gloge)"
        rlLog "> valgrind output <"
        rlLog "$(<vloge)"
    rlPhaseEnd

    rlPhaseStartTest "$binary noerror"
    rlAssertExists "$binary"
        rlLog "valgrind gdb server..."
        valgrind --vex-iropt-register-updates=allregs-at-mem-access --vgdb-error=0 ./$binary > vlogn 2>&1 &
        vpid=$!
        sleep 5
        rlRun "gdb -x noerror.gdb ./$binary > glogn 2>&1"
        [[ -d /proc/$vpid ]] && { kill -9 $vpid; rlFail "oops: valgrind still running..."; }
        rlRun "wait $vpid"
        rlAssertGrep '10.*f(a);' glogn
        # this time, no errors
        rlAssertGrep 'ERROR SUMMARY: 0 errors from 0 contexts' vlogn
        rlAssertGrep 'hello, world' vlogn
        rlLog "> gdb output <"
        rlLog "$(<glogn)"
        rlLog "> valgrind output <"
        rlLog "$(<vlogn)"
    rlPhaseEnd
}

rlJournalStart
    rlPhaseStartSetup
        which valgrind | grep "/devtoolset"
        if [ $? -eq 0 ]; then
            rpm_prefix="$(which valgrind | grep -o 'devtoolset[^/]*')-"
        fi

        for p in "${PACKAGES[@]}"; do
            rlAssertRpm "${rpm_prefix}${p}"
        done; unset p
        rlRun "TmpDir=\$(mktemp -d)" 0 "Creating tmp directory"
        rlRun "cp something.c error.gdb noerror.gdb $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "gcc -g something.c -o basic.out"

        which dwz
        if [ $? -eq 0 ]; then
            rlRun "cp basic.out dwz.out"
            rlRun "dwz dwz.out"
            rlRun "dwz_binary_size=$(du -b dwz.out | awk '{ print $1}')"
            rlRun "basic_binary_size=$(du -b basic.out | awk '{ print $1}')"
            [ "$dwz_binary_size" = "$basic_binary_size" ] && rlFail "Size of dwz binary should differs"
            run_for=(basic.out dwz.out)
        else
            run_for=(basic.out)
        fi
    rlPhaseEnd

    for p in "${run_for[@]}"; do
        _test_routine "$p"
    done; unset p

    rlPhaseStartCleanup
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
