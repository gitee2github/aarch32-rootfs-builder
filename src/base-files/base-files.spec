Name:     base-files
Version:  1.0
Release:  2
Summary:  embedded base files
License:  GPLv3
Provides: base-files

%description
embedded base files


%install
install -d $RPM_BUILD_ROOT/boot
install -d $RPM_BUILD_ROOT/dev
install -d $RPM_BUILD_ROOT/etc
install -d $RPM_BUILD_ROOT/home
install -d $RPM_BUILD_ROOT/mnt
install -d $RPM_BUILD_ROOT/proc
install -d $RPM_BUILD_ROOT/root
install -d $RPM_BUILD_ROOT/sys
install -d $RPM_BUILD_ROOT/tmp
install -d $RPM_BUILD_ROOT/usr
install -d $RPM_BUILD_ROOT/run
install -d $RPM_BUILD_ROOT/var
install -d $RPM_BUILD_ROOT/usr/lib
install -d $RPM_BUILD_ROOT/usr/bin
install -d $RPM_BUILD_ROOT/usr/sbin
install -d $RPM_BUILD_ROOT/usr/lib/modules
ln -srf $RPM_BUILD_ROOT/usr/sbin $RPM_BUILD_ROOT/sbin
ln -srf $RPM_BUILD_ROOT/usr/lib $RPM_BUILD_ROOT/lib
ln -srf $RPM_BUILD_ROOT/usr/bin $RPM_BUILD_ROOT/bin
ln -srf $RPM_BUILD_ROOT/run $RPM_BUILD_ROOT/var/run


%files
/*

%changelog
* Tue Dec 8 2020 liang_dong <liang_dong@hoperun.com> - 1.0-2
- add run and modules dir

* Tue Dec 1 2020 liang_dong <liang_dong@hoperun.com> - 1.0-1
- Package init

