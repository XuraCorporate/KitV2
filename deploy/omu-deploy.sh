#!/bin/bash

_SCRIPT=OMU

if [[ "$1" == "" ]]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> <ADMIN CSV File> <SZ CSV File> [StackName - default omu1] [Instace to start with - default 1]"
	exit 1
fi

_RCFILE=$1
_ACTION=$2
_ADMINCSVFILE=$3
_SZCSVFILE=$4
_STACKNAME=${5-omu}
_INSTACE=${6-1}

if [ ! -e ${_RCFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "RC File does not exist."
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> <ADMIN CSV File> <SZ CSV File> [StackName - default omu1] [Instace to start with - default 1]"
	exit 1
fi

if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" ]]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> <ADMIN CSV File> <SZ CSV File> [StackName - default omu1] [Instace to start with - default 1]"
	exit 1
fi

if [ ! -f ${_ADMINCSVFILE} ] || [ ! -r ${_ADMINCSVFILE} ] || [ ! -s ${_ADMINCSVFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "CSV File for Admin Network with mapping Portid,MacAddress,FixedIP,Netmask,Gateway does not exist."
	exit 1
fi

if [ ! -f ${_SZCSVFILE} ] || [ ! -r ${_SZCSVFILE} ] || [ ! -s ${_SZCSVFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP,Netmask does not exist."
	exit 1
fi

source ${_RCFILE}

_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

#_TENANT_NETWORK_NAME=$(cat ../environment/common.yaml|awk '/tenant_network_name/ {print $2}')
#_TENANT_NETWORK_ID=$(neutron net-show --field id --format value ${_TENANT_NETWORK_NAME})

IFS=","
exec 3<../${_ADMINCSVFILE}
exec 4<../${_SZCSVFILE}
while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP _ADMIN_NETMASK _ADMIN_GW <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP _SZ_NETMASK <&4
do
	if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
	then 
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') \
		 --template-file ../templates/omu.yaml \
		 --environment-file ../environment/common.yaml \
                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "admin_mac_address=${_ADMIN_MAC}" \
                 --parameters "admin_ip_address=${_ADMIN_IP}" \
                 --parameters "admin_netmask=${_ADMIN_NETMASK}" \
                 --parameters "admin_gw=${_ADMIN_GW}" \
                 --parameters "sz_mac_address=${_SZ_MAC}" \
                 --parameters "sz_ip_address=${_SZ_IP}" \
                 --parameters "sz_netmask=${_SZ_NETMASK}" \
		 ${_STACKNAME}${_INSTACE} || (echo "Error during Stack ${_ACTION}." ; exit 1)
                 #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	elif [[ "${_ACTION}" != "List" ]]
	then
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKNAME}${_INSTACE} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	else
		heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKNAME}${_INSTACE} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	fi
	_INSTACE=$(($_INSTACE+1))
done
exec 3<&-
exec 4<&-

cd ${_CURRENTDIR}

exit 0

