#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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
# Function to check the OpenStack environment
#####
function check {
#	echo -e -n "Verifying access to the Nova API ...\t\t"
#	nova list > /dev/null 2>&1 || exit_for_error "Error, Cannot access to the Nova API." false
#	echo -e "${GREEN} [OK]${NC}"
#	
#	echo -e -n "Verifying access to the Neutron API ...\t\t"
#	neutron net-list > /dev/null 2>&1 || exit_for_error "Error, Cannot access to the Nova API." false
#	echo -e "${GREEN} [OK]${NC}"
	echo "Not yet implemented."
}

#####
# Verity if any input values are present
#####
if [[ "$1" == "" ]]
then
	echo -e "${RED}Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete>${NC}"
	exit 1
fi

#####
# Write the input args into variable
#####
_RCFILE=$1
_ACTION=$2
_STACKNAME=PreparetionStack
#_STACKNAME=${3-PreparetionStack}
_ENV="environment/common.yaml"
_CHECKS="environment/common_checks"

#####
# Check RC File
#####
if [ ! -e ${_RCFILE} ]
then
	echo -e "${RED}"
	echo "OpenStack RC environment file does not exist."
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete>"
	echo -e "${NC}"
	exit 1
fi

#####
# Check Action Name
#####
if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" && "${_ACTION}" != "Check" ]]
then
	echo -e "${RED}"
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "\"Check\" - Check the OpenStack environment in order to find out any possible issue"
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete>"
	echo -e "${NC}"
	exit 1
fi

#####
# Verify binary
#####
_BINS="heat nova neutron glance"
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

echo -e -n "Verifying git binary ...\t\t"
which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find git and any changes will be commited." false soft
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifying dos2unix binary ...\t\t"
which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find dos2unix binary, please install it\nThe installation will continue BUT the Wrapper cannot ensure the File Unix format consistency." false soft
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifying md5sum binary ...\t\t"
which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find md5sum binary." false hard
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
	if [[ "${_MD5BEFORE}" != "${_MD5AFTER}" ]]
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
_DUPENTRY=$(cat ${_ENV}|grep -v -E '^[[:space:]]*$|#|^$'|awk '{print $1}'|sort|uniq -c|grep " 2 "|wc -l)
if (( "${_DUPENTRY}" > "0" ))
then
        echo -e "${RED}Found Duplicate Entries${NC}"
        _OLDIFS=$IFS
        IFS=$'\n'
        for _VALUE in $(cat ${_ENV}|grep -v -E '^[[:space:]]*$|#|^$'|awk '{print $1}'|sort|uniq -c|grep " 2 "|awk '{print $2}'|sed 's/://g')
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
for _ENVVALUE in $(cat ${_ENV}|grep -v -E '^[[:space:]]*$|#|^$'|grep -v -E "parameter_defaults|[-]{3}"|awk '{print $1}')
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
# Change directory into the deploy one
#####
_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

#####
# Initiate the actions phase
#####
echo -e "${GREEN}Performing Action ${_ACTION}${NC}"
if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" && "${_ACTION}" != "Check" ]]
then
	#####
	# Here the action can be only Update or Create
	#####

	#####
	# Verify if the stack already exist. A double create will fail
	# Verify if the stack exist in order to be updated
	#####
	echo -e -n "Verifying if ${_STACKNAME} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME} > /dev/null 2>&1
	_STATUS=${?}
	if [[ "${_ACTION}" == "Create" && "${_STATUS}" == "0" ]]
	then
		exit_for_error "Error, The Stack already exist." true
	elif [[ "${_ACTION}" == "Update" && "${_STATUS}" != "0" ]]
	then
		exit_for_error "Error, The Stack does not exist." true
	fi
	echo -e "${GREEN} [OK]${NC}"

	echo -e -n "Verifying if Server Group Quota ...\t\t"
	_GROUPS=$(cat ../${_ENV}|grep server_group_quantity|awk '{s+=$2} END {print s}')
	_GROUPSQUOTA=$(nova quota-show|grep server_groups|awk '{print $4}')	
	if (( "${_GROUPS}" > "${_GROUPSQUOTA}" ))
	then
		exit_for_error "Error, In the environemnt file has been defined to create ${_GROUPS} Server Groups but the user quota can only allow to have up to ${_GROUPSQUOTA} Server Groups. Recude the number or call the Administrator to increase the Quota." true
	fi
	echo -e "${GREEN} [OK]${NC}"

	#####
	# Create or Update the Stack
	# All of the path have a ".." in front since we are in the deploy directory in this phase
	#####
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') \
	 --template-file ../templates/preparation.yaml \
	 --environment-file ../${_ENV} \
	${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
elif [[ "${_ACTION}" != "List" && "${_ACTION}" != "Check" ]]
then
	#####
	# Delete the Stack
	# To disassociate all of the Neutron ports for any security groups
	# $ source <openstack rc file>
	# $ neutron port-list --column id --format value|xargs -n1 neutron port-update --no-security-group
	#####
	heat stack-list|grep -E "(cms|lvu|omu|vm-asu|mau)" >/dev/null 2>&1 && exit_for_error "Error, During Stack ${_ACTION}. Cannot delete it if any Unit Stacks are presents.\nThis is due to:\n - the associated Neutron Security Groups to the Neutron Ports.\n - the associated Nova Server Group to the Nova VMs."
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_ASSUMEYES} ${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
elif [[ "${_ACTION}" != "Check" ]]
then
	#####
	# List all of the Stack's resources
	#####
	heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
else
	#####
	# Check the OpenStack environment
	#####
	check	
fi

cd ${_CURRENTDIR}

exit 0

