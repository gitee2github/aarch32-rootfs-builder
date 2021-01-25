Name:     t3-setup
Version:  1.0
Release:  1
Summary:  embedded base setup files
License:  GPLv3
Source0:  %{name}-%{version}.tar.xz
Provides: t3-setup

%description
embedded base setup files

%prep
%autosetup -n %{name}-%{version} -p1

%install
cp -r t3/* $RPM_BUILD_ROOT/

%files
/etc/*
/usr/share/udhcpc/*

%changelog
* Tue Dec 1 2020 liang_dong <liang_dong@hoperun.com> - 1.0-1
- Package init
