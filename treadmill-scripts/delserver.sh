#!/bin/bash
for server in "$@"
do
	treadmill admin aws instance delete ${server} && echo "${server} terminated"
        treadmill admin ldap server delete ${server} && echo "${server} removed from LDAP"
done
