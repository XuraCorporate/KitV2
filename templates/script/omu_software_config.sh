#!/bin/bash
function netconfig {
	_SYSTEMDINIT=${1}
	_MAC=${2}
	_IP=${3}
	_NETMASK=${4}
	_ETH=$(ip -oneline link|awk '/'${_MAC}'/ {print $2}'|sed "s/://g")
	_NETFILE="/etc/sysconfig/network-scripts/ifcfg-${_ETH}"
	rm -f  ${_NETFILE} || true
	touch ${_NETFILE}
	echo "BOOTPROTO=static" >> ${_NETFILE}
	echo "DEVICE=${_ETH}" >> ${_NETFILE}
	echo "ONBOOT=yes" >> ${_NETFILE}
	echo "IPADDR=${_IP}" >> ${_NETFILE}
	echo "NETMASK=${_NETMASK}" >> ${_NETFILE}
	if [[ "${5}" != "" ]]
	then
		_GW=${5}
		echo "GATEWAY=${_GW}" >> ${_NETFILE}
	fi
	echo "TYPE=Ethernet" >> ${_NETFILE}
	if ${_SYSTEMDINIT}
	then
		ifdown ${_ETH} || true
		ifup ${_ETH} || (echo "could not configure the device ${_ETH}." ; exit 1)
	fi
}

_DEVMODE=_DEVMODE_

if $(echo "${_DEVMODE}" | awk '{print tolower($0)}')
then
        echo "root:Xur4"|chpasswd
fi

_SYSVINIT=$(pidof /sbin/init >/dev/null 2>&1 && echo true || echo false)
_SYSTEMD=$(pidof systemd >/dev/null 2>&1 && echo true || echo false)

netconfig ${_SYSTEMD} _ADMIN_MAC_ _ADMIN_IP_ _ADMIN_NETMASK_ _ADMIN_GW_
netconfig ${_SYSTEMD} _SZ_MAC_ _SZ_IP_ _SZ_NETMASK_


if ${_SYSVINIT}
then
	service network restart || (echo "could not reconfigure the network." ; exit 1)
fi	

exit 0
