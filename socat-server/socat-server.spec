Name:           socat-server
Version:        1 
Release:        0%{?dist}
Summary:        Socat Endpoint Manager

License:        Apache 2.0
URL:            https://github.com/Morgan-Stanley/treadmill-deploy
Prefix:         /opt/socat-server
AutoReqProv:    no
Requires:       Treadmill_AWS

%description
Socat Server


%prep
%build


%install
cp -r %{_builddir}/opt %{buildroot}/opt
mkdir -p %{buildroot}/lib/systemd/system/
install -m644 %{_builddir}/*.service %{buildroot}/lib/systemd/system/
install -m644 %{_builddir}/*.timer %{buildroot}/lib/systemd/system/

%post
# Create socat user 
id socat >/dev/null|| useradd --system --home /opt/socat-server --shell /bin/false socat

%files
%defattr(-,root,root,-)
/opt/socat-server/*
/lib/systemd/system/*.service
/lib/systemd/system/*.timer

%changelog

