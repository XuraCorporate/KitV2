#!/bin/bash

_SCRIPT=OMU

if [[ "$1" == "" ]]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete/Replace> [Instace to start with or replace to - default 1] [Path to the CSV Files - default "environment/omu" and it looks for admin.csv and sz.csv] [StackName - default omu]"
	exit 1
fi

_RCFILE=$1
_ACTION=$2
_INSTACE=${3-1}
_CSVFILEPATH=${4-environment/omu}
_STACKNAME=${5-omu}

if [ ! -e ${_RCFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "RC File does not exist."
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete/Replace> [Instace to start with or replace to - default 1] [Path to the CSV Files - default "environment/omu" and it looks for admin.csv and sz.csv] [StackName - default omu]"
	exit 1
fi

if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" && "${_ACTION}" != "Replace" ]]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "\"Replace\" - To replace a specific stack - This will delete it and then recreate it"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete/Replace> [Instace to start with or replace to - default 1] [Path to the CSV Files - default "environment/omu" and it looks for admin.csv and sz.csv] [StackName - default omu]"
	exit 1
fi

_ADMINCSVFILE=$(echo ${_CSVFILEPATH}/admin.csv)
_SZCSVFILE=$(echo ${_CSVFILEPATH}/sz.csv)

if [ ! -f ${_ADMINCSVFILE} ] || [ ! -r ${_ADMINCSVFILE} ] || [ ! -s ${_ADMINCSVFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "CSV File for Admin Network with mapping PortID,MacAddress,FixedIP does not exist."
	exit 1
fi

if [ ! -f ${_SZCSVFILE} ] || [ ! -r ${_SZCSVFILE} ] || [ ! -s ${_SZCSVFILE} ]
then
	echo "Wrapper for ${_SCRIPT} Unit Creation"
	echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP does not exist."
	exit 1
fi

source ${_RCFILE}

_GROUPS=./groups.tmp
nova server-group-list|grep Group|sort -k4|awk '{print $2}' > ${_GROUPS}
_GROUPNUMBER=$(cat ${_GROUPS}|wc -l)
for (( i=0 ; i < ${_GROUPNUMBER} ; i++ ))
do
	_GROUP[${i}]=$(sed -n -e $((${i}+1))p ${_GROUPS})
done
rm -f ${_GROUPS}

_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

#_TENANT_NETWORK_NAME=$(cat ../environment/common.yaml|awk '/tenant_network_name/ {print $2}')
#_TENANT_NETWORK_ID=$(neutron net-show --field id --format value ${_TENANT_NETWORK_NAME})

if  [[ "${_ACTION}" != "Replace" ]]
then
	cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	cat ../${_SZCSVFILE}|tail -n+${_INSTACE} > ../${_SZCSVFILE}.tmp
	IFS=","
	exec 3<../${_ADMINCSVFILE}.tmp
	exec 4<../${_SZCSVFILE}.tmp
	while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	do
		if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
		then 
			heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') \
			 --template-file ../templates/omu.yaml \
			 --environment-file ../environment/common.yaml \
	                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
	                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
	                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
	                 --parameters "admin_network_ip=${_ADMIN_IP}" \
	                 --parameters "sz_network_port=${_SZ_PORTID}" \
	                 --parameters "sz_network_mac=${_SZ_MAC}" \
	                 --parameters "sz_network_ip=${_SZ_IP}" \
	                 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
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
elif [[ "${_ACTION}" == "Replace" ]]
then
        sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} > ../${_ADMINCSVFILE}.tmp
        sed -n -e ${_INSTACE}p ../${_SZCSVFILE} > ../${_SZCSVFILE}.tmp
	IFS=","
	exec 3<../${_ADMINCSVFILE}.tmp
	exec 4<../${_SZCSVFILE}.tmp
	while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	do
		heat stack-delete ${_STACKNAME}${_INSTACE} || (echo "Error during Stack ${_ACTION}." ; exit 1)
		while :; do heat resource-list ${_STACKNAME}${_INSTACE} || break; done
                heat stack-create \
                 --template-file ../templates/omu.yaml \
                 --environment-file ../environment/common.yaml \
                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 ${_STACKNAME}${_INSTACE} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	done
fi
exec 3<&-
exec 4<&-
rm -f ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
cd ${_CURRENTDIR}

exit 0

