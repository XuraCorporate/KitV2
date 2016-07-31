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
#	echo -e -n "Verifing access to the Nova API ...\t\t"
#	nova list > /dev/null 2>&1 || exit_for_error "Error, Cannot access to the Nova API." false
#	echo -e "${GREEN} [OK]${NC}"
#	
#	echo -e -n "Verifing access to the Neutron API ...\t\t"
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
	echo -e -n "Verifing if ${_STACKNAME} is already loaded ...\t\t"
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

	echo -e -n "Verifing if Server Group Quota ...\t\t"
	_GROUPS=$(cat ../environment/common.yaml|grep server_group_quantity|awk '{s+=$2} END {print s}')
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
	 --environment-file ../environment/common.yaml \
	${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
elif [[ "${_ACTION}" != "List" && "${_ACTION}" != "Check" ]]
then
	#####
	# Delete the Stack
	#####
	heat stack-list|grep -E "(cms|lvu|omu|vm-asu|mau)" >/dev/null 2>&1 && exit_for_error "Error, During Stack ${_ACTION}. Cannot delete it if any Unit Stacks are presents."
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
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

