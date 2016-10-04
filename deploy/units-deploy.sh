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
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete/Replace> <CMS/LVU/OMU/VM-ASU/MAU/DSU/SMU> [Instance to start with - default 1] [Instance to end with - default false aka continue until the end of the CSV file] [Path to the CSV Files - default "environment/${_UNITLOWER}"] [StackName - default ${_UNITLOWER}]"
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
        if ${_CHANGEDIR} && [[ "${_EXIT}" == "hard" ]]
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
	#####
	# Load the CSV Files for all of the Instances
	#####
	if [[ "${_INSTANCEEND}" == "false" ]]
	then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
                cat ../${_SIPCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SIPCSVFILE}.tmp
                cat ../${_MEDIACSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_MEDIACSVFILE}.tmp
	else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SIPCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SIPCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_MEDIACSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_MEDIACSVFILE}.tmp
	fi

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


        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load into environment the CSV Files
                #####
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
                        heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_cms Create
                done
        else
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                exec 5<../${_SIPCSVFILE}.tmp
                exec 6<../${_MEDIACSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4 && read _SIP_PORTID _SIP_MAC _SIP_IP <&5 && read _MEDIA_PORTID _MEDIA_MAC _MEDIA_IP <&6
                do
			if [[ "${_ACTION}" != "Delete" ]]
			then
				#####
				# After the checks create the CMS with the right parameters
				#####
				init_cms ${_ACTION}
			else
			        #####
			        # Release the port cleaning up the security group
			        #####
			        echo -e -n "Cleaning up Neutron Port ...\t\t"
                		port_securitygroupcleanup ${_ADMIN_PORTID} false
                		port_securitygroupcleanup ${_SZ_PORTID} false
                		port_securitygroupcleanup ${_SIP_PORTID} false
                		port_securitygroupcleanup ${_MEDIA_PORTID} false
        			echo -e "${GREEN} [OK]${NC}"
			        #####
			        # Delete Stack
			        #####
				heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
        			_INSTANCESTART=$(($_INSTANCESTART+1))
			fi
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
        echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
		mac_validation ${_ADMIN_MAC}
		mac_validation ${_SZ_MAC}
		mac_validation ${_SIP_MAC}
		mac_validation ${_MEDIA_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}
                port_validation ${_SZ_PORTID} ${_SZ_MAC} ${_ACTION}
                port_validation ${_SIP_PORTID} ${_SIP_MAC} ${_ACTION}
                port_validation ${_MEDIA_PORTID} ${_MEDIA_MAC} ${_ACTION}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}
		ip_validation ${_SIP_IP}
		ip_validation ${_MEDIA_IP}

                #####
                # Update the port securtiy group
                #####
		echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
		port_securitygroupcleanup ${_ADMIN_PORTID} false
		port_securitygroup ${_ADMIN_PORTID} \
			$(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
			true # This is a true since in production this port will be VIRTIO
		port_securitygroup ${_SZ_PORTID} \
			$(cat ../${_ENV}|awk '/sz_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/sz_security_group_name/ {print $2}') \
			false # This is a false since in production this port will be SR-IOV
		port_securitygroup ${_SIP_PORTID} \
			$(cat ../${_ENV}|awk '/sip_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/sip_security_group_name/ {print $2}') \
			false # This is a false since in production this port will be SR-IOV
		port_securitygroup ${_MEDIA_PORTID} \
			$(cat ../${_ENV}|awk '/media_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/media_security_group_name/ {print $2}') \
			false # This is a false since in production this port will be SR-IOV
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - SIP Port ID, Mac Address and IP Address
                # - MEDIA Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
		_LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
		_SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
		_SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
		if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
		then
			exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
		elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
		then
			exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
		fi	

		if [[ "${_SOURCE_BOOT}" == "cinder" ]]
		then
			_HOT="../templates/${_UNITLOWER}_cinder_source"
		elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
		then
			_HOT="../templates/${_UNITLOWER}"
		else
			_HOT="../templates/${_UNITLOWER}_volume"
		fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
		then
			_SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
		elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
		then
			_HOT=$(echo ${_HOT}_no_server_group)
		elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
		then
			_SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
			if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
			then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
				_HOT=$(echo ${_HOT}_no_server_group)
			fi
		fi

		_HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
                _ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
                _ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
                if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_INDEX=${_INSTANCESTART}
                fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
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
                 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
                 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTANCESTART=$(($_INSTANCESTART+1))
}

#####
# Function to Create LVU
#####
function create_update_lvu {
        #####
        # Load the CSV Files for all of the Instances
        #####
        if [[ "${_INSTANCEEND}" == "false" ]]
        then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
        else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
        fi

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
        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_lvu Create
                done
        else
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        if [[ "${_ACTION}" != "Delete" ]]
                        then
                                #####
                                # After the checks create the LVU with the right parameters
                                #####
                                init_lvu ${_ACTION}
                        else
                                #####
                                # Release the port cleaning up the security group
                                #####
                                echo -e -n "Cleaning up Neutron Port ...\t\t"
                                port_securitygroupcleanup ${_ADMIN_PORTID} false
                		port_securitygroupcleanup ${_SZ_PORTID} false
				echo -e "${GREEN} [OK]${NC}"
                                #####
                                # Delete Stack
                                #####
                                heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
                                _INSTANCESTART=$(($_INSTANCESTART+1))
                        fi
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
        echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
                mac_validation ${_ADMIN_MAC}
                mac_validation ${_SZ_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}
                port_validation ${_SZ_PORTID} ${_SZ_MAC} ${_ACTION}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}

                #####
                # Update the port securtiy group
                #####
                echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
                port_securitygroupcleanup ${_ADMIN_PORTID} false
                port_securitygroup ${_ADMIN_PORTID} \
                        $(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
                        true # This is a true since in production this port will be VIRTIO
                port_securitygroup ${_SZ_PORTID} \
                        $(cat ../${_ENV}|awk '/sz_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/sz_security_group_name/ {print $2}') \
                        false # This is a false since in production this port will be SR-IOV
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
                _LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                _SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
                then
                        exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
                fi

                if [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}"
                else
                        _HOT="../templates/${_UNITLOWER}_volume"
                fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
                then
                        _SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
                elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
                then
                        _HOT=$(echo ${_HOT}_no_server_group)
                elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
                then
                        _SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
                        if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
                        then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
                                _HOT=$(echo ${_HOT}_no_server_group)
                        fi
                fi

                _HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
                _ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
                _ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
                if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_INDEX=${_INSTANCESTART}
                fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
                 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTANCESTART=$(($_INSTANCESTART+1))
}

#####
# Function to Create OMU Unit
#####
function create_update_omu {
        #####
        # Load the CSV Files for all of the Instances
        #####
        if [[ "${_INSTANCEEND}" == "false" ]]
        then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
        else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
        fi

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
	if [[ "${_ACTION}" == "Replace" ]]
	then
		#####
		# Load into environment the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
			#####
			# Delete the old stack
			#####
	                heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

			#####
			# Wait until has been deleted
			#####
	                while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

			#####
			# Create it again
			#####
			init_omu Create
		done
	else
		#####
		# Load into environment the CSV Files
		#####
	        IFS=","
	        exec 3<../${_ADMINCSVFILE}.tmp
	        exec 4<../${_SZCSVFILE}.tmp
	        while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
	        do
                        if [[ "${_ACTION}" != "Delete" ]]
                        then
                                #####
                                # After the checks create the OMU with the right parameters
                                #####
                                init_omu ${_ACTION}
                        else
                                #####
                                # Release the port cleaning up the security group
                                #####
                                echo -e -n "Cleaning up Neutron Port ...\t\t"
                                port_securitygroupcleanup ${_ADMIN_PORTID} false
                		port_securitygroupcleanup ${_SZ_PORTID} false
                                echo -e "${GREEN} [OK]${NC}"
                                #####
                                # Delete Stack
                                #####
                                heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
                                _INSTANCESTART=$(($_INSTANCESTART+1))
                        fi
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
	echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else 
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Verify the port status one by one
		#####
                mac_validation ${_ADMIN_MAC}
                mac_validation ${_SZ_MAC}

		port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}
		port_validation ${_SZ_PORTID} ${_SZ_MAC} ${_ACTION}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}

		#####
		# Update the port securtiy group
		#####
                echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
                port_securitygroupcleanup ${_ADMIN_PORTID} false
                port_securitygroup ${_ADMIN_PORTID} \
                        $(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
                        true # This is a true since in production this port will be VIRTIO
                port_securitygroup ${_SZ_PORTID} \
                        $(cat ../${_ENV}|awk '/sz_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/sz_security_group_name/ {print $2}') \
                        false # This is a false since in production this port will be SR-IOV
                echo -e "${GREEN} [OK]${NC}"

		#####
		# Load the Stack and pass the following information
		# - Admin Port ID, Mac Address and IP Address
		# - SZ Port ID, Mac Address and IP Address
		# - Hostname
		# - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
		#####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
                _LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                _SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
                then
                        exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
                fi

                if [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}"
                else
                        _HOT="../templates/${_UNITLOWER}_volume"
                fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
                then
                        _SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
                elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
                then
                        _HOT=$(echo ${_HOT}_no_server_group)
                elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
                then
                        _SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
                        if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
                        then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
                                _HOT=$(echo ${_HOT}_no_server_group)
                        fi
                fi

                _HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
                _ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
                _ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
                if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_INDEX=${_INSTANCESTART}
                fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

		heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
		 --template-file ${_HOT} \
		 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
		 --parameters "admin_network_port=${_ADMIN_PORTID}" \
		 --parameters "admin_network_mac=${_ADMIN_MAC}" \
		 --parameters "admin_network_ip=${_ADMIN_IP}" \
		 --parameters "sz_network_port=${_SZ_PORTID}" \
		 --parameters "sz_network_mac=${_SZ_MAC}" \
		 --parameters "sz_network_ip=${_SZ_IP}" \
		 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
		 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
		#--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
	fi
	_INSTANCESTART=$(($_INSTANCESTART+1))
}

#####
# Function to Create VM-ASU
#####
function create_update_vmasu {
        #####
        # Load the CSV Files for all of the Instances
        #####
        if [[ "${_INSTANCEEND}" == "false" ]]
        then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
        else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
        fi

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
        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_vmasu Create
                done
        else
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        if [[ "${_ACTION}" != "Delete" ]]
                        then
                                #####
                                # After the checks create the VM-ASU with the right parameters
                                #####
                                init_vmasu ${_ACTION}
                        else
                                #####
                                # Release the port cleaning up the security group
                                #####
                                echo -e -n "Cleaning up Neutron Port ...\t\t"
                                port_securitygroupcleanup ${_ADMIN_PORTID} false
                		port_securitygroupcleanup ${_SZ_PORTID} false
                                echo -e "${GREEN} [OK]${NC}"
                                #####
                                # Delete Stack
                                #####
                                heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
                                _INSTANCESTART=$(($_INSTANCESTART+1))
                        fi
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
        echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
                mac_validation ${_ADMIN_MAC}
                mac_validation ${_SZ_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}
                port_validation ${_SZ_PORTID} ${_SZ_MAC} ${_ACTION}

                ip_validation ${_ADMIN_IP}
                ip_validation ${_SZ_IP}

                #####
                # Update the port securtiy group
                #####
                echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
                port_securitygroupcleanup ${_ADMIN_PORTID} false
                port_securitygroup ${_ADMIN_PORTID} \
                        $(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
                        true # This is a true since in production this port will be VIRTIO
                port_securitygroup ${_SZ_PORTID} \
                        $(cat ../${_ENV}|awk '/sz_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/sz_security_group_name/ {print $2}') \
                        false # This is a false since in production this port will be SR-IOV
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
                _LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                _SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
                then
                        exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
                fi

                if [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}"
                else
                        _HOT="../templates/${_UNITLOWER}_volume"
                fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
                then
                        _SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
                elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
                then
                        _HOT=$(echo ${_HOT}_no_server_group)
                elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
                then
                        _SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
                        if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
                        then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
                                _HOT=$(echo ${_HOT}_no_server_group)
                        fi
                fi

                _HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
                _ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
                _ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
                if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_INDEX=${_INSTANCESTART}
                fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
                 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTANCESTART=$(($_INSTANCESTART+1))
}

#####
# Function to Create MAU
#####
function create_update_mau {
        #####
        # Load the CSV Files for all of the Instances
        #####
        if [[ "${_INSTANCEEND}" == "false" ]]
        then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
        else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
        fi

        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_mau Create
                done
        else
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3
                do
                        if [[ "${_ACTION}" != "Delete" ]]
                        then
                                #####
                                # After the checks create the MAU with the right parameters
                                #####
                                init_mau ${_ACTION}
                        else
                                #####
                                # Release the port cleaning up the security group
                                #####
                                echo -e -n "Cleaning up Neutron Port ...\t\t"
                                port_securitygroupcleanup ${_ADMIN_PORTID} false
                                echo -e "${GREEN} [OK]${NC}"
                                #####
                                # Delete Stack
                                #####
                                heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
                                _INSTANCESTART=$(($_INSTANCESTART+1))
                        fi
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
        echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
                mac_validation ${_ADMIN_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}

                ip_validation ${_ADMIN_IP}

                #####
                # Update the port securtiy group
                #####
                echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
                port_securitygroupcleanup ${_ADMIN_PORTID} false
                port_securitygroup ${_ADMIN_PORTID} \
                        $(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
                        $(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
                        true # This is a true since in production this port will be VIRTIO
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
                _LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                _SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
                _SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
                if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
                elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
                then
                        exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
                fi

                if [[ "${_SOURCE_BOOT}" == "cinder" ]]
                then
                        _HOT="../templates/${_UNITLOWER}_cinder_source"
                elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
                then
                        _HOT="../templates/${_UNITLOWER}"
                else
                        _HOT="../templates/${_UNITLOWER}_volume"
                fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
                then
                        _SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
                elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
                then
                        _HOT=$(echo ${_HOT}_no_server_group)
                elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
                then
                        _SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
                        if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
                        then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
                                _HOT=$(echo ${_HOT}_no_server_group)
                        fi
                fi

                _HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
                _ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
                _ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
                if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_INDEX=${_INSTANCESTART}
                fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
                 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTANCESTART=$(($_INSTANCESTART+1))
}

#####
# Function to Create DSU Unit
#####
function create_update_dsu {
	#####
	# Load the CSV Files for all of the Instances
	#####
	if [[ "${_INSTANCEEND}" == "false" ]]
	then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
	else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
	fi

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


        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_dsu Create
                done
        else
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
			if [[ "${_ACTION}" != "Delete" ]]
			then
				#####
				# After the checks create the DSU with the right parameters
				#####
				init_dsu ${_ACTION}
			else
			        #####
			        # Release the port cleaning up the security group
			        #####
			        echo -e -n "Cleaning up Neutron Port ...\t\t"
                		port_securitygroupcleanup ${_ADMIN_PORTID} false
                		port_securitygroupcleanup ${_SZ_PORTID} false
        			echo -e "${GREEN} [OK]${NC}"
			        #####
			        # Delete Stack
			        #####
				heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
        			_INSTANCESTART=$(($_INSTANCESTART+1))
			fi
                done
        fi
        exec 3<&-
        exec 4<&-
        rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to initialize the creation of the DSU Unit
#####
function init_dsu {
        _COMMAND=${1}

        #####
        # Verify if the stack already exist. A double create will fail
        # Verify if the stack exist in order to be updated
        #####
        echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
		mac_validation ${_ADMIN_MAC}
		mac_validation ${_SZ_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}
                port_validation ${_SZ_PORTID} ${_SZ_MAC} ${_ACTION}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}

                #####
                # Update the port securtiy group
                #####
		echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
		port_securitygroupcleanup ${_ADMIN_PORTID} false
		port_securitygroup ${_ADMIN_PORTID} \
			$(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
			true # This is a true since in production this port will be VIRTIO
		port_securitygroup ${_SZ_PORTID} \
			$(cat ../${_ENV}|awk '/sz_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/sz_security_group_name/ {print $2}') \
			false # This is a false since in production this port will be SR-IOV
        echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
		_LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
		_SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
		_SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
		if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
		then
			exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
		elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
		then
			exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
		fi	

		if [[ "${_SOURCE_BOOT}" == "cinder" ]]
		then
			_HOT="../templates/${_UNITLOWER}_cinder_source"
		elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
		then
			_HOT="../templates/${_UNITLOWER}"
		else
			_HOT="../templates/${_UNITLOWER}_volume"
		fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
		then
			_SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
		elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
		then
			_HOT=$(echo ${_HOT}_no_server_group)
		elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
		then
			_SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
			if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
			then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
				_HOT=$(echo ${_HOT}_no_server_group)
			fi
		fi

		_HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the Cinder Volume to be used for persistent data ...\t\t"
                if $(cat ../${_ENV}|awk '/dsu_persistent_volume_mount/ {print $2}'|awk '{print tolower($0)}')
                then
                        heat resource-show PreparetionStack DSUPersistentVolume >/dev/null 2>&1 || exit_for_error "Error, No Volume available for persistent data." false soft
                        _VOLID=$(heat resource-show PreparetionStack DSUPersistentVolume|grep physical_resource_id|awk '{print $4}')
                        _VOLIDSTATUS=$(cinder show ${_VOLID}|grep " status "|awk '{print $4}')
                        if [[ "${_VOLIDSTATUS}" == "available" ]]
                        then
                                _VOLIDAVAILABLE=true
                        else
                                _VOLIDAVAILABLE=false
                        fi
                fi
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
                _ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
                _ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
                if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_INDEX=${_INSTANCESTART}
                fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
                 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
		
		#####
		# Function to attach the persistent volume only when the VM has been created
		#####
		if ${_VOLIDAVAILABLE} && [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]]
		then
                	echo -e -n "Waiting instance do be ready to attach persistent volume ...\t\t"
			#####
			# Function to wait until the new instance is ready
			#####
			while :
			do
				_STACKSTATUS=$(heat resource-list ${_STACKNAME}${_INSTANCESTART})
				_VMID=$(echo "${_STACKSTATUS}"|grep "OS::Nova::Server"|awk '{print $4}')
				echo "${_STACKSTATUS}"|grep "OS::Nova::Server"|grep "_COMPLETE" && break
			done >/dev/null 2>&1
                	echo -e "${GREEN} [OK]${NC}"

                	echo -e -n "Attaching persistent volume to instance ...\t\t"
			nova volume-attach ${_VMID} ${_VOLID} >/dev/null 2>&1 || exit_for_error "Error, Cannot attach the persistent volume." false soft
                	echo -e "${GREEN} [OK]${NC}"
		fi
        fi
        _INSTANCESTART=$(($_INSTANCESTART+1))
}

#####
# Function to Create SMU Unit
#####
function create_update_smu {
	#####
	# Load the CSV Files for all of the Instances
	#####
	if [[ "${_INSTANCEEND}" == "false" ]]
	then
                cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
	else
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
                sed -n -e "${_INSTANCESTART},${_INSTANCEEND}p" ../${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
	fi

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


        if [[ "${_ACTION}" == "Replace" ]]
        then
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
                        #####
                        # Delete the old stack
                        #####
                        heat stack-delete ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} 2>/dev/null || exit_for_error "Error, During Stack ${_ACTION}." true soft

                        #####
                        # Wait until has been deleted
                        #####
                        while :; do heat resource-list ${_STACKNAME}${_INSTANCESTART} >/dev/null 2>&1 || break; done

                        #####
                        # Create it again
                        #####
                        init_smu Create
                done
        else
                #####
                # Load into environment the CSV Files
                #####
                IFS=","
                exec 3<../${_ADMINCSVFILE}.tmp
                exec 4<../${_SZCSVFILE}.tmp
                while read _ADMIN_PORTID _ADMIN_MAC _ADMIN_IP <&3 && read _SZ_PORTID _SZ_MAC _SZ_IP <&4
                do
			if [[ "${_ACTION}" != "Delete" ]]
			then
				#####
				# After the checks create the DSU with the right parameters
				#####
				init_smu ${_ACTION}
			else
			        #####
			        # Release the port cleaning up the security group
			        #####
			        echo -e -n "Cleaning up Neutron Port ...\t\t"
                		port_securitygroupcleanup ${_ADMIN_PORTID} false
                		port_securitygroupcleanup ${_SZ_PORTID} false
        			echo -e "${GREEN} [OK]${NC}"
			        #####
			        # Delete Stack
			        #####
				heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." false soft
        			_INSTANCESTART=$(($_INSTANCESTART+1))
			fi
                done
        fi
        exec 3<&-
        exec 4<&-
        rm -rf ../${_ADMINCSVFILE}.tmp ../${_SZCSVFILE}.tmp
}

#####
# Function to initialize the creation of the SMU Unit
#####
function init_smu {
        _COMMAND=${1}

        #####
        # Verify if the stack already exist. A double create will fail
        # Verify if the stack exist in order to be updated
        #####
        echo -e -n "Verifying if ${_STACKNAME}${_INSTANCESTART} is already loaded ...\t\t"
        heat resource-list ${_STACKNAME}${_INSTANCESTART} > /dev/null 2>&1
        _STATUS=${?}
        if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} already exist." false soft
        elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
        then
                exit_for_error "Error, The Stack ${_STACKNAME}${_INSTANCESTART} does not exist." false soft
        else
                echo -e "${GREEN} [OK]${NC}"

                #####
                # Verify the port status one by one
                #####
		mac_validation ${_ADMIN_MAC}
		mac_validation ${_SZ_MAC}

                port_validation ${_ADMIN_PORTID} ${_ADMIN_MAC} ${_ACTION}
                port_validation ${_SZ_PORTID} ${_SZ_MAC} ${_ACTION}

		ip_validation ${_ADMIN_IP}
		ip_validation ${_SZ_IP}

                #####
                # Update the port securtiy group
                #####
		echo -e -n "Updating Neutron Ports for ${_UNIT} ...\t\t"
		port_securitygroupcleanup ${_ADMIN_PORTID} false
		port_securitygroup ${_ADMIN_PORTID} \
			$(cat ../${_ENV}|awk '/admin_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/admin_security_group_name/ {print $2}') \
			true # This is a true since in production this port will be VIRTIO
		port_securitygroup ${_SZ_PORTID} \
			$(cat ../${_ENV}|awk '/sz_security_group_enabled/ {print $2}'|awk '{print tolower($0)}') \
			$(cat ../${_ENV}|awk '/sz_security_group_name/ {print $2}') \
			false # This is a false since in production this port will be SR-IOV
        echo -e "${GREEN} [OK]${NC}"

                #####
                # Load the Stack and pass the following information
                # - Admin Port ID, Mac Address and IP Address
                # - SZ Port ID, Mac Address and IP Address
                # - Hostname
                # - (Anti-)Affinity Group ID from the Group Array which is a modulo math operation (%) betweem the Stack number (1..2..3 etc) and the Available anti-affinity Group. 
                #####
		echo -e -n "Identifying the right HOT to be used ...\t\t"
		_LOCAL_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
		_SOURCE_BOOT=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_image_source/ {print $2}'|awk '{print tolower($0)}')
		_SERVER_GROUP=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
		if [[ "${_LOCAL_BOOT}" == "true" && "${_SOURCE_BOOT}" == "cinder" ]]
		then
			exit_for_error "Error, Local Boot using a Volume source is not supported in OpenStack." true hard
		elif [[ ${_SERVER_GROUP} != "true" && ${_SERVER_GROUP} != "false" ]]
		then
			exit_for_error "Error, Server Group parameters ${_UNITLOWER}_server_group_enable can be only \"true\" or \"false\"." true hard
		fi	

		if [[ "${_SOURCE_BOOT}" == "cinder" ]]
		then
			_HOT="../templates/${_UNITLOWER}_cinder_source"
		elif "${_LOCAL_BOOT}" # in this case _SOURCE_BOOT=glance
		then
			_HOT="../templates/${_UNITLOWER}"
		else
			_HOT="../templates/${_UNITLOWER}_volume"
		fi

		if [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Replace" ]] && ${_SERVER_GROUP}
		then
			_SERVER_GROUP_ID=${_GROUP[ $((${RANDOM}%${_GROUPNUMBER})) ]}
		elif [[ "${_ACTION}" == "Create" ]] && ! ${_SERVER_GROUP} # in this case _SERVER_GROUP=false
		then
			_HOT=$(echo ${_HOT}_no_server_group)
		elif [[ "${_ACTION}" == "Update" ]] # In this case an update might delete the running VM so cannot be put in a new/different server group
		then
			_SERVER_GROUP_ID=$(nova server-group-list|grep $(heat resource-list ${_STACKNAME}${_INSTANCESTART}|grep "OS::Nova::Server"|awk '{print $4}')|awk '{print $2}')
			if [[ "${_SERVER_GROUP_ID}" == "" ]] && ${_SERVER_GROUP}
			then
				echo -e -n "${YELLOW} Warning, the Stack ${_STACKNAME}${_INSTANCESTART} has been created without Server Groups so it will keep not using them.${NC}"
				_HOT=$(echo ${_HOT}_no_server_group)
			fi
		fi
		
		_HOT=$(echo ${_HOT}.yaml)
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "Identifying the right Unit Name to be used ...\t\t"
                _UNIT_NAME=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_unit_name/ {print $2}')
		_ENABLE_UNIT_NAME_SUFFIX=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_enable_suffix_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_SUFFIX}
                then
                        _UNIT_NAME_SUFFIX=$(printf "%0$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_suffix_index_unit_name/ {print $2}')d" ${_INSTANCESTART})
                fi

                if [[ "$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')" != "none" ]]
                then
                        _UNIT_NAME_APPEND_STATIC_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_static_letter_index_unit_name/ {print $2}')
                else
                        _UNIT_NAME_APPEND_STATIC_CHAR=""
                fi
		_ENABLE_UNIT_NAME_APPEND_CHAR=$(cat ../${_ENV}|awk '/'${_UNITLOWER}'_append_letter_index_unit_name/ {print $2}'|awk '{print tolower($0)}')
                if ${_ENABLE_UNIT_NAME_APPEND_CHAR}
                then
                        _UNIT_NAME_APPEND_CHAR=$(alphabet_number_counter ${_INSTANCESTART})
                else
                        _UNIT_NAME_APPEND_CHAR=""
                fi
		if ! ${_ENABLE_UNIT_NAME_SUFFIX} && ! ${_ENABLE_UNIT_NAME_APPEND_CHAR}
		then
			_UNIT_NAME_INDEX=${_INSTANCESTART}
		fi
                _UNIT_NAME_FINAL=$(echo ${_UNIT_NAME}${_UNIT_NAME_SUFFIX}${_UNIT_NAME_APPEND_STATIC_CHAR}${_UNIT_NAME_APPEND_CHAR}${_UNIT_NAME_INDEX})
                echo -e "${GREEN} ${_UNIT_NAME_FINAL}${NC}"

                heat stack-$(echo "${_COMMAND}" | awk '{print tolower($0)}') \
                 --template-file ${_HOT} \
                 --environment-file ../${_ENV} \
                 --parameters "unit_name=${_UNIT_NAME_FINAL}" \
                 --parameters "admin_network_port=${_ADMIN_PORTID}" \
                 --parameters "admin_network_mac=${_ADMIN_MAC}" \
                 --parameters "admin_network_ip=${_ADMIN_IP}" \
                 --parameters "sz_network_port=${_SZ_PORTID}" \
                 --parameters "sz_network_mac=${_SZ_MAC}" \
                 --parameters "sz_network_ip=${_SZ_IP}" \
                 --parameters "antiaffinity_group=${_SERVER_GROUP_ID}" \
                 ${_STACKNAME}${_INSTANCESTART} || exit_for_error "Error, During Stack ${_ACTION}." true hard
                #--parameters "tenant_network_id=${_TENANT_NETWORK_ID}" \
        fi
        _INSTANCESTART=$(($_INSTANCESTART+1))
}


#####
# Function to valide various things
# - Given Flavor
# - Given Image Name and Image ID
#####
function validation {
	_UNITTOBEVALIDATED=$1
	_IMAGE=$(cat ../${_ENV}|grep "$(echo "${_UNITTOBEVALIDATED}" | awk '{print tolower($0)}')_image"|grep -v -E "image_id|image_source|image_volume_size"|awk '{print $2}'|sed "s/\"//g")
	_IMAGEID=$(cat ../${_ENV}|awk '/'$(echo "${_UNITTOBEVALIDATED}" | awk '{print tolower($0)}')_image_id'/ {print $2}'|sed "s/\"//g")
	_VOLUMEID=$(cat ../${_ENV}|awk '/'$(echo "${_UNITTOBEVALIDATED}" | awk '{print tolower($0)}')_volume_id'/ {print $2}'|sed "s/\"//g")
	_FLAVOR=$(cat ../${_ENV}|awk '/'$(echo "${_UNITTOBEVALIDATED}" | awk '{print tolower($0)}')_flavor_name'/ {print $2}'|sed "s/\"//g")
	_SOURCE=$(cat ../${_ENV}|grep "$(echo "${_UNITTOBEVALIDATED}" | awk '{print tolower($0)}')_image_source"|awk '{print $2}'|sed "s/\"//g")

	#####
	# _SOURCE=glance -> Check the Image Id and the Image Name is the same 
	# _SOURCE=cinder -> Check the Volume Id, the Given size and if the Volume snapshot/clone feature is present 
	#####
	if [[ "${_SOURCE}" == "glance" ]]
	then
		if $(cat ../${_ENV}|awk '/'${_UNITTOBEVALIDATED}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
		then
			echo -e "${GREEN}The Unit ${_UNITTOBEVALIDATED} will boot from the local hypervisor disk (aka Ephemeral Disk)${NC}"
		else
			echo -e "${GREEN}The Unit ${_UNITTOBEVALIDATED} will boot from Volume (aka from the SAN)${NC}"
		fi
		echo -e -n "Validating chosen Glance Image ${_IMAGE} ...\t\t"
		glance image-show ${_IMAGEID}|grep "${_IMAGE}" >/dev/null 2>&1 || exit_for_error "Error, Image for Unit ${_UNITTOBEVALIDATED} not present or mismatch between ID and Name." true hard
		echo -e "${GREEN} [OK]${NC}"
	elif [[ "${_SOURCE}" == "cinder" ]]
	then
		echo -e "${GREEN}The Unit ${_UNITTOBEVALIDATED} will boot from Volume (aka from the SAN)${NC}"
		echo -e -n "Validating chosen Cinder Volume ${_VOLUMEID} ...\t\t"
		cinder show ${_VOLUMEID} >/dev/null 2>&1 || exit_for_error "Error, Volume for Unit ${_UNITTOBEVALIDATED} not present." true hard
		echo -e "${GREEN} [OK]${NC}"

		echo -e -n "Validating given volume size ...\t\t"
		_VOLUME_SIZE=$(cinder show ${_VOLUMEID}|awk '/size/ {print $4}'|sed "s/ //g")
		_VOLUME_GIVEN_SIZE=$(cat ../${_ENV}|awk '/'$(echo "${_UNITTOBEVALIDATED}" | awk '{print tolower($0)}')_volume_size'/ {print $2}'|sed "s/\"//g")
		if (( "${_VOLUME_GIVEN_SIZE}" < "${_VOLUME_SIZE}" ))
		then
			exit_for_error "Error, Volume for Unit ${_UNITTOBEVALIDATED} with UUID ${_VOLUMEID} has a size of ${_VOLUME_SIZE} which cannot fit into the given input size of ${_VOLUME_GIVEN_SIZE}." true hard
		fi
		echo -e "${GREEN} [OK]${NC}"

		#####
		# Creating a test volume to verify that the snapshotting works
		# https://wiki.openstack.org/wiki/CinderSupportMatrix
		# e.g. Feature not available with standard NFS driver
		#####
		echo -e -n "Validating if volume cloning/snapshotting feature is available ...\t\t"
		#####
		# Creating a new volume from the given one
		#####
		cinder create --source-volid ${_VOLUMEID} --display-name "temp-${_VOLUMEID}" ${_VOLUME_SIZE} >/dev/null 2>&1 || exit_for_error "Error, During volume cloning/snapshotting. With the current Cinder's backend Glance has to be used." true hard
		
		#####
		# Wait until the volume created is in error or available states
		#####
		while :
		do
			_VOLUME_SOURCE_STATUS=$(cinder show temp-${_VOLUMEID}|grep " status "|awk '{print $4}')
			if [[ "${_VOLUME_SOURCE_STATUS}" == "available" ]]
			then
				cinder delete temp-${_VOLUMEID} >/dev/null 2>&1
				echo -e "${GREEN} [OK]${NC}"
				break
			elif [[ "${_VOLUME_SOURCE_STATUS}" == "error" ]]
			then
				cinder delete temp-${_VOLUMEID} >/dev/null 2>&1
				exit_for_error "Error, the system does not support volume cloning/snapshotting. With the current Cinder's backend Glance has to be used." true hard
			fi
		done
	else
		exit_for_error "Error, Invalid Image Source option, can be \"glance\" or \"cinder\"." true hard
	fi

	#####
	# Check the given flavor is available
	#####
	echo -e -n "Validating chosen Flavor ${_FLAVOR} ...\t\t"
	nova flavor-show "${_FLAVOR}" >/dev/null 2>&1 || exit_for_error "Error, Flavor for Unit ${_UNITTOBEVALIDATED} not present." true hard
	echo -e "${GREEN} [OK]${NC}"
}

#####
# Function to valide the Network
# - Does it exist?
# - Does the given VLAN ID is valid?
#####
function net_validation {
        _UNITTOBEVALIDATED=$1
	_NET=$2
        _NETWORK=$(cat ../${_ENV}|awk '/'${_NET}'_network_name/ {print $2}'|sed "s/\"//g")
        _VLAN=$(cat ../${_ENV}|awk '/'${_NET}'_network_vlan/ {print $2}'|sed "s/\"//g")

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
	_UNITACTION=$3

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
	if [[ "$(neutron port-show --field device_owner --format value ${_PORT})" == "compute:nova" && "${_UNITACTION}" != "Update" ]]
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
        echo -e -n "Validating IP Address ${_IP} ...\t\t"
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
        echo -e -n "Validating MAC Address ${_MAC} ...\t\t"
        echo ${_MAC}|grep -E "([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})" >/dev/null 2>&1
        if [[ "${?}" != "0" ]]
        then
                exit_for_error "Error, The Port Mac Address ${_MAC} is not valid." true hard
        fi
        echo -e "${GREEN} [OK]${NC}"

}
function port_securitygroup {
        _PORT=$1
	_SECGROUPENABLE=$2
	_SECGROUPNAME=$3
	_EXITHARD=$4
	if ${_SECGROUPENABLE}
	then
		if ${_EXITHARD}
		then
			neutron port-update --security-group ${_SECGROUPNAME} ${_PORT} > /dev/null 2>&1 || exit_for_error "Error, During Neutron Port ${_ADMIN_PORTID} Security Group Update." true hard
		else
			neutron port-update --security-group ${_SECGROUPNAME} ${_PORT} > /dev/null 2>&1 || exit_for_error "Error, During Neutron Port ${_ADMIN_PORTID} Security Group Update." false soft
		fi
	fi
}
function port_securitygroupcleanup {
        _PORT=$1
	_EXITHARD=$2
	if ${_EXITHARD}
	then
		neutron port-update --no-security-groups ${_PORT} >/dev/null 2>&1 || exit_for_error "Error, During Neutron Port ${_ADMIN_PORTID} Security Group Clean Up." true hard
	else
		neutron port-update --no-security-groups ${_PORT} >/dev/null 2>&1 || exit_for_error "Error, During Neutron Port ${_ADMIN_PORTID} Security Group Clean Up." false soft
	fi
}

#####
# Algoritm to convert decimal numbers to alphabet numbers.
# Quite a nightmare developing it
# Here the results https://www.minus40.info/sky/alphabetcountdec.html
# e.g.
# 0 = z
# 1 = a
# 2 = b
# 26 = z
# 27 = aa
# 1989 = bxm
# 2050 = bzv
#####
function alphabet_number_counter {
	ALPHBET[0]=Z
	ALPHBET[1]=A
	ALPHBET[2]=B
	ALPHBET[3]=C
	ALPHBET[4]=D
	ALPHBET[5]=E
	ALPHBET[6]=F
	ALPHBET[7]=G
	ALPHBET[8]=H
	ALPHBET[9]=I
	ALPHBET[10]=J
	ALPHBET[11]=K
	ALPHBET[12]=L
	ALPHBET[13]=M
	ALPHBET[14]=N
	ALPHBET[15]=O
	ALPHBET[16]=P
	ALPHBET[17]=Q
	ALPHBET[18]=R
	ALPHBET[19]=S
	ALPHBET[20]=T
	ALPHBET[21]=U
	ALPHBET[22]=V
	ALPHBET[23]=W
	ALPHBET[24]=X
	ALPHBET[25]=Y
	ALPHBET[26]=Z
	
	_NUMBER=$1

	_MOD=$((${_NUMBER} % 26))
	if (( ${_MOD} == 0 ))
	then	
		_INIT_DIV=$(( (${_NUMBER}-1)/26))
	else
		_INIT_DIV=$((${_NUMBER}/26))
	fi
	_RESULTSUFFIX=${ALPHBET[ ${_MOD} ]}
	if (( ${_INIT_DIV} <= 26 && ${_NUMBER} > 26 ))
	then
		_MOD=$((${_INIT_DIV} % 26))
		_RESULT=${ALPHBET[ ${_MOD} ]}
	else
		while (( ${_INIT_DIV} > 26 ))
		do
			_DIV=$((${_INIT_DIV} / 26))
			_MOD=$((${_INIT_DIV} % 26))
			if (( ${_MOD} == 0 ))
			then
				_DIV=$((${_DIV}-1))
			fi
			_RESULT=${ALPHBET[ ${_DIV} ]}
			_RESULT=$(echo ${_RESULT}${ALPHBET[ ${_MOD} ]} )
			_INIT_DIV=${_DIV}
		done
	fi
	
	echo ${_RESULT}${_RESULTSUFFIX}

}
#####
# Write the input args into variable
#####
_RCFILE=$1
_ACTION=$2
_UNIT=$3
_UNITLOWER=$(echo "${_UNIT}" | awk '{print tolower($0)}')
_INSTANCESTART=${4-1}
[[ "${5}" != "" ]] && _INSTANCEEND=${5} || _INSTANCEEND=false
_CSVFILEPATH=${6-environment/${_UNITLOWER}}
_STACKNAME=${7-${_UNITLOWER}}
_ENV="environment/common.yaml"
_CHECKS="environment/common_checks"

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
	echo "\"Replace\" - To replace the stack - This deletes it and then will recreate it from scratch"
        echo -e ${NC}
	exit 1
fi

#####
# Check Unit Name
#####
if [[ "${_UNIT}" != "CMS" && "${_UNIT}" != "LVU" && "${_UNIT}" != "OMU" && "${_UNIT}" != "VM-ASU" && "${_UNIT}" != "MAU" && "${_UNIT}" != "DSU" && "${_UNIT}" != "SMU" ]]
then
	input_error_log
	echo "Unit type non valid."
	echo "It must be in the following format:"
	echo "\"CMS\""
	echo "\"LVU\""
	echo "\"OMU\""
	echo "\"VM-ASU\""
	echo "\"MAU\""
	echo "\"DSU\""
	echo "\"SMU\""
        echo -e ${NC}
	exit 1
fi

#####
# Check instance to start
# Check instance to end
#####
echo ${_INSTANCESTART}|grep -E "[0-9]{1,99}" > /dev/null 2>&1
if [[ "${?}" != "0" ]]
then
	input_error_log
	echo "Error, Not valid Instance to Start with."
        echo -e ${NC}
	exit 1
fi

echo ${_INSTANCEEND}|grep -E "[0-9]{1,99}" > /dev/null 2>&1
if [[ "${?}" != "0" && ${_INSTANCEEND} != "false" ]]
then
	input_error_log
	echo "Error, Not valid Instance to End with."
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
# - Does it have the given starting line?
# - Does it have the given ending line?
#####
echo -e -n "Verifying if Admin CSV file is good ...\t\t"
if [ ! -f ${_ADMINCSVFILE} ] || [ ! -r ${_ADMINCSVFILE} ] || [ ! -s ${_ADMINCSVFILE} ]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Admin Network with mapping PortID,MacAddress,FixedIP does not exist."
	echo -e "${NC}"
	exit 1
fi
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifying if Admin CSV file has the given starting line ${_INSTANCESTART} ...\t\t"
if [[ "$(sed -n -e "${_INSTANCESTART}p" ${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
then
	echo -e "${RED}"
	echo "Wrapper for ${_UNIT} Unit Creation"
	echo "CSV File for Admin Network does not have the given starting line"
	echo -e "${NC}"
	exit 1
fi
echo -e "${GREEN} [OK]${NC}"

if [[ "${_INSTANCEEND}" != "false" ]]
then
	echo -e -n "Verifying if Admin CSV file has the given ending line ${_INSTANCEEND} ...\t\t"
	if [[ "$(sed -n -e "${_INSTANCEEND}p" ${_ADMINCSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	then
		echo -e "${RED}"
		echo "Wrapper for ${_UNIT} Unit Creation"
		echo "CSV File for Admin Network does not have the given ending line"
		echo -e "${NC}"
		exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
fi

#####
# Check if the Secure Zone CSV File except for the MAU Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
# - Does it have the given starting line?
# - Does it have the given ending line?
#####
if [[ ! "${_UNIT}" == "MAU" ]]
then
	echo -e -n "Verifying if Secure Zone CSV file is good ...\t\t"
	if [ ! -f ${_SZCSVFILE} ] || [ ! -r ${_SZCSVFILE} ] || [ ! -s ${_SZCSVFILE} ]
	then
		echo -e "${RED}"
		echo "Wrapper for ${_UNIT} Unit Creation"
		echo "CSV File for Secure Zone Network with mapping Portid,MacAddress,FixedIP does not exist."
		echo -e "${NC}"
		exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	echo -e -n "Verifying if Secure Zone CSV file has the given starting line ${_INSTANCESTART} ...\t\t"
	if [[ "$(sed -n -e "${_INSTANCESTART}p" ${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	then
	        echo -e "${RED}"
	        echo "Wrapper for ${_UNIT} Unit Creation"
	        echo "CSV File for Secure Zone does not have the given starting line"
	        echo -e "${NC}"
	        exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	if [[ "${_INSTANCEEND}" != "false" ]]
	then
	        echo -e -n "Verifying if Secure Zone CSV file has the given ending line ${_INSTANCEEND} ...\t\t"
	        if [[ "$(sed -n -e "${_INSTANCEEND}p" ${_SZCSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	        then
	                echo -e "${RED}"
	                echo "Wrapper for ${_UNIT} Unit Creation"
	                echo "CSV File for Secure Zone Network does not have the given ending line"
	                echo -e "${NC}"
	                exit 1
	        fi
	        echo -e "${GREEN} [OK]${NC}"
	fi
fi

#####
# Check if the SIP CSV File for the CMS Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
# - Does it have the given starting line?
# - Does it have the given ending line?
#####
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e -n "Verifying if SIP CSV file is good ...\t\t"
	if [ ! -f ${_SIPCSVFILE} ] || [ ! -r ${_SIPCSVFILE} ] || [ ! -s ${_SIPCSVFILE} ]
	then
		echo -e "${RED}"
		echo "Wrapper for ${_UNIT} Unit Creation"
		echo "CSV File for SIP Internal Network with mapping Portid,MacAddress,FixedIP does not exist."
		echo -e "${NC}"
		exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	echo -e -n "Verifying if SIP CSV file has the given starting line ${_INSTANCESTART} ...\t\t"
	if [[ "$(sed -n -e "${_INSTANCESTART}p" ${_SIPCSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	then
	        echo -e "${RED}"
	        echo "Wrapper for ${_UNIT} Unit Creation"
	        echo "CSV File for SIP Network does not have the given starting line"
	        echo -e "${NC}"
	        exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	if [[ "${_INSTANCEEND}" != "false" ]]
	then
	        echo -e -n "Verifying if SIP CSV file has the given ending line ${_INSTANCEEND} ...\t\t"
	        if [[ "$(sed -n -e "${_INSTANCEEND}p" ${_SIPCSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	        then
	                echo -e "${RED}"
	                echo "Wrapper for ${_UNIT} Unit Creation"
	                echo "CSV File for SIP Network does not have the given ending line"
	                echo -e "${NC}"
	                exit 1
	        fi
	        echo -e "${GREEN} [OK]${NC}"
	fi
fi

#####
# Check if the Media CSV File for the CMS Unit
# - Does it exist?
# - Is it readable?
# - Does it have a size higher than 0Byte?
# - Does it have the given starting line?
# - Does it have the given ending line?
#####
if [[ "${_UNIT}" == "CMS" ]]
then
	echo -e -n "Verifying if Media CSV file is good ...\t\t"
	if [ ! -f ${_MEDIACSVFILE} ] || [ ! -r ${_MEDIACSVFILE} ] || [ ! -s ${_MEDIACSVFILE} ]
	then
		echo -e "${RED}"
		echo "Wrapper for ${_UNIT} Unit Creation"
		echo "CSV File for Media Network with mapping Portid,MacAddress,FixedIP does not exist."
		echo -e "${NC}"
		exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	echo -e -n "Verifying if Media CSV file has the given starting line ${_INSTANCESTART} ...\t\t"
	if [[ "$(sed -n -e "${_INSTANCESTART}p" ${_MEDIACSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	then
	        echo -e "${RED}"
	        echo "Wrapper for ${_UNIT} Unit Creation"
	        echo "CSV File for Media Network does not have the given starting line"
	        echo -e "${NC}"
	        exit 1
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	if [[ "${_INSTANCEEND}" != "false" ]]
	then
	        echo -e -n "Verifying if Media CSV file has the given ending line ${_INSTANCEEND} ...\t\t"
	        if [[ "$(sed -n -e "${_INSTANCEEND}p" ${_MEDIACSVFILE} | sed -e "s/\^M//g" | grep -v "^$")" == "" ]]
	        then
	                echo -e "${RED}"
	                echo "Wrapper for ${_UNIT} Unit Creation"
	                echo "CSV File for Media Network does not have the given ending line"
	                echo -e "${NC}"
	                exit 1
	        fi
	        echo -e "${GREEN} [OK]${NC}"
	fi
fi

#####
# Verify binary
#####
_BINS="heat nova neutron glance cinder"
for _BIN in ${_BINS}
do
	echo -e -n "Verifying ${_BIN} binary ...\t\t"
	which ${_BIN} > /dev/null 2>&1 || exit_for_error "Error, Cannot find python${_BIN}-client." false
	echo -e "${GREEN} [OK]${NC}"
done

echo -e -n "Verifying Heat Assume Yes ...\t\t"
_ASSUMEYES=""
heat help stack-delete|grep "\-\-yes" >/dev/null 2>&1
if [[ "${?}" == "0" ]]
then
        _ASSUMEYES="--yes"
        echo -e "${GREEN} [OK]${NC}"
else
        echo -e "${YELLOW} [NOT AVAILABLE]${NC}"
fi

_ENABLEGIT=false
if ${_ENABLEGIT}
then
        echo -e -n "Verifying git binary ...\t\t"
        which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find git and any changes will be commited." false soft
        echo -e "${GREEN} [OK]${NC}"
fi

echo -e -n "Verifying dos2unix binary ...\t\t"
which dos2unix > /dev/null 2>&1 || exit_for_error "Error, Cannot find dos2unix binary, please install it first\nThe installation will continue BUT the Wrapper cannot ensure the File Unix format consistency." false soft
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifying md5sum binary ...\t\t"
which md5sum > /dev/null 2>&1 || exit_for_error "Error, Cannot find md5sum binary." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Convert every files exept the GITs one
#####
echo -e -n "Eventually converting files in Standard Unix format ...\t\t"
for _FILE in $(find . -not \( -path ./.git -prune \) -type f)
do
        _MD5BEFORE=$(md5sum ${_FILE}|awk '{print $1}')
        dos2unix ${_FILE} >/dev/null 2>&1
        _MD5AFTER=$(md5sum ${_FILE}|awk '{print $1}')
        #####
        # Verify the MD5 after and before the dos2unix - eventually commit the changes
        #####
        if [[ "${_MD5BEFORE}" != "${_MD5AFTER}" ]] && ${_ENABLEGIT}
        then
                git add ${_FILE} >/dev/null 2>&1
                git commit -m "Auto Commit Dos2Unix for file ${_FILE} conversion" >/dev/null 2>&1
        fi
done
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if there is the environment file
#####
echo -e -n "Verifying if there is the environment file ...\t\t"
if [ ! -f ${_ENV} ] || [ ! -r ${_ENV} ] || [ ! -s ${_ENV} ]
then
        exit_for_error "Error, Environment file missing." false hard
fi
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if there is any duplicated entry in the environment file
#####
echo -e -n "Verifying duplicate entries in the environment file ...\t\t"
_DUPENTRY=$(cat ${_ENV}|grep -v -E '^[[:space:]]*$|^$'|awk '{print $1}'|grep -v "#"|sort|uniq -c|grep " 2 "|wc -l)
if (( "${_DUPENTRY}" > "0" ))
then
        echo -e "${RED}Found Duplicate Entries${NC}"
        _OLDIFS=$IFS
        IFS=$'\n'
        for _VALUE in $(cat ${_ENV}|grep -v -E '^[[:space:]]*$|^$'|awk '{print $1}'|grep -v "#"|sort|uniq -c|grep " 2 "|awk '{print $2}'|sed 's/://g')
        do
                echo -e "${YELLOW}This parameters is present more than once:${NC} ${RED}${_VALUE}${NC}"
        done
        IFS=${_OLDIFS}
        exit_for_error "Error, Please fix the above duplicate entries and then you can continue." false hard
fi
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if there is a test for each entry in the environment file
#####
echo -e -n "Verifying if there is a test for each entry in the environment file ...\t\t"
_EXIT=false
_OLDIFS=$IFS
IFS=$'\n'
for _ENVVALUE in $(cat ${_ENV}|grep -v -E '^[[:space:]]*$|^$'|grep -v -E "parameter_defaults|[-]{3}"|awk '{print $1}'|grep -v "#")
do
        grep ${_ENVVALUE} ${_CHECKS} >/dev/null 2>&1
        if [[ "${?}" != "0" ]]
        then
                _EXIT=true
                echo -e -n "\n${YELLOW}Error, missing test for parameter ${NC}${RED}${_ENVVALUE}${NC}${YELLOW} in environment check file ${_CHECKS}${NC}"
        fi
done
if ${_EXIT}
then
        echo -e -n "\n"
        exit 1
fi
IFS=${_OLDIFS}
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the environment file has the right input values
#####
echo -e -n "Verifying if the environment file has all of the right input values ...\t\t"
_EXIT=false
if [ ! -f ${_CHECKS} ] || [ ! -r ${_CHECKS} ] || [ ! -s ${_CHECKS} ]
then
	exit_for_error "Error, Missing Environment check file." false hard
else
	_OLDIFS=$IFS
	IFS=$'\n'
	for _INPUTTOBECHECKED in $(cat ${_CHECKS})
	do
		_PARAM=$(echo ${_INPUTTOBECHECKED}|awk '{print $1}')
		_EXPECTEDVALUE=$(echo ${_INPUTTOBECHECKED}|awk '{print $2}')
		_PARAMFOUND=$(grep ${_PARAM} ${_ENV}|awk '{print $1}')
		_VALUEFOUND=$(grep ${_PARAM} ${_ENV}|awk '{print $2}'|sed "s/\"//g")
		#####
		# Verify that I have all of my parameters
		#####
		if [[ "${_PARAMFOUND}" == "" ]]
		then
			_EXIT=true
			echo -e -n "\n${YELLOW}Error, missing parameter ${NC}${RED}${_PARAM}${NC}${YELLOW} in environment file.${NC}"
		fi
		#####
		# Verify that I have for each parameter a value
		#####
		if [[ "${_VALUEFOUND}" == "" && "${_PARAMFOUND}" != "" ]]
		then
			_EXIT=true
			echo -e -n "\n${YELLOW}Error, missing value for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file.${NC}"
		fi
		#####
		# Verify that I have the right/expected value
		#####
		if [[ "${_EXPECTEDVALUE}" == "string" ]]
		then
			echo "${_VALUEFOUND}"|grep -E "[a-zA-Z_-\.]" >/dev/null 2>&1
			if [[ "${?}" != "0" ]]
			then
				_EXIT=true
				echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
				echo -e -n "\n${RED}It has to be a String with the following characters a-zA-Z_-.${NC}"
			fi
		elif [[ "${_EXPECTEDVALUE}" == "boolean" ]]
	        then
	                echo "${_VALUEFOUND}"|grep -E "^(true|false|True|False|TRUE|FALSE)$" >/dev/null 2>&1
	                if [[ "${?}" != "0" ]]
	                then
	                        _EXIT=true
	                        echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
	                        echo -e -n "\n${RED}It has to be a Boolean, e.g. True${NC}"
	                fi
	        elif [[ "${_EXPECTEDVALUE}" == "number" ]]
	        then
	                echo "${_VALUEFOUND}"|grep -E "[0-9]" >/dev/null 2>&1
	                if [[ "${?}" != "0" ]]
	                then
	                        _EXIT=true
	                        echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
	                        echo -e -n "\n${RED}It has to be a Number, e.g. 123${NC}"
	                fi
                elif [[ "${_EXPECTEDVALUE}" == "string|number" ]]
                then
                        echo "${_VALUEFOUND}"|grep -E "[a-zA-Z_-\.0-9]" >/dev/null 2>&1
                        if [[ "${?}" != "0" ]]
                        then
                                _EXIT=true
                                echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
                                echo -e -n "\n${RED}It has to be either a Number or a String, e.g. 1${NC}"
                        fi
	        elif [[ "${_EXPECTEDVALUE}" == "ip" ]]
	        then
	                echo "${_VALUEFOUND}"|grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" >/dev/null 2>&1
	                if [[ "${?}" != "0" ]]
	                then
	                        _EXIT=true
	                        echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
	                        echo -e -n "\n${RED}It has to be an IP Address, e.g. 192.168.1.1 or a NetMask e.g. 255.255.255.0 or a Network Cidr, e.g. 192.168.1.0/24${NC}"
	                fi
	        elif [[ "${_EXPECTEDVALUE}" == "vlan" ]]
	        then
	                echo "${_VALUEFOUND}"|grep -E "^(none|[0-9]{1,4})$" >/dev/null 2>&1
	                if [[ "${?}" != "0" ]]
	                then
	                        _EXIT=true
	                        echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
	                        echo -e -n "\n${RED}It has to be a VLAN ID, between 1 to 4096 or none in case of diabled VLAN configuration${NC}"
	                fi
	        elif [[ "${_EXPECTEDVALUE}" == "anti-affinity|affinity" ]]
	        then
	                echo "${_VALUEFOUND}"|grep -E "^(anti-affinity|affinity)$" >/dev/null 2>&1
	                if [[ "${?}" != "0" ]]
	                then
	                        _EXIT=true
	                        echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
	                        echo -e -n "\n${RED}It has to be \"anti-affinity\" or \"affinity\"${NC}"
	                fi
		elif [[ "${_EXPECTEDVALUE}" == "glance|cinder" ]]
	        then
	                echo "${_VALUEFOUND}"|grep -E "^(glance|cinder)$" >/dev/null 2>&1
	                if [[ "${?}" != "0" ]]
	                then
	                        _EXIT=true
	                        echo -e -n "\n${YELLOW}Error, value ${NC}${RED}${_VALUEFOUND}${NC}${YELLOW} for parameter ${NC}${RED}${_PARAMFOUND}${NC}${YELLOW} in environment file is not correct.${NC}"
	                        echo -e -n "\n${RED}It has to be \"glance\" or \"cinder\"${NC}"
	                fi
		else
			_EXIT=true
			echo -e -n "\n${YELLOW}Error, Expected value to check ${NC}${RED}${_EXPECTEDVALUE}${NC}${YELLOW} is not correct.${NC}"
		fi
	done
fi
if ${_EXIT}
then
	echo -e -n "\n"
	exit 1
fi
IFS=${_OLDIFS}
echo -e "${GREEN} [OK]${NC}"

#####
# Unload any previous loaded environment file
#####
for _BASHENV in $(env|grep ^OS|awk -F "=" '{print $1}')
do
        unset ${_BASHENV}
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
echo -e -n "Verifying OpenStack credential ...\t\t"
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the PreparetionStack is available.
#####
echo -e -n "Verifying Preparetion Stack ...\t\t"
heat resource-list PreparetionStack > /dev/null 2>&1 || exit_for_error "Error, Cannot find the Preparetion Stack, so create it first." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the Generic Security Group is available
#####
echo -e -n "Verifying Generic Security Group ...\t\t"
neutron security-group-show $(cat ${_ENV}|awk '/generic_security_group_name/ {print $2}') >/dev/null 2>&1 \
	&& ( echo -e "${GREEN} [OK]${NC}" ) \
	|| ( exit_for_error "Error, Cannot find the Generic Security Group." false soft )

#####
# Verify if the Admin Security Group is available
#####
echo -e -n "Verifying Admin Security Group ...\t\t"
neutron security-group-show $(cat ${_ENV}|awk '/admin_security_group_name/ {print $2}') >/dev/null 2>&1 || exit_for_error "Error, Cannot find the Admin Security Group." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if the Server Groups are available and
# - Load them into an array
#####
echo -e -n "Eventually Verifying (Anti-)Affinity rules ...\t\t"
_GROUPS=./groups.tmp
nova server-group-list|grep ServerGroup|sort -k4|awk '{print $4,$2}' > ${_GROUPS}
_GROUPNUMBER=$(cat ${_GROUPS}|grep ${_UNIT}|wc -l)
if [[ "${_GROUPNUMBER}" == "0" && "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]] && $(cat ${_ENV}|awk '/'${_UNITLOWER}'_server_group_enable/ {print $2}'|awk '{print tolower($0)}')
then
	exit_for_error "Error, There is any available (Anti-)Affinity Group." false hard
fi
_INDEXGROUP=0
_OLDIFS=$IFS
while IFS=$'\n' read -r _LINE || [[ -n "$line" ]]
do
	_UNITGROUP=$(echo ${_LINE}|awk '{print $1}')
	_UNITGROUPID=$(echo ${_LINE}|awk '{print $2}')
	if [[ ${_UNITGROUP} =~ "${_UNIT}" ]]
	then
		_GROUP[${_INDEXGROUP}]=${_UNITGROUPID}
		_INDEXGROUP=$((${_INDEXGROUP}+1))
	fi
done < ${_GROUPS}
rm -rf ${_GROUPS}
IFS=${_OLDIFS}
echo -e "${GREEN} [OK]${NC}"

#####
# Change directory into the deploy one
#####
_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

#_TENANT_NETWORK_NAME=$(cat ../${_ENV}|awk '/tenant_network_name/ {print $2}')
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
elif [[ "${_ACTION}" == "Create" || "${_ACTION}" == "Update" || "${_ACTION}" == "Replace" || "${_ACTION}" == "Delete" ]]
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
		# Init the CMS Creation
		#####
		create_update_cms
		echo -e "${GREEN}DONE${NC}"
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
		echo -e "${GREEN}DONE${NC}"
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
		# Init the OMU Creation
		#####
		create_update_omu
		echo -e "${GREEN}DONE${NC}"
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
		echo -e "${GREEN}DONE${NC}"
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
		echo -e "${GREEN}DONE${NC}"
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "DSU" ]]
	then
		#####
		# Validate the network for DSU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Init the DSU Creation
		#####
		create_update_dsu
		echo -e "${GREEN}DONE${NC}"
		cd ${_CURRENTDIR}
		exit 0
	elif [[ ${_UNIT} == "SMU" ]]
	then
		#####
		# Validate the network for SMU
		#####
		net_validation ${_UNIT} admin
		net_validation ${_UNIT} sz

		#####
		# Init the SMU Creation
		#####
		create_update_smu
		echo -e "${GREEN}DONE${NC}"
		cd ${_CURRENTDIR}
		exit 0
	fi
fi
echo -e "${GREEN}DONE${NC}"
 
exit 0

