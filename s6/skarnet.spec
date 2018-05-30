Name:           skarnet
Version:        2.7.1.1
Release:        2%{?dist}
Summary:        Skarnet Suite

License:        ISC
URL:            http://skarnet.org/software/s6/
Source0:        %{_builddir}/bin
Source1:        %{_builddir}/lib
Source2:        %{_builddir}/libexec


%description
skarnet.org's small & secure supervision software suite.


%prep


%build


%install
cp -r %{_builddir}/opt %{buildroot}/opt

%files
%defattr(-,root,root,-)
/opt/s6/*
%doc


%changelog

