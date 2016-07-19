#!/bin/bash

function input_error_log {
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete/Replace> <CMS/LVU/OMU/VM-ASU/MAU> [Instace to start with or replace to - default 1] [Path to the CSV Files - default "environment/${_UNITLOWER}"] [StackName - default ${_UNITLOWER}]"
}

function create_update_cms {
	echo "Not yet implemented."
}

function create_update_lvu {
	echo "Not yet implemented."
}

function create_update_omu {
	if [[ "${_ACTION}" == "Replace" ]]
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
			init_omu Create
		done
	else
	        cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	        cat ../${_SZCSVFILE}|tail -n+${_INSTACE} > ../${_SZCSVFILE}.tmp
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
			init_omu ${_ACTION}
	        done
	fi
	exec 3<&-
	exec 4<&-
	rm -f ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

function init_omu {
	_COMMAND=${1}
	neutron port-update --no-security-groups ${_ADMIN_PORTID}
	neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
	neutron port-update --no-security-groups ${_SZ_PORTID}
	heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
	 --template-file ../templates/${_UNITLOWER}.yaml \
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
	_INSTACE=$(($_INSTACE+1))
}

function create_update_vmasu {
	echo "Not yet implemented."
}

function create_update_mau {
	echo "Not yet implemented."
}

_RCFILE=$1
_ACTION=$2
_UNIT=$3
_UNITLOWER=$(echo "${_UNIT}" | awk '{print tolower($0)}')
_INSTACE=${4-1}
_CSVFILEPATH=${5-environment/${_UNITLOWER}}
_STACKNAME=${6-${_UNITLOWER}}

if [[ "$1" == "" ]]
then
	input_error_log
	exit 1
fi

if [ ! -e ${_RCFILE} ]
then
	input_error_log
	echo "RC File does not exist."
	exit 1
fi

if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" && "${_ACTION}" != "Replace" ]]
then
	input_error_log
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "\"Replace\" - To replace a specific stack - This will delete it and then recreate it"
	exit 1
fi

if [[ "${_UNIT}" != "CMS" && "${_UNIT}" != "LVU" && "${_UNIT}" != "OMU" && "${_UNIT}" != "VM-ASU" && "${_UNIT}" != "MAU" ]]
then
	input_error_log
	echo "Unit type non valid."
	echo "It must be in the following format:"
	echo "\"CMS\""
	echo "\"LVU\""
	echo "\"OMU\""
	echo "\"VM-ASU\""
	echo "\"MAU\""
	exit 1
fi

_ADMINCSVFILE=$(echo ${_CSVFILEPATH}/admin.csv)
_SZCSVFILE=$(echo ${_CSVFILEPATH}/sz.csv)
_SIPINTCSVFILE=$(echo ${_CSVFILEPATH}/sip.csv)
_MEDIACSVFILE=$(echo ${_CSVFILEPATH}/media.csv)

if [ ! -f ${_ADMINCSVFILE} ] || [ ! -r ${_ADMINCSVFILE} ] || [ ! -s ${_ADMINCSVFILE} ]
then
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Admin Network with mapping PortID,MacAddress,FixedIP does not exist."
	exit 1
fi

if [ ! -f ${_SZCSVFILE} ] || [ ! -r ${_SZCSVFILE} ] || [ ! -s ${_SZCSVFILE} ] && [[ ! "${_UNIT}" == "MAU" ]]
then
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP does not exist."
	exit 1
fi

if [ ! -f ${_SIPINTCSVFILE} ] || [ ! -r ${_SIPINTCSVFILE} ] || [ ! -s ${_SIPINTCSVFILE} ] && [[ "${_UNIT}" == "CMS" ]]
then
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for SIP Internal Network with mapping Portid,MacAddress,FixedIP does not exist."
	exit 1
fi

if [ ! -f ${_MEDIACSVFILE} ] || [ ! -r ${_MEDIACSVFILE} ] || [ ! -s ${_MEDIACSVFILE} ] && [[ "${_UNIT}" == "CMS" ]]
then
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Media Network with mapping Portid,MacAddress,FixedIP does not exist."
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

if [[ "${_ACTION}" == "List" ]]
then
	for _STACKID in $(heat stack-list|awk '/'${_STACKNAME}'/ {print $2}')
	do
		heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKID} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	done
	cd ${_CURRENTDIR}
	exit 0
elif [[ "${_ACTION}" == "Delete" ]]
then
	for _STACKID in $(heat stack-list|awk '/'${_STACKNAME}'/ {print $2}')
	do
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKID} || (echo "Error during Stack ${_ACTION}." ; exit 1)
	done
	cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} > ../${_ADMINCSVFILE}.tmp
	IFS=","
	exec 3<../${_ADMINCSVFILE}.tmp
	while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
	do	
        	neutron port-update --no-security-groups ${_ADMIN_PORTID}
	done
	exec 3<&-
	rm -f ../${_ADMINCSVFILE}.tmp
	cd ${_CURRENTDIR}
	exit 0
elif [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Update" || "${_ACTION}" == "Replace" ]]
then
	if [[ ${_UNIT} == "CMS" ]]
	then
		create_update_cms
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "LVU" ]]
	then
		create_update_lvu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "OMU" ]]
	then
		create_update_omu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "VM-ASU" ]]
	then
		create_update_vmasu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "MAU" ]]
	then
		create_update_mau
		cd ${_CURRENTDIR}
		exit 0
	fi
fi
 
exit 0

