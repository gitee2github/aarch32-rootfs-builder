%global _hardened_build 1
Name:              dropbear
Version:           2019.78
Release:           6
Summary:           Lightweight SSH server and client
License:           MIT
URL:               https://matt.ucc.asn.au/dropbear/dropbear.html
Source0:           https://matt.ucc.asn.au/%{name}/releases/%{name}-%{version}.tar.bz2
Source1:           dropbear.service
Source2:           dropbear-keygen.service
Source3:           sshd
BuildRequires:     gcc
BuildRequires:     libtomcrypt-devel
BuildRequires:     libtommath-devel
BuildRequires:     pam-devel
%ifnarch %{arm}
BuildRequires:     systemd
%{?systemd_requires}
# For triggerun
Requires(post):    systemd-sysv
%endif
BuildRequires:     zlib-devel

%description
Dropbear is a relatively small SSH server and client. It's particularly useful
for "embedded"-type Linux (or other Unix) systems, such as wireless routers.

%package help
Summary: Including man file for dropbear
Requires: man

%description    help
This contains man files for the using of dropbear

%prep
%setup -q
iconv -f iso-8859-1 -t utf-8 -o CHANGES{.utf8,}
mv CHANGES{.utf8,}

%build
%configure --enable-pam --disable-bundled-libtom

cat > localoptions.h <<EOT
#define SFTPSERVER_PATH "/usr/libexec/openssh/sftp-server"
EOT

%make_build PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"

%install
%make_install  PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
install -d %{buildroot}%{_sysconfdir}/%{name}
install -d %{buildroot}%{_unitdir}
%ifarch %{arm}
install -d %{buildroot}/etc/init.d/
install -pm 755 %{SOURCE3} %{buildroot}/etc/init.d/sshd
ln -srf %{buildroot}/etc/init.d/sshd %{buildroot}/etc/init.d/S05sshd
ln -srf %{buildroot}%{_bindir}/dbclient %{buildroot}%{_bindir}/ssh
ln -srf %{buildroot}%{_sbindir}/dropbear %{buildroot}%{_sbindir}/sshd
%else
install -pm644 %{S:1} %{buildroot}%{_unitdir}/%{name}.service
install -pm644 %{S:2} %{buildroot}%{_unitdir}/dropbear-keygen.service

%post
%systemd_post %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%preun
%systemd_preun %{name}.service

%triggerun -- dropbear < 0.55-2
# Save the current service runlevel info
# User must manually run systemd-sysv-convert --apply dropbear
# to migrate them to systemd targets
systemd-sysv-convert --save dropbear >/dev/null 2>&1 ||:

# Run these because the SysV package being removed won't do them
chkconfig --del dropbear >/dev/null 2>&1 || :
systemctl try-restart dropbear.service >/dev/null 2>&1 || :
%endif

%files
%ifnarch %{arm}
%doc CHANGES README
%license LICENSE
%{_mandir}/man1/*.1*
%{_mandir}/man8/*.8*
%{_unitdir}/dropbear*
%else
%{_bindir}/ssh
%{_sbindir}/sshd
/etc/init.d/*
%endif
%dir %{_sysconfdir}/dropbear
%{_bindir}/dropbearkey
%{_bindir}/dropbearconvert
%{_bindir}/dbclient
%{_bindir}/scp
%{_sbindir}/dropbear

%ifarch %{arm}
%files help
%doc CHANGES README
%license LICENSE
%{_mandir}/man1/*.1*
%{_mandir}/man8/*.8*
%endif

%changelog
* Mon Dec 7 2020 liang_dong <liang_dong@hoperun.com> - 2019.78-6
- chmod sshd file

* Fri Dec 4 2020 liang_dong <liang_dong@hoperun.com> - 2019.78-5
- add scp bin into pkg

* Wed Dec 2 2020 liang_dong <liang_dong@hoperun.com> - 2019.78-4
- add SysVinit support in busybox env

* Fri Nov 27 2020 liang_dong <liang_dong@hoperun.com> - 2019.78-3
- Add arm32 compilation support

* Wed Nov 18 2020 liang_dong <liang_dong@hoperun.com> - 2019.78-2
- package init
