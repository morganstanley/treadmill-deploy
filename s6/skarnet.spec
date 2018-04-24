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
mkdir -p %{buildroot}/%{_bindir}
mkdir -p %{buildroot}/%{_libexecdir}
cp -r %{_builddir}/bin/* %{buildroot}/%{_bindir}
cp -r %{_builddir}/libexec/* %{buildroot}/%{_libexecdir}

%files
%defattr(-,root,root,-)
%include %{_builddir}/bin.lst
%include %{_builddir}/libexec.lst
%doc


%changelog

