%define tar_version 1.0.0

Summary: Tool for finding memory management bugs in programs
Name: valgrind
Version: 1.0.0
Release: 1
Epoch: 1
Source0: valgrind-%{tar_version}.tar.bz2
License: GPL
Group: Development/Debuggers
BuildRoot: %{_tmppath}/%{name}-root
ExclusiveArch: %{ix86}
Patch0: valgrind-1.0pre1-extra_suppressions.patch
Patch1: valgrind-1.0pre4-clock.patch

%define __find_requires %{_builddir}/%{name}-%{tar_version}/find-requires

# disable build root strip policy
%define __spec_install_post /usr/lib/rpm/brp-compress || :

%description
Valgrind is a tool to help you find memory-management problems in your
programs. When a program is run under Valgrind's supervision, all
reads and writes of memory are checked, and calls to
malloc/new/free/delete are intercepted. As a result, Valgrind can
detect a lot of problems that are otherwise very hard to
find/diagnose.

%prep
%setup -q -n valgrind-%{tar_version}

%patch0 -p1 -b .extra_suppressions
%patch1 -p1 -b .clock

find_requires=`rpm --eval %%{__find_requires}`
echo "$find_requires | grep -v GLIBC_PRIVATE" > find-requires
chmod +x find-requires

%build
%configure

# Force a specific set of default supressions
echo -n > default.supp
for file in glibc-2.2.supp xfree-4.supp ; do
    cat $file >> default.supp
done
make 

%install
rm -rf $RPM_BUILD_ROOT
%makeinstall
mv $RPM_BUILD_ROOT%{_datadir}/doc/valgrind $RPM_BUILD_ROOT%{_datadir}/doc/valgrind-%{version}

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc ACKNOWLEDGEMENTS COPYING ChangeLog NEWS README TODO README_MISSING_SYSCALL_OR_IOCTL
%{_bindir}/*
%{_prefix}/include/valgrind.h
%{_libdir}/valgrind

%changelog
* Fri Aug  9 2002 Alexander Larsson <alexl@redhat.com>
- Update to 1.0.0

* Wed Jul  3 2002 Alexander Larsson <alexl@redhat.com>
- Update to pre4.

* Tue Jun 18 2002 Alexander Larsson <alla@lysator.liu.se>
- Add threadkeys and extra suppressions patches. Bump epoch.

* Mon Jun 17 2002 Alexander Larsson <alla@lysator.liu.se>
- Updated to 1.0pre1

* Tue May 28 2002 Alex Larsson <alexl@redhat.com>
- Updated to 20020524. Added GLIBC_PRIVATE patch

* Thu May  9 2002 Jonathan Blandford <jrb@redhat.com>
- add missing symbol __pthread_clock_settime

* Wed May  8 2002 Alex Larsson <alexl@redhat.com>
- Update to 20020508

* Mon May  6 2002 Alex Larsson <alexl@redhat.com>
- Update to 20020503b

* Thu May  2 2002 Alex Larsson <alexl@redhat.com>
- update to new snapshot

* Mon Apr 29 2002 Alex Larsson <alexl@redhat.com> 20020428-1
- update to new snapshot

* Fri Apr 26 2002 Jeremy Katz <katzj@redhat.com> 20020426-1
- update to new snapshot

* Thu Apr 25 2002 Alex Larsson <alexl@redhat.com> 20020424-5
- Added stack patch. Commented out other patches.

* Wed Apr 24 2002 Nalin Dahyabhai <nalin@redhat.com> 20020424-4
- filter out GLIBC_PRIVATE requires, add preload patch

* Wed Apr 24 2002 Alex Larsson <alexl@redhat.com> 20020424-3
- Make glibc 2.2 and XFree86 4 the default supressions

* Wed Apr 24 2002 Alex Larsson <alexl@redhat.com> 20020424-2
- Added patch that includes atomic.h

* Wed Apr 24 2002 Alex Larsson <alexl@redhat.com> 20020424-1
- Initial build
