#!/bin/sh

NEW=$1

CURRENT_DEFAULT=$(oc get storageclass | fgrep '(default)')
: ${CURRENT_DEFAULT:=(none)}

if [ -z "$NEW" ] ; then
	echo "Usage: $0 NEW-StorageClass"
	echo "example:"
	echo "    $0 nfs-storage"
	echo
	echo "Current default: $CURRENT_DEFAULT"
	exit 1
fi

if [ "(none)" = "$CURRENT_DEFAULT" ] ; then
	echo "There is no default, so skipping changing of old default"
else
	set $CURRENT_DEFAULT
	if [ "$1" = "$NEW" ] ; then
		echo "[$NEW] is already the current default... nothing to do."
		exit 0
	fi
	echo "Unsetting [$1] as default"
	oc patch storageclass $1 -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "false"}}}'
fi

echo "Setting [$NEW] as default"
oc patch storageclass $NEW -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
