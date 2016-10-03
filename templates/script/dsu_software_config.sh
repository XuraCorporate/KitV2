#!/bin/bash
function netconfig {
        _SYSTEMDINIT=${1}
        _MTU=${2}
        _VLAN=${3}
        _MAC=${4}
        _IP=${5}
        _NETMASK=${6}
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
                echo "MTU=${_MTU}" >> ${_NETFILE}
                if [[ "${7}" != "" ]]
                then
                        _GW=${7}
                        echo "GATEWAY=${_GW}" >> ${_NETFILE}
                        echo "DNS1=\"\"" >> ${_NETFILE}
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
                echo "MTU=${_MTU}" >> ${_NETFILE}.${_VLAN}
                echo "USERCTL=no" >> ${_NETFILE}.${_VLAN}
                echo "VLAN=yes" >> ${_NETFILE}.${_VLAN}
                if [[ "${7}" != "" ]]
                then
                        _GW=${7}
                        echo "GATEWAY=${_GW}" >> ${_NETFILE}.${_VLAN}
                        echo "DNS1=\"\"" >> ${_NETFILE}.${_VLAN}
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
# Clean resolv.conf
> /etc/resolv.conf
# Configure the Network
netconfig ${_SYSTEMD} _ADMIN_MTU_ _ADMIN_VLAN_ _ADMIN_MAC_ _ADMIN_IP_ _ADMIN_NETMASK_ _ADMIN_GW_
netconfig ${_SYSTEMD} _SZ_MTU_ _SZ_VLAN_ _SZ_MAC_ _SZ_IP_ _SZ_NETMASK_

sed -e "s/#UseDNS yes/UseDNS no/g" -i /etc/ssh/sshd_config
systemctl restart sshd || service sshd restart

cat > /etc/cloud/cloud.cfg.d/99_hostname.cfg << EOF
#cloud-config
hostname: _HOSTNAME_
EOF

_DOMAIN=_DOMAINNAME_
if [[ "${_DOMAIN}" != "none" ]]
then
        echo "fqdn: _HOSTNAME_${_DOMAIN}" >> /etc/cloud/cloud.cfg.d/99_hostname.cfg
        cat > /etc/hosts << EOF
127.0.0.1       localhost localhost.localdomain localhost4 localhost4.localdomain4
::1             localhost localhost.localdomain localhost6 localhost6.localdomain6
_SZ_IP_   _HOSTNAME_ _HOSTNAME_${_DOMAIN}
EOF
else
        _DOMAIN=""
        cat > /etc/hosts << EOF
127.0.0.1       localhost localhost.localdomain localhost4 localhost4.localdomain4
::1             localhost localhost.localdomain localhost6 localhost6.localdomain6
_SZ_IP_   _HOSTNAME_
EOF
fi

cloud-init init
# RHEL 6.7 and 6.8 has the following bug - https://bugs.launchpad.net/cloud-init/+bug/1246485
sysctl -w kernel.hostname=_HOSTNAME_${_DOMAIN}
sed -e "s/^HOSTNAME=.*$/HOSTNAME=_HOSTNAME_${_DOMAIN}/g" -i /etc/sysconfig/network

if ${_SYSVINIT}
then
	service network restart || (echo "could not reconfigure the network." ; exit 1)
fi

#DSU Cinder Volume Config
_CINDERVOL=$(ls /dev/[sv]d*|grep -v "$(lsblk|grep -i swap|grep -o -E "[sv]d[a-z]{1,3}")")
if [[ "${_CINDERVOL}" != "" ]]
then
	if [[ "$(file -Ls ${_CINDERVOL})" == "${_CINDERVOL}: data" ]]
	then
		echo "Creating a new GPT Partition Table"
		parted ${_CINDERVOL} mklabel gpt
		echo "Creating a new LVM Partition"
		parted ${_CINDERVOL} mkpart lvm 0% 100%
		echo "Creating a new Volume Group"
		vgcreate vgdata "${_CINDERVOL}1"

		echo "Create Logical Volumes in Thin Provisioning"
		lvcreate -l 3%VG --thinpool ubr 		vgdata
		lvcreate -l 3%VG --thinpool sw_cfg 		vgdata
		lvcreate -l 3%VG --thinpool httpd 		vgdata
		lvcreate -l 3%VG --thinpool act_logs 		vgdata
		lvcreate -l 3%VG --thinpool cdr 		vgdata
		lvcreate -l 3%VG --thinpool stat 		vgdata
		lvcreate -l 3%VG --thinpool spm 		vgdata
		lvcreate -l 3%VG --thinpool data_cons 		vgdata
		lvcreate -l 3%VG --thinpool PC 			vgdata
		lvcreate -l 3%VG --thinpool PL 			vgdata
		lvcreate -l 3%VG --thinpool PM 			vgdata
		lvcreate -l 3%VG --thinpool lgw 		vgdata
		lvcreate -l 3%VG --thinpool oracle_data 	vgdata
		lvcreate -l 3%VG --thinpool oracle_archives 	vgdata
		lvcreate -l 3%VG --thinpool oracle_logs 	vgdata
		lvcreate -l 3%VG --thinpool oracle_backup 	vgdata
		lvcreate -l 3%VG --thinpool vote1 		vgdata
		lvcreate -l 3%VG --thinpool vote2 		vgdata
		lvcreate -l 3%VG --thinpool vote3 		vgdata
		lvcreate -l 3%VG --thinpool mboxes_metadata 	vgdata
		lvcreate -l 3%VG --thinpool mboxes0 		vgdata
		lvcreate -l 3%VG --thinpool mboxes1 		vgdata
		lvcreate -l 3%VG --thinpool mboxes2 		vgdata
		lvcreate -l 3%VG --thinpool mboxes3 		vgdata
		lvcreate -l 3%VG --thinpool mboxes4 		vgdata
		lvcreate -l 3%VG --thinpool mboxes5 		vgdata
		lvcreate -l 3%VG --thinpool mboxes6 		vgdata
		lvcreate -l 3%VG --thinpool mboxes7 		vgdata
		lvcreate -l 3%VG --thinpool mboxes8 		vgdata
		lvcreate -l 3%VG --thinpool mboxes9 		vgdata
		lvcreate -l 3%VG --thinpool MIPSlogs 		vgdata
		lvcreate -l 3%VG --thinpool criticalpath 	vgdata

		echo "Create the Logical Volumes' File System"
		mkfs.ext4 /dev/mapper/vgdata-ubr
                mkfs.ext4 /dev/mapper/vgdata-sw_cfg
                mkfs.ext4 /dev/mapper/vgdata-httpd
                mkfs.ext4 /dev/mapper/vgdata-act_logs
                mkfs.ext4 /dev/mapper/vgdata-cdr
                mkfs.ext4 /dev/mapper/vgdata-stat
                mkfs.ext4 /dev/mapper/vgdata-spm
                mkfs.ext4 /dev/mapper/vgdata-data_cons
                mkfs.ext4 /dev/mapper/vgdata-PC
                mkfs.ext4 /dev/mapper/vgdata-PL
                mkfs.ext4 /dev/mapper/vgdata-PM
                mkfs.ext4 /dev/mapper/vgdata-lgw
                mkfs.ext4 /dev/mapper/vgdata-oracle_data
                mkfs.ext4 /dev/mapper/vgdata-oracle_archives
                mkfs.ext4 /dev/mapper/vgdata-oracle_logs
                mkfs.ext4 /dev/mapper/vgdata-oracle_backup
                mkfs.ext4 /dev/mapper/vgdata-vote1
                mkfs.ext4 /dev/mapper/vgdata-vote2
                mkfs.ext4 /dev/mapper/vgdata-vote3
                mkfs.ext4 /dev/mapper/vgdata-mboxes_metadata
                mkfs.ext4 /dev/mapper/vgdata-mboxes0
                mkfs.ext4 /dev/mapper/vgdata-mboxes1
                mkfs.ext4 /dev/mapper/vgdata-mboxes2
                mkfs.ext4 /dev/mapper/vgdata-mboxes3
                mkfs.ext4 /dev/mapper/vgdata-mboxes4
                mkfs.ext4 /dev/mapper/vgdata-mboxes5
                mkfs.ext4 /dev/mapper/vgdata-mboxes6
                mkfs.ext4 /dev/mapper/vgdata-mboxes7
                mkfs.ext4 /dev/mapper/vgdata-mboxes8
                mkfs.ext4 /dev/mapper/vgdata-mboxes9
                mkfs.ext4 /dev/mapper/vgdata-MIPSlogs
                mkfs.ext4 /dev/mapper/vgdata-criticalpath
	else
		echo "Enabling the Volume Group on the device"
		vgchange -ay
	fi

	echo "Creating the Folders"
	mkdir -p /vol/vzw_ubr
	mkdir -p /vol/vzw_fs/SW_CFG
	mkdir -p /vol/vzw_fs/HTTP
	mkdir -p /vol/vzw_files/AL
	mkdir -p /vol/vzw_files/CDR
	mkdir -p /vol/vzw_files/STATISTICS
	mkdir -p /vol/vzw_files/SPM
	mkdir -p /vol/vzw_files/DC
	mkdir -p /vol/vzw_files/PC
	mkdir -p /vol/vzw_files/PL
	mkdir -p /vol/vzw_files/PM
	mkdir -p /vol/vzw_lvu
	mkdir -p /vol/vzw_oracle_data
	mkdir -p /vol/vzw_oracle_archives
	mkdir -p /vol/vzw_oracle_redo_logs
	mkdir -p /vol/vzw_oracle_backup
	mkdir -p /vol/vzw_vote1
	mkdir -p /vol/vzw_vote2
	mkdir -p /vol/vzw_vote3
	mkdir -p /vol/vzw_mtd
	mkdir -p /vol/vzw_mbx0
	mkdir -p /vol/vzw_mbx1
	mkdir -p /vol/vzw_mbx2
	mkdir -p /vol/vzw_mbx3
	mkdir -p /vol/vzw_mbx4
	mkdir -p /vol/vzw_mbx5
	mkdir -p /vol/vzw_mbx6
	mkdir -p /vol/vzw_mbx7
	mkdir -p /vol/vzw_mbx8
	mkdir -p /vol/vzw_mbx9
	mkdir -p /vol/vzw_mips_logs
	mkdir -p /vol/vzw_mips_conf

	echo "Mounting each mount point"
	mount /dev/mapper/vgdata-ubr 			/vol/vzw_ubr
	mount /dev/mapper/vgdata-sw_cfg			/vol/vzw_fs/SW_CFG
	mount /dev/mapper/vgdata-httpd			/vol/vzw_fs/HTTP
	mount /dev/mapper/vgdata-act_logs		/vol/vzw_files/AL
	mount /dev/mapper/vgdata-cdr			/vol/vzw_files/CDR
	mount /dev/mapper/vgdata-star			/vol/vzw_files/STATISTICS
	mount /dev/mapper/vgdata-spm			/vol/vzw_files/SPM
	mount /dev/mapper/vgdata-data_cons		/vol/vzw_files/DC
	mount /dev/mapper/vgdata-PC			/vol/vzw_files/PC
	mount /dev/mapper/vgdata-PL			/vol/vzw_files/PL
	mount /dev/mapper/vgdata-PM			/vol/vzw_files/PM
	mount /dev/mapper/vgdata-lgw			/vol/vzw_lvu
	mount /dev/mapper/vgdata-oracle_data		/vol/vzw_oracle_data
	mount /dev/mapper/vgdata-oracle_archives	/vol/vzw_oracle_archives
	mount /dev/mapper/vgdata-oracle_logs		/vol/vzw_oracle_redo_logs
	mount /dev/mapper/vgdata-oracle_backup		/vol/vzw_oracle_backup
	mount /dev/mapper/vgdata-vote1			/vol/vzw_vote1
	mount /dev/mapper/vgdata-vote2			/vol/vzw_vote2
	mount /dev/mapper/vgdata-vote3			/vol/vzw_vote3
	mount /dev/mapper/vgdata-mboxes_metadata	/vol/vzw_mtd
	mount /dev/mapper/vgdata-mboxes0		/vol/vzw_mbx0
	mount /dev/mapper/vgdata-mboxes1		/vol/vzw_mbx1
	mount /dev/mapper/vgdata-mboxes2		/vol/vzw_mbx2
	mount /dev/mapper/vgdata-mboxes3		/vol/vzw_mbx3
	mount /dev/mapper/vgdata-mboxes4		/vol/vzw_mbx4
	mount /dev/mapper/vgdata-mboxes5		/vol/vzw_mbx5
	mount /dev/mapper/vgdata-mboxes6		/vol/vzw_mbx6
	mount /dev/mapper/vgdata-mboxes7		/vol/vzw_mbx7
	mount /dev/mapper/vgdata-mboxes8		/vol/vzw_mbx8
	mount /dev/mapper/vgdata-mboxes9		/vol/vzw_mbx9
	mount /dev/mapper/vgdata-MIPSlogs		/vol/vzw_mips_logs
	mount /dev/mapper/vgdata-criticalpath		/vol/vzw_mips_conf

	if [[ "$(grep vgdata /dev/fstab)" == "" ]]
	then
		cat /etc/mtab|grep vgdata|sed "s/rw/defaults/g"|tee -a /etc/fstab
	fi
else
	echo "Did not find any available Cinder Volume to be used"
fi

exit 0
