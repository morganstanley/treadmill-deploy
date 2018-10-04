Summary: ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services.
Name: zookeeper
Version: %{version}
Release: %{build_number}

License: Apache License, Version 2.0
Group: Applications/Databases
URL: http://zookeeper.apache.org/
Vendor: Apache Software Foundation

Prefix: /opt/zookeeper

Requires: java-1.8.0-openjdk
Provides: zookeeper

Source: zookeeper-%{version}.tar.gz

%description
ZooKeeper is a centralized service for maintaining configuration information, naming, providing distributed synchronization, and providing group services. 

%prep
tar -xvzf %{_topdir}/SOURCES/zookeeper-%{version}.tar.gz zookeeper-%{version}/zookeeper-%{version}.jar 'zookeeper-%{version}/lib/*jar'
mv -v %{_topdir}/SOURCES/zookeeper-authorizers.jar %{_topdir}/BUILD/zookeeper-%{version}/lib/

%build

%install
mkdir -p $RPM_BUILD_ROOT/opt/zookeeper
install -m644 $RPM_BUILD_DIR/zookeeper-%{version}/zookeeper-%{version}.jar %{buildroot}/opt/zookeeper
install -m644 $RPM_BUILD_DIR/zookeeper-%{version}/lib/*.jar %{buildroot}/opt/zookeeper

%clean
rm -rf $RPM_BUILD_ROOT

%pre

%post

%files
%defattr(-,root,root)
/opt/zookeeper/*.jar

%changelog
