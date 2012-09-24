check_esx_datastores
====================

Nagios Plugin: Check the capacity/ usage of vsphere Datastores

NAME
    check_esx_datatore.pl

SYNOPSYS
    check_esx_datastore.pl -H <hostname> -u <root> -p <password> -w
    <warning> -c <critical>

DESCRIPTION
    check_esx_dataore.pl is an Nagios-Plugin checking the freespace of the
    Datatores of an vCenter or ESX(i).

OPTIONS
    -H Hostname or IP-Address of a vCenter or ESX(i). (required)

    -u Username (required)

    -p Password (required)

    -w Treshhold (Free Space in Percent) for warnings (INTEGER) (required)

    -c Treshhold (Free Space in Percent) for critical (INTEGER) (required)or

FILES
    check_esx_datastore.pl

AUTHOR
    Torge Gipp torge<at>tg432<dot>de
