Name:           Treadmill_AWS
Version:        %{_version} 
Release:        %{_release}%{?dist}
Summary:        Treadmill AWS

License:        Apache 2.0
URL:            https://github.com/Morgan-Stanley/treadmill
Prefix:         /opt/treadmill
AutoReqProv:    no
Requires:       conntrack-tools iproute libcgroup bridge-utils openldap-clients lvm2 lvm2-libs ipset iptables rrdtool bc docker-latest python34 skarnet treadmill-pid1 treadmill-bind treadmill-tktfwd


%description
Treadmill (AWS)


%prep


%build


%install
cp -r %{_builddir}/opt %{buildroot}/opt
mkdir -p %{buildroot}/lib/systemd/system/
install -m755 %{_builddir}/treadmill.service %{buildroot}/lib/systemd/system/
install -m755 %{_builddir}/treadmill-node.service %{buildroot}/lib/systemd/system/
install -m755 %{_builddir}/treadmill-master.service %{buildroot}/lib/systemd/system/

%post


%files
%defattr(-,root,root,-)
/opt/treadmill/*
/lib/systemd/system/treadmill.service
/lib/systemd/system/treadmill-node.service
/lib/systemd/system/treadmill-master.service

%changelog

