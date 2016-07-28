#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#####
# Function to give the usage help
#####
function input_error_log {
	echo -e ${RED}
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete/Replace> <CMS/LVU/OMU/VM-ASU/MAU> [Instace to start with or replace to - default 1] [Path to the CSV Files - default "environment/${_UNITLOWER}"] [StackName - default ${_UNITLOWER}]"
}

#####
# Function to exit in case of error
#####
function exit_for_error {
	#####
	# The message to print
	#####
        _MESSAGE=$1

	#####
	# If perform a change directory in case something has failed in order to not be in deploy dir
	#####
        _CHANGEDIR=$2

	#####
	# If hard "exit 1"
	# If break "break"
	# If soft no exit
	#####
	_EXIT=${3-hard}
        if ${_CHANGEDIR}
        then
                cd ${_CURRENTDIR}
        fi
	if [[ "${_EXIT}" == "hard" ]]
	then
		rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp ../${_SIPCSVFILE}.tmp ../${_MEDIACSVFILE}.tmp >/dev/null 2>&1
		rm -rf ${_ADMINCSVFILE}.tmp ${_SZCSVFILE}.tmp ${_SIPCSVFILE}.tmp ${_MEDIACSVFILE}.tmp >/dev/null 2>&1
		echo -e "${RED}${_MESSAGE}${NC}"
        	exit 1
	elif [[ "${_EXIT}" == "break" ]]
	then
		echo -e "${RED}${_MESSAGE}${NC}"
		break
	elif [[ "${_EXIT}" == "soft" ]]
	then
		echo -e "${YELLOW}${_MESSAGE}${NC}"
	fi
}

#####
# Function to Create CMS Unit
#####
function create_update_cms {
        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load the CSV Files
                #####
                sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e ${_INSTACE}p ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
                sed -n -e ${_INSTACE}p ../${_SIPCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SIPCSVFILE}.tmp
                sed -n -e ${_INSTACE}p ../${_MEDIACSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_MEDIACSVFILE}.tmp
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                exec 5<../${_SIPCSVFILE}.tmp
                exec 6<../${_MEDIACSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4 && read _SIP_PORTID _SIP_MAC _SIP_IP <&5 && read _MEDIA_PORTID _MEDIA_MAC _MEDIA_IP <&6
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_cms Create
                done
        else
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
                cat ../${_SIPCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SIPCSVFILE}.tmp
                cat ../${_MEDIACSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_MEDIACSVFILE}.tmp

                #####
                # Verify that in the CSV files there are the same amout of Ports
                #####
                _ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
                _SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
                _SIP_PORT_NUMBER=$(cat ../${_SIPCSVFILE}.tmp|wc -l)
                _MEDIA_PORT_NUMBER=$(cat ../${_MEDIACSVFILE}.tmp|wc -l)
                echo -e -n "Validating number of Ports ...\t\t"
                if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
                then
                        exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
                fi
                if [[ "${_ADMIN_PORT_NUMBER}" != "${_SIP_PORT_NUMBER}" ]]
                then
                        exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and SIP, which has ${_SIP_PORT_NUMBER} Port(s)" true hard
                fi
                if [[ "${_ADMIN_PORT_NUMBER}" != "${_MEDIA_PORT_NUMBER}" ]]
                then
                        exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Media, which has ${_MEDIA_PORT_NUMBER} Port(s)" true hard
                fi
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                exec 5<../${_SIPCSVFILE}.tmp
                exec 6<../${_MEDIACSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4 && read _SIP_PORTID _SIP_MAC _SIP_IP <&5 && read _MEDIA_PORTID _MEDIA_MAC _MEDIA_IP <&6
                do

                        #####
                        # After the checks create the CMS with the right parameters
                        #####
                        init_cms ${_ACTION}
                done
        fi
        exec 3<&-
        exec 4<&-
        exec 5<&-
        exec 6<&-
        rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp ../${_SIPCSVFILE}.tmp ../${_MEDIACSVFILE}.tmp
}

#####
# Function to initialize the creation of the CMS Unit
#####
function init_cms {
        _COMMAND=${1}

        #####
        # Verify if the stack already exist. A double create will fail
        # Verify if the stack exist in order to be updated
        #####
        echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
		mac_validation ${_ADMIN_MAC}
		mac_validation ${_SZ_MAC}
		mac_validation ${_SIP_MAC}
		mac_validation ${_MEDIA_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
                port_validation ${_SZ_PORTID} ${_SZ_MAC}
                port_validation ${_SIP_PORTID} ${_SIP_MAC}
                port_validation ${_MEDIA_PORTID} ${_MEDIA_MAC}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}
		ip_validation ${_SIP_IP}
		ip_validation ${_MEDIA_IP}

                #####
                # Update the port securtiy group
                #####
                neutron port-update --no-security-groups ${_ADMIN_PORTID}
                neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
                neutron port-update --no-security-groups ${_SZ_PORTID}
                neutron port-update --no-security-groups ${_SIP_PORTID}
                neutron port-update --no-security-groups ${_MEDIA_PORTID}

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - SIP Port ID, Mac Address and IP Address
                # - MEDIA Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		_LOCAL_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
		_SOURCE_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
		if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
		then
			exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
		elif [[ "${_SOURCE_BOOT}" == "cinder" ]]
		then
			_HOT="../templates/${_UNITLOWER}_cinder_source.yaml"
		elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
		then
			_HOT="../templates/${_UNITLOWER}.yaml"
		else
			_HOT="../templates/${_UNITLOWER}_volume.yaml"
		fi

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../environment/common.yaml \
                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "sip_network_port=${_SIP_PORTID}" \
                 --parameters "sip_network_mac=${_SIP_MAC}" \
                 --parameters "sip_network_ip=${_SIP_IP}" \
                 --parameters "media_network_port=${_MEDIA_PORTID}" \
                 --parameters "media_network_mac=${_MEDIA_MAC}" \
                 --parameters "media_network_ip=${_MEDIA_IP}" \
                 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
                 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTACE=$(($_INSTACE+1))
}

#####
# Function to Create LVU
#####
function create_update_lvu {
        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load the CSV Files
                #####
                sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e ${_INSTACE}p ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_lvu Create
                done
        else
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp

                #####
                # Verify that in the CSV files there are the same amout of Ports
                #####
                _ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
                _SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
                echo -e -n "Validating number of Ports ...\t\t"
                if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
                then
                        exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
                fi
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do

                        #####
                        # After the checks create the LVU with the right parameters
                        #####
                        init_lvu ${_ACTION}
                done
        fi
        exec 3<&-
        exec 4<&-
        rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to initialize the creation of the LVU Unit
#####
function init_lvu {
        _COMMAND=${1}

        #####
        # Verify if the stack already exist. A double create will fail
        # Verify if the stack exist in order to be updated
        #####
        echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
                mac_validation ${_ADMIN_MAC}
                mac_validation ${_SZ_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
                port_validation ${_SZ_PORTID} ${_SZ_MAC}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}

                #####
                # Update the port securtiy group
                #####
                neutron port-update --no-security-groups ${_ADMIN_PORTID}
                neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
                neutron port-update --no-security-groups ${_SZ_PORTID}

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
                _LOCAL_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source.yaml"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}.yaml"
                else
                        _HOT="../templates/${_UNITLOWER}_volume.yaml"
                fi

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../environment/common.yaml \
                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
                 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTACE=$(($_INSTACE+1))
}

#####
# Function to Create OMU Unit
#####
function create_update_omu {
	if [[ "${_ACTION}" == "Replace" ]]
	then
		#####
		# Load the CSV Files
		#####
	        sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
	        sed -n -e ${_INSTACE}p ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
			#####
			# Delete the old stack
			#####
	                heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

			#####
			# Wait until has been deleted
			#####
	                while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

			#####
			# Create it again
			#####
			init_omu Create
		done
	else
	        cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
	        cat ../${_SZCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp

		#####
		# Verify that in the CSV files there are the same amout of Ports
		#####
		_ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
		_SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
		echo -e -n "Validating number of Ports ...\t\t"
		if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
		then
			exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Load the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do

			#####
			# After the checks create the OMU with the right parameters
			#####
			init_omu ${_ACTION}
	        done
	fi
	exec 3<&-
	exec 4<&-
	rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to initialize the creation of the OMU Unit
#####
function init_omu {
	_COMMAND=${1}

	#####
	# Verify if the stack already exist. A double create will fail
	# Verify if the stack exist in order to be updated
	#####
	echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else 
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Verify the port status one by one
		#####
                mac_validation ${_ADMIN_MAC}
                mac_validation ${_SZ_MAC}

		port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
		port_validation ${_SZ_PORTID} ${_SZ_MAC}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}

		#####
		# Update the port securtiy group
		#####
		neutron port-update --no-security-groups ${_ADMIN_PORTID}
		neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
		neutron port-update --no-security-groups ${_SZ_PORTID}

		#####
		# Load the Stack and pass the following information
		# - Admin Port ID, Mac Address and IP Address
		# - SZ Port ID, Mac Address and IP Address
		# - Hostname
		# - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
		#####
                _LOCAL_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source.yaml"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}.yaml"
                else
                        _HOT="../templates/${_UNITLOWER}_volume.yaml"
                fi

		heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
		 --template-file ${_HOT} \
		 --environment-file ../environment/common.yaml \
		 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
		 --parameters "admin_network_port=${_ADMIN_PORTID}" \
		 --parameters "admin_network_mac=${_ADMIN_MAC}" \
		 --parameters "admin_network_ip=${_ADMIN_IP}" \
		 --parameters "sz_network_port=${_SZ_PORTID}" \
		 --parameters "sz_network_mac=${_SZ_MAC}" \
		 --parameters "sz_network_ip=${_SZ_IP}" \
		 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
		 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
		#--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	fi
	_INSTACE=$(($_INSTACE+1))
}

#####
# Function to Create VM-ASU
#####
function create_update_vmasu {
        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load the CSV Files
                #####
                sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e ${_INSTACE}p ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_vmasu Create
                done
        else
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp

                #####
                # Verify that in the CSV files there are the same amout of Ports
                #####
                _ADMIN_PORT_NUMBER=$(cat ../${_ADMINCSVFILE}.tmp|wc -l)
                _SZ_PORT_NUMBER=$(cat ../${_SZCSVFILE}.tmp|wc -l)
                echo -e -n "Validating number of Ports ...\t\t"
                if [[ "${_ADMIN_PORT_NUMBER}" != "${_SZ_PORT_NUMBER}" ]]
                then
                        exit_for_error "Error, Inconsitent port number between Admin, which has ${_ADMIN_PORT_NUMBER} Port(s), and Secure Zone, which has ${_SZ_PORT_NUMBER} Port(s)" true hard
                fi
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do

                        #####
                        # After the checks create the VM-ASU with the right parameters
                        #####
                        init_vmasu ${_ACTION}
                done
        fi
        exec 3<&-
        exec 4<&-
        rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to initialize the creation of the VM-ASU Unit
#####
function init_vmasu {
        _COMMAND=${1}

        #####
        # Verify if the stack already exist. A double create will fail
        # Verify if the stack exist in order to be updated
        #####
        echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
                mac_validation ${_ADMIN_MAC}
                mac_validation ${_SZ_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}
                port_validation ${_SZ_PORTID} ${_SZ_MAC}

                ip_validation ${_ADMIN_IP}
                ip_validation ${_SZ_IP}

                #####
                # Update the port securtiy group
                #####
                neutron port-update --no-security-groups ${_ADMIN_PORTID}
                neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}
                neutron port-update --no-security-groups ${_SZ_PORTID}

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
                _LOCAL_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source.yaml"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}.yaml"
                else
                        _HOT="../templates/${_UNITLOWER}_volume.yaml"
                fi

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../environment/common.yaml \
                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
                 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTACE=$(($_INSTACE+1))
}

#####
# Function to Create MAU
#####
function create_update_mau {
        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load the CSV Files
                #####
                sed -n -e ${_INSTACE}p ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTACE} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_mau Create
                done
        else
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp

                #####
                # Load the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
                do

                        #####
                        # After the checks create the MAU with the right parameters
                        #####
                        init_mau ${_ACTION}
                done
        fi
        exec 3<&-
        rm -rf ../${_ADMINCSVFILE}.tmp
}

#####
# Function to initialize the creation of the MAU Unit
#####
function init_mau {
        _COMMAND=${1}

        #####
        # Verify if the stack already exist. A double create will fail
        # Verify if the stack exist in order to be updated
        #####
        echo -e -n "Verifing if ${_STACKNAME}${_INSTACE} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTACE} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTACE} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
                mac_validation ${_ADMIN_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC}

                ip_validation ${_ADMIN_IP}

                #####
                # Update the port securtiy group
                #####
                neutron port-update --no-security-groups ${_ADMIN_PORTID}
                neutron port-update --security-group $(cat ../environment/common.yaml|awk '/admin_security_group_name/ {print $2}') ${_ADMIN_PORTID}

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
                _LOCAL_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../environment/common.yaml|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source.yaml"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}.yaml"
                else
                        _HOT="../templates/${_UNITLOWER}_volume.yaml"
                fi

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../environment/common.yaml \
                 --parameters "unit_name=${_STACKNAME}${_INSTACE}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "antiaffinity_group=${_GROUP[ $((${_INSTACE}%${_GROUPNUMBER})) ]}" \
                 ${_STACKNAME}${_INSTACE} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTACE=$(($_INSTACE+1))
}

#####
# Function to valide various things
# - Given Flavor
# - Given Image Name and Image ID
#####
function validation {
	_UNITTOVALIDATE=$1
	_IMAGE=$(cat ../environment/common.yaml|grep "$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_image"|grep -v -E "image_id|image_source"|awk '{print $2}'|sed "s/\"//g")
	_IMAGEID=$(cat ../environment/common.yaml|awk '/'$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_image_id'/ {print $2}'|sed "s/\"//g")
	_VOLUMEID=$(cat ../environment/common.yaml|awk '/'$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_volume_id'/ {print $2}'|sed "s/\"//g")
	_FLAVOR=$(cat ../environment/common.yaml|awk '/'$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_flavor_name'/ {print $2}'|sed "s/\"//g")
	_SOURCE=$(cat ../environment/common.yaml|grep "$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_image_source"|awk '{print $2}'|sed "s/\"//g")

	#####
	# Check the Image Id and the Image Name is the same 
	#####
	if [[ "${_SOURCE}" == "glance" ]]
	then
		echo -e -n "Validating chosen Glance Image ${_IMAGE} ...\t\t"
		glance image-show ${_IMAGEID}|grep "${_IMAGE}" >/dev/null 2>&1 || exit_for_error "Error, Image for Unit ${_UNITTOVALIDATE} not present or mismatch between ID and Name." true hard
		echo -e "${GREEN} [OK]${NC}"
	elif [[ "${_SOURCE}" == "cinder" ]]
	then
		echo -e -n "Validating chosen Cinder Volume ${_VOLUMEID} ...\t\t"
		cinder show ${_VOLUMEID} >/dev/null 2>&1 || exit_for_error "Error, Volume for Unit ${_UNITTOVALIDATE} not present." true hard
		echo -e "${GREEN} [OK]${NC}"

		echo -e -n "Validating given volume size ...\t\t"
		_VOLUME_SIZE=$(cinder show ${_VOLUMEID}|awk '/size/ {print $4}'|sed "s/ //g")
		_VOLUME_GIVEN_SIZE=$(cat ../environment/common.yaml|awk '/'$(echo "${_UNITTOVALIDATE}" | awk '{print tolower($0)}')_volume_size'/ {print $2}'|sed "s/\"//g")
		if (( "${_VOLUME_GIVEN_SIZE}" < "${_VOLUME_SIZE}" ))
		then
			exit_for_error "Error, Volume for Unit ${_UNITTOVALIDATE} with UUID ${_VOLUMEID} has a size of ${_VOLUME_SIZE} which cannot fit into the given input size of ${_VOLUME_GIVEN_SIZE}." true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Creating a test volume to verify that the snapshotting works
		# https://wiki.openstack.org/wiki/CinderSupportMatrix
		# e.g. Feature not available with standard NFS driver
		#####
		echo -e -n "Validating if volume cloning/snapshotting is available ...\t\t"
		#####
		# Creating a new volume from the given one
		#####
		cinder create --source-volid ${_VOLUMEID} --display-name "temp-${_VOLUMEID}" ${_VOLUME_SIZE} >/dev/null 2>&1 || exit_for_error "Error, During volume cloning/snapshotting creation." true hard
		
		#####
		# Wait until the volume created is in error or available states
		#####
		while :
		do
			_VOLUME_SOURCE_STATUS=$(cinder show temp-${_VOLUMEID}|grep status|grep -v extended_status|awk '{print $4}')
			if [[ "${_VOLUME_SOURCE_STATUS}" == "available" ]]
			then
				cinder delete temp-${_VOLUMEID} >/dev/null 2>&1
				echo -e "${GREEN} [OK]${NC}"
				break
			elif [[ "${_VOLUME_SOURCE_STATUS}" == "error" ]]
			then
				cinder delete temp-${_VOLUMEID} >/dev/null 2>&1
				exit_for_error "Error, the system does not support volume cloning/snapshotting." true hard
			fi
		done
	else
		exit_for_error "Error, Invalid Image Source option, can be \"glance\" or \"cinder\"." true hard
	fi

	#####
	# Check the given flavor is available
	#####
	echo -e -n "Validating chosen Flavor ${_FLAVOR} ...\t\t"
	nova flavor-show "${_FLAVOR}" >/dev/null 2>&1 || exit_for_error "Error, Flavor for Unit ${_UNITTOVALIDATE} not present." true hard
	echo -e "${GREEN} [OK]${NC}"
}

#####
# Function to valide the Network
# - Does it exist?
# - Does the given VLAN ID is valid?
#####
function net_validation {
        _UNITTOVALIDATE=$1
	_NET=$2
        _NETWORK=$(cat ../environment/common.yaml|awk '/'${_NET}'_network_name/ {print $2}'|sed "s/\"//g")
        _VLAN=$(cat ../environment/common.yaml|awk '/'${_NET}'_network_vlan/ {print $2}'|sed "s/\"//g")

	#####
	# Check the Network exist
	#####
	echo -e -n "Validating chosen Network ${_NETWORK} ...\t\t"
        neutron net-show "${_NETWORK}" >/dev/null 2>&1 || exit_for_error "Error, ${_NET} Network is not present." true hard
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check the VLAN ID is corret
	# - none
	# - between 1 to 4096
	#####
	echo -e -n "Validating VLAN ${_VLAN} for chosen Network ${_NETWORK} ...\t\t"
        if [[ "${_VLAN}" != "none" ]]
        then
                if (( ${_VLAN} < 1 || ${_VLAN} > 4096 ))
                then
                        exit_for_error "Error, The VLAN ID ${_VLAN} for the ${_NET} Network is not valid. Acceptable values: \"none\" or a number between 1 to 4096." true hard
                fi
        fi
	echo -e "${GREEN} [OK]${NC}"
}

#####
# Function to valide the given Neutron Port
# - Does it exist?
# - Is it available?
# - Does the given Mac Address match with the Port Mac Address?
#####
function port_validation {
	_PORT=$1
	_MAC=$2

	#####
	# Check of the port exist
	#####
	echo -e -n "Validating Port ${_PORT} exist ...\t\t"
	neutron port-show ${_PORT} >/dev/null 2>&1 || exit_for_error "Error, Port with ID ${_PORT} does not exist." false break
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check if the port is in use
	#####
	echo -e -n "Validating Port ${_PORT} is not in use ...\t\t"
	if [[ "$(neutron port-show --field device_id --format value ${_PORT})" != "" ]]
	then
		exit_for_error "Error, Port with ID ${_PORT} is in use." false break
	fi
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Check if the Mac address is the same from the given one
	#####
	echo -e -n "Validating Port ${_PORT} MAC Address ...\t\t"
	if [[ "$(neutron port-show --field mac_address --format value ${_PORT})" != "${_MAC}" ]]
	then
		exit_for_error "Error, Port with ID ${_PORT} has a different MAC Address than the one provided into the CSV file." false break
	fi
	echo -e "${GREEN} [OK]${NC}"
}

function ip_validation {
        _IP=$1

        #####
        # Check if the given IP or NetMask is valid
        #####
        echo -e -n "Validating ${_IP} ...\t\t"
	echo ${_IP}|grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" >/dev/null 2>&1
        if [[ "${?}" != "0" ]]
        then
                exit_for_error "Error, The Address ${_IP} is not valid." true hard
        fi
	if (( "$(echo ${_IP}|awk -F "." '{print $1}')" < "1" || "$(echo ${_IP}|awk -F "." '{print $1}')" > "255" ))
        then
                exit_for_error "Error, The Address ${_IP} is not valid." true hard
        fi
	if (( "$(echo ${_IP}|awk -F "." '{print $2}')" < "0" || "$(echo ${_IP}|awk -F "." '{print $2}')" > "255" ))
        then
                exit_for_error "Error, The Address ${_IP} is not valid." true hard
        fi
	if (( "$(echo ${_IP}|awk -F "." '{print $3}')" < "0" || "$(echo ${_IP}|awk -F "." '{print $3}')" > "255" ))
        then
                exit_for_error "Error, The Address ${_IP} is not valid." true hard
        fi
	if (( "$(echo ${_IP}|awk -F "." '{print $4}')" < "0" || "$(echo ${_IP}|awk -F "." '{print $4}')" > "255" ))
        then
                exit_for_error "Error, The Address ${_IP} is not valid." true hard
        fi
        echo -e "${GREEN} [OK]${NC}"

}

function mac_validation {
        _MAC=$1

        #####
        # Check if the given IP or NetMask is valid
        #####
        echo -e -n "Validating ${_MAC} ...\t\t"
        echo ${_MAC}|grep -E "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})" >/dev/null 2>&1
        if [[ "${?}" != "0" ]]
        then
                exit_for_error "Error, The Port Mac Address ${_MAC} is not valid." true hard
        fi
        echo -e "${GREEN} [OK]${NC}"

}
#####
# Write the input args into variable
#####
_RCFILE=$1
_ACTION=$2
_UNIT=$3
_UNITLOWER=$(echo "${_UNIT}" | awk '{print tolower($0)}')
_INSTACE=${4-1}
_CSVFILEPATH=${5-environment/${_UNITLOWER}}
_STACKNAME=${6-${_UNITLOWER}}

#####
# Verity if any input values are present
#####
if [[ "$1" == "" ]]
then
	input_error_log
        echo -e ${NC}
	exit 1
fi

#####
# Check RC File
#####
if [ ! -e ${_RCFILE} ]
then
	input_error_log
	echo "OpenStack RC environment file does not exist."
        echo -e ${NC}
	exit 1
fi

#####
# Check Action Name
#####
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
        echo -e ${NC}
	exit 1
fi

#####
# Check Unit Name
#####
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
        echo -e ${NC}
	exit 1
fi

#####
# Just write into variables the CSV Files
#####
_ADMINCSVFILE=$(echo ${_CSVFILEPATH}/admin.csv)
_SZCSVFILE=$(echo ${_CSVFILEPATH}/sz.csv)
_SIPCSVFILE=$(echo ${_CSVFILEPATH}/sip.csv)
_MEDIACSVFILE=$(echo ${_CSVFILEPATH}/media.csv)

#####
# Check if the Admin CSV File
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
echo -e -n "Verifing if Admin CSV file is good ...\t\t"
if [ ! -f ${_ADMINCSVFILE} ] || [ ! -r ${_ADMINCSVFILE} ] || [ ! -s ${_ADMINCSVFILE} ]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Admin Network with mapping PortID,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
echo -e "${GREEN} [OK]${NC}"

#####
# Check if the Secure Zone CSV File except for the MAU Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
if [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e -n "Verifing if Secure Zone CSV file is good ...\t\t"
fi
if [ ! -f ${_SZCSVFILE} ] || [ ! -r ${_SZCSVFILE} ] || [ ! -s ${_SZCSVFILE} ] && [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
if [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Check if the SIP CSV File for the CMS Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e -n "Verifing if SIP CSV file is good ...\t\t"
fi
if [ ! -f ${_SIPINTCSVFILE} ] || [ ! -r ${_SIPINTCSVFILE} ] || [ ! -s ${_SIPINTCSVFILE} ] && [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for SIP Internal Network with mapping Portid,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Check if the Media CSV File for the CMS Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
#####
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e -n "Verifing if Media CSV file is good ...\t\t"
fi
if [ ! -f ${_MEDIACSVFILE} ] || [ ! -r ${_MEDIACSVFILE} ] || [ ! -s ${_MEDIACSVFILE} ] && [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Media Network with mapping Portid,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Verify binary
#####
_BINS="heat nova neutron glance cinder"
for _BIN in ${_BINS}
do
	echo -e -n "Verifing ${_BIN} binary ...\t\t"
	which ${_BIN} > /dev/null 2>&1 || exit_for_error "Error, Cannot find python${_BIN}-client." false
	echo -e "${GREEN} [OK]${NC}"
done
echo -e -n "Verifing git binary ...\t\t"
which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find git and any changes will be commited." false soft
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifing dos2unix binary ...\t\t"
which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find dos2unix binary, please install it first." false hard
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifing md5sum binary ...\t\t"
which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find md5sum binary." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Convert every files exept the GITs one
#####
echo -e -n "Eventually converting files in Standard Unix format ...\t\t"
for _FILE in $(find . -not \( -path ./.git -prune \) -type f)
do
        _MD5BEFORE=$(md5sum ${_FILE}|awk '{print $1}')
        dos2unix ${_FILE} >/dev/null 2>&1 || exit_for_error "Error, Cannot convert to Unix format some files" false hard
        _MD5AFTER=$(md5sum ${_FILE}|awk '{print $1}')
        #####
        # Verify the MD5 after and before the dos2unix - eventually commit the changes
        #####
        if [[ "${_MD5BEFORE}" != "${_MD5AFTER}" ]]
        then
                git add ${_FILE} >/dev/null 2>&1
                git commit -m "Auto Commit Dos2Unix for file ${_FILE} conversion" >/dev/null 2>&1
        fi
done
echo -e "${GREEN} [OK]${NC}"

#####
# Unload any previous loaded environment file
#####
for _ENV in $(env|grep ^OS|awk -F "=" '{print $1}')
do
        unset ${_ENV}
done

#####
# Load environment file
#####
echo -e -n "Loading environment file ...\t\t"
source ${_RCFILE}
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the given credential are valid. This will also check if the use can contact Heat
#####
echo -e -n "Verifing OpenStack credential ...\t\t"
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the PreparetionStack is available.
#####
echo -e -n "Verifing Preparetion Stack ...\t\t"
heat resource-list PreparetionStack > /dev/null 2>&1 || exit_for_error "Error, Cannot find the Preparetion Stack, so create it first." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the Admin Security Group is available
#####
echo -e -n "Verifing Admin Security Group ...\t\t"
neutron security-group-show $(cat environment/common.yaml|awk '/admin_security_group_name/ {print $2}') >/dev/null 2>&1 || exit_for_error "Error, Cannot find the Admin Security Group." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the Server Groups are available and
# - Load them into an array
#####
echo -e -n "Verifing (Anti-)Affinity rules ...\t\t"
_GROUPS=./groups.tmp
nova server-group-list|grep ServerGroup|sort -k4|awk '{print $2}' > ${_GROUPS}
_GROUPNUMBER=$(cat ${_GROUPS}|wc -l)
if [[ "${_GROUPNUMBER}" == "0" && "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
then
	exit_for_error "Error, There is any available (Anti-)Affinity Group." false hard
fi
for (( i=0 ; i < ${_GROUPNUMBER} ; i++ ))
do
	_GROUP[${i}]=$(sed -n -e $((${i}+1))p ${_GROUPS})
done
rm -rf ${_GROUPS}
echo -e "${GREEN} [OK]${NC}"

#####
# Change directory into the deploy one
#####
_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

#_TENANT_NETWORK_NAME=$(cat ../environment/common.yaml|awk '/tenant_network_name/ {print $2}')
#_TENANT_NETWORK_ID=$(neutron net-show --field id --format value ${_TENANT_NETWORK_NAME})

#####
# Initiate the actions phase
#####
echo -e "${GREEN}Performing Action ${_ACTION}${NC}"
if [[ "${_ACTION}" == "List" ]]
then
	#####
	# Stack List for each Stack of the same Unit 
	#####
	for _STACKID in $(heat stack-list|awk '/'${_STACKNAME}'/ {print $2}')
	do
		heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKID} || exit_for_error "Error, During Stack ${_ACTION}." true hard
	done
	cd ${_CURRENTDIR}
	exit 0
elif [[ "${_ACTION}" == "Delete" ]]
then
	#####
	# Delete each Stack of the same Unit
	#####
	for _STACKID in $(heat stack-list|awk '/'${_STACKNAME}'/ {print $2}')
	do
		heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKID} || exit_for_error "Error, During Stack ${_ACTION}." true hard
	done

	#####
	# Release the the port cleaning up the security group
	#####
	cat ../${_ADMINCSVFILE}|tail -n+${_INSTACE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
	IFS=","
	exec 3<../${_ADMINCSVFILE}.tmp
	while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
	do	
		echo "Cleaning up Neutron port"
        	neutron port-update --no-security-groups ${_ADMIN_PORTID}
	done
	exec 3<&-
	rm -rf ../${_ADMINCSVFILE}.tmp
	cd ${_CURRENTDIR}
	exit 0
elif [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Update" || "${_ACTION}" == "Replace" ]]
then
	#####
	# Validate the Input values (falvor, image etc)
	#####
	echo "Validation phase"
	validation ${_UNIT}

	if [[ ${_UNIT} == "CMS" ]]
	then
		#####
		# Validate the network for CMS
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz
		net_validation ${_UNIT} media
		net_validation ${_UNIT} sip

		#####
		# Validate the network for CMS
		#####
		create_update_cms
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "LVU" ]]
	then
		#####
		# Validate the network for LVU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Init the LVU Creation
		#####
		create_update_lvu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "OMU" ]]
	then
		#####
		# Validate the network for OMU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Ini the OMU Creation
		#####
		create_update_omu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "VM-ASU" ]]
	then
		#####
		# Validate the network for VM-ASU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Init the VM-ASU Creation
		#####
		create_update_vmasu
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "MAU" ]]
	then
		#####
		# Validate the network for MAU
		#####
		net_validation ${_UNIT} admin

		#####
		# Init the MAU Creation
		#####
		create_update_mau
		cd ${_CURRENTDIR}
		exit 0
	fi
fi
 
exit 0

