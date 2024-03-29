#!/bin/bash

# Set file locations
KEYS=${HOME}/dockerkeys

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# Get docker container ID for isamconfig container
ISAMCONFIG="$(oc get --no-headers=true pods -l isamapp=isam-config -o custom-columns=:metadata.name)"

# Copy the current snapshots from isamconfig container
SNAPSHOTS=`oc exec ${ISAMCONFIG} ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
oc cp ${ISAMCONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR/$SNAPSHOT
done

# Get docker container ID for openldap container
OPENLDAP="$(oc get --no-headers=true pods -l app=openldap -o custom-columns=:metadata.name)"

# Extract LDAP Data from OpenLDAP
oc exec ${OPENLDAP} -- ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
oc exec ${OPENLDAP} -- ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="$(oc get --no-headers=true pods -l app=postgresql -o custom-columns=:metadata.name)"
oc exec ${POSTGRESQL} -- /usr/local/bin/pg_dump isam > $TMPDIR/isam.db

cp -R ${KEYS} ${TMPDIR}

tar -cf sam-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
