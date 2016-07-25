#!/bin/bash
function netconfig {
	_SYSTEMDINIT=${1}
	_VLAN=${2}
	_MAC=${3}
	_IP=${4}
	_NETMASK=${5}
	_ETH=$(ip -oneline link|awk '/'${_MAC}'/ {print $2}'|sed "s/://g")
	_NETFILE="/etc/sysconfig/network-scripts/ifcfg-${_ETH}"
	touch ${_NETFILE}
	if [[ "${_VLAN}" == "none" ]]
	then
		echo "BOOTPROTO=static" >> ${_NETFILE}
		echo "DEVICE=${_ETH}" >> ${_NETFILE}
		echo "ONBOOT=yes" >> ${_NETFILE}
		echo "IPADDR=${_IP}" >> ${_NETFILE}
		echo "NETMASK=${_NETMASK}" >> ${_NETFILE}
		if [[ "${6}" != "" ]]
		then
			_GW=${6}
			echo "GATEWAY=${_GW}" >> ${_NETFILE}
		fi
		echo "TYPE=Ethernet" >> ${_NETFILE}
		if ${_SYSTEMDINIT}
		then
			ifdown ${_ETH} || true
			ifup ${_ETH} || (echo "could not configure the device ${_ETH}." ; exit 1)
		fi
	else
                echo "DEVICE=${_ETH}" >> ${_NETFILE}
                echo "TYPE=Ethernet" >> ${_NETFILE}
                echo "BOOTPROTO=static" >> ${_NETFILE}
                echo "ONBOOT=yes" >> ${_NETFILE}

		touch ${_NETFILE}.${_VLAN}
                echo "DEVICE=${_ETH}.${_VLAN}" >> ${_NETFILE}.${_VLAN}
                echo "BOOTPROTO=none" >> ${_NETFILE}.${_VLAN}
                echo "ONBOOT=yes" >> ${_NETFILE}.${_VLAN}
                echo "IPADDR=${_IP}" >> ${_NETFILE}.${_VLAN}
                echo "NETMASK=${_NETMASK}" >> ${_NETFILE}.${_VLAN}
                echo "USERCTL=no" >> ${_NETFILE}.${_VLAN}
                echo "VLAN=yes" >> ${_NETFILE}.${_VLAN}
                if [[ "${6}" != "" ]]
                then
                        _GW=${6}
                        echo "GATEWAY=${_GW}" >> ${_NETFILE}.${_VLAN}
                fi
                if ${_SYSTEMDINIT}
                then
                        systemctl restart network || (echo "could not configure the device ${_ETH}." ; exit 1)
                fi
	fi
}

_DEVMODE=_DEVMODE_

if $(echo "${_DEVMODE}" | awk '{print tolower($0)}')
then
        echo "root:Xur4"|chpasswd
        sed -e "s/^PasswordAuthentication.*$/PasswordAuthentication yes/g" -i /etc/ssh/sshd_config
        sed -e "s/^PermitRootLogin.*$/PermitRootLogin yes/g" -i /etc/ssh/sshd_config
        systemctl restart sshd || service sshd restart
fi

_SYSVINIT=$(pidof /sbin/init >/dev/null 2>&1 && echo true || echo false)
_SYSTEMD=$(pidof systemd >/dev/null 2>&1 && echo true || echo false)

for _OLDNET in $(ls /etc/sysconfig/network-scripts/ifcfg-*|grep -v ifcfg-lo)
do
	rm -f ${_OLDNET}
done
netconfig ${_SYSTEMD} _ADMIN_VLAN_ _ADMIN_MAC_ _ADMIN_IP_ _ADMIN_NETMASK_
netconfig ${_SYSTEMD} _SZ_VLAN_ _SZ_MAC_ _SZ_IP_ _SZ_NETMASK_
netconfig ${_SYSTEMD} _SIP_VLAN_ _SIP_MAC_ _SIP_IP_ _SIP_NETMASK_
netconfig ${_SYSTEMD} _MEDIA_VLAN_ _MEDIA_MAC_ _MEDIA_IP_ _MEDIA_NETMASK_ _MEDIA_GW_

cat > /etc/cloud/cloud.cfg.d/99_hostname.cfg << EOF
#cloud-config
hostname: _HOSTNAME_
EOF

_DOMAIN=_DOMAINNAME_
if [[ "${_DOMAIN}" != "none" ]]
then
	echo "fqdn: _HOSTNAME_${_DOMAIN}" >> /etc/cloud/cloud.cfg.d/99_hostname.cfg
else
	_DOMAIN=""
fi

cloud-init init
# RHEL 6.7 and 6.8 has the following bug - https://bugs.launchpad.net/cloud-init/+bug/1246485
sysctl -w kernel.hostname=_HOSTNAME_${_DOMAIN}
sed -e "s/^HOSTNAME=.*$/HOSTNAME=_HOSTNAME_${_DOMAIN}/g" -i /etc/sysconfig/network

if ${_SYSVINIT}
then
	service network restart || (echo "could not reconfigure the network." ; exit 1)
fi	

exit 0
