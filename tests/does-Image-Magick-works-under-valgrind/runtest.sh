#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest.sh of /tools/valgrind/Sanity/does-Image-Magick-works-under-valgrind
#   Description: Testing sanity of valgrind by comparing outputs of ImageMagick utilities with/without valgrind.
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
#   The image munich.jpg used in this test is from:
#   https://en.wikipedia.org/wiki/File:Frauenkirche_and_Neues_Rathaus_Munich_March_2013.JPG.
#   munich.jpg file is distributed under the Creative Commons
#   Attribution-Share Alike 3.0 Unported license
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Include rhts environment
. /usr/share/beakerlib/beakerlib.sh || exit 1

VALGRIND="${VALGRIND:-$(which valgrind)}"
PACKAGES="${PACKAGES:-$(rpm --qf '%{name}\n' -qf $(which $VALGRIND) | head -1)}"
REQUIRES="${REQUIRES:-ImageMagick}"

Picture="munich.jpg"
Formats=(jpg gif)
Options=(-flop
         -flip
         -resize\ 160x100
         -resize\ 50\\\%
         -sharpen\ 5x5
         -equalize
         -motion-blur\ 20x5
         -paint\ 3x3
         -radial-blur\ 5
         -posterize\ 10
        )


rlJournalStart
    rlPhaseStartSetup
        rlLogInfo "VALGRIND=$VALGRIND"
        rlLogInfo "PACKAGES=$PACKAGES"
        rlLogInfo "REQUIRES=$REQUIRES"
        rlLogInfo "COLLECTIONS=$COLLECTIONS"
        rlLogInfo "$(type valgrind)"

        rlAssertRpm --all

        rlRun "TmpDir=\`mktemp -d\`" 0 "Creating tmp directory"
        rlRun "cp $Picture $TmpDir" 0 "Copying $Picture to $TmpDir"
        rlRun "pushd $TmpDir"
        rlRun "mkdir out" 0 "Creating out directory"
    rlPhaseEnd

    for f in "${Formats[@]}"; do
        for o in "${Options[@]}"; do
            rlPhaseStartTest "convert $o $Picture out/0${Picture%jpg}$f"
                rlRun "convert $o $Picture out/0${Picture%jpg}$f" 0 "Converting $Picture to out/0${Picture%jpg}$f with ($o)"
                rlLog "convert $o $Picture out/0${Picture%jpg}$f"
                rlRun "valgrind convert $o $Picture out/1${Picture%jpg}$f" 0 "Converting $Picture to out/1${Picture%jpg}$f with ($o) [valgrind]"
                rlLog "valgrind convert $o $Picture out/1${Picture%jpg}$f"
                [[ $(arch) = i686 ]] || rlRun "echo \`md5sum out/[01]${Picture%jpg}$f\` | while read with nic without nic; do test \"\$with\" = \"\$without\";done" 0 "Output is the same with/without valgrind"
                md5sum out/[01]${Picture%jpg}$f
            rlPhaseEnd
            rlPhaseStartCleanup "Cleaning for $f with $o"
                rlRun "mkdir -p \"out-$o\""
                rlRun "cp -r out/* \"out-$o/\""
                rlRun "rm -f out/*" 0 "Removing the old pictures"
            rlPhaseEnd
        done
    done

    rlPhaseStartCleanup
        rlRun "rm -rf out"
        rlRun "tar czf out.tgz $TmpDir/*"
        rlFileSubmit "out.tgz"
        rlRun "popd"
        rlRun "rm -r $TmpDir" 0 "Removing tmp directory"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
