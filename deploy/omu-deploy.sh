#!/bin/bash

_SCRIPT=OMU

if [[ "$1" == "" ]]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> <ADMIN CSV File> <SZ CSV File> [StackName - default omu1]"
	exit 1
fi

_RCFILE=$1
_ACTION=$2
_ADMINCSVFILE=$3
_SZCSVFILE=$4
_STACKNAME=${5-omu}

if [ ! -e ${_RCFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "RC File does not exist."
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> [StackName]"
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
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> [StackName]"
	exit 1
fi

if [ ! -e ${_ADMINCSVFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "CSV File for Admin Network with mapping Portid,MacAddress,FixedIP does not exist."
	exit 1
fi

if [ ! -e ${_SZCSVFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP does not exist."
	exit 1
fi

source ${_RCFILE}

_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

_TENANT_NETWORK_NAME=$(cat ../environment/common.yaml|awk '/tenant_network_name/ {print $2}')
_TENANT_NETWORK_ID=$(neutron net-show --field id --format value ${_TENANT_NETWORK_NAME})

i=1
IFS=","
exec 3<../${_ADMINCSVFILE}
exec 4<../${_SZCSVFILE}
while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
do
	if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
	then
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') \
		 --template-file ../templates/omu.yaml \
		 --environment-file ../environment/common.yaml \
                 --parameters "admin_network_port=${_ADMIN_PORTID};sz_network_port=${_SZ_PORTID};tenant_network_id=${_TENANT_NETWORK_ID}" \
		${_STACKNAME}${i} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	elif [[ "${_ACTION}" != "List" ]]
	then
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKNAME}${i} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	else
		heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKNAME}${i} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	fi
	i=$(($i+1))
done
exec 3<&-
exec 4<&-

cd ${_CURRENTDIR}

exit 0

