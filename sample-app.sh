#!/bin/sh

# yum install atomic-enterprise-service-catalog-svcat

NAME=postgresql-instance-test
CLASS=postgresql-persistent
PLAN=default # this is the only one available for postgresql-persistent
DB_NAME=sampledb
DB_PASS=admin123
DB_USER=admin
VERSION=9.6

T=$(mktemp)

trap "rm -f $T" EXIT

cat<<EOF>$T
{
    "postgresql_database": "$DB_NAME",
    "postgresql_password": "$DB_PASS",
    "postgresql_user": "$DB_USER",
    "postgresql_version": "$VERSION"
}
EOF

svcat provision $NAME --plan $PLAN --class $CLASS --params-json "$(cat $T)"
