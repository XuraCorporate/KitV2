
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\e[1m'
NORMAL='\e[0m'

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
# Verity if any input values are present
#####
if [[ "$1" == "" ]]
then
	echo -e "${RED}Usage bash $0 <OpenStack RC environment file>${NC}"
	exit 1
fi

#####
# Write the input args into variable
#####
_RCFILE=$1
_ENV="environment/common.yaml"
_CHECKS="environment/common_checks"

#####
# Check RC File
#####
if [ ! -e ${_RCFILE} ]
then
	echo -e "${RED}"
	echo "OpenStack RC environment file does not exist."
	echo "Usage bash $0 <OpenStack RC environment file>"
	echo -e "${NC}"
	exit 1
fi

echo -e "\n${GREEN}${BOLD}Verifying Environment Files Integrity${NC}${NORMAL}"
_ENABLEGIT=false
if ${_ENABLEGIT}
then
	echo -e -n " - Verifying git binary ...\t\t\t\t\t\t\t\t"
	which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find git and any changes will be commited." false soft
	echo -e "${GREEN} [OK]${NC}"
fi

echo -e -n " - Verifying dos2unix binary ...\t\t\t\t\t\t\t"
which dos2unix > /dev/null 2>&1 || exit_for_error "Error, Cannot find dos2unix binary, please install it\nThe installation will continue BUT the Wrapper cannot ensure the File Unix format consistency." false soft
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying md5sum binary ...\t\t\t\t\t\t\t\t"
which md5sum > /dev/null 2>&1 || exit_for_error "Error, Cannot find md5sum binary." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Convert every files exept the GITs one
#####
echo -e -n " - Eventually converting files in Standard Unix format ...\t\t\t\t"
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
echo -e -n " - Verifying if there is the environment file ...\t\t\t\t\t"
if [ ! -f ${_ENV} ] || [ ! -r ${_ENV} ] || [ ! -s ${_ENV} ]
then
	exit_for_error "Error, Environment file missing." false hard
fi
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if there is any duplicated entry in the environment file
#####
echo -e -n " - Verifying duplicate entries in the environment file ...\t\t\t\t"
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
echo -e -n " - Verifying if there is a test for each entry in the environment file ...\t\t"
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
echo -e -n " - Verifying if the environment file has all of the right input values ...\t\t"
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

echo -e "${GREEN}${BOLD}Verifying OpenStack Binary${NC}${NORMAL}"
#####
# Verify binary
#####
_BINS="nova glance cinder neutron heat"
for _BIN in ${_BINS}
do
        echo -e -n " - Verifying ${_BIN} binary ...\t\t"
        which ${_BIN} > /dev/null 2>&1 || exit_for_error "Error, Cannot find python${_BIN}-client." false
        echo -e "${GREEN} [OK]${NC}"
done

echo -e -n " - Verifying Heat Assume Yes ...\t\t"
_ASSUMEYES=""
heat help stack-delete|grep "\-\-yes" >/dev/null 2>&1
if [[ "${?}" == "0" ]]
then
        _ASSUMEYES="--yes"
        echo -e "${GREEN} [OK]${NC}"
else
        echo -e "${YELLOW} [NOT AVAILABLE]${NC}"
fi

echo -e "\n${GREEN}${BOLD}Verifying OpenStack Credential Authentication${NC}${NORMAL}"
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
echo -e -n " - Loading environment file ...\t\t"
source ${_RCFILE}
echo -e "${GREEN} [OK]${NC}"

#FIXME
exit 0

#####
# Verify if the given credential are valid. This will also check if the use can contact Heat
#####
echo -e -n " - Verifying OpenStack credential ...\t\t"
nova --timeout 5 endpoints > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e "\n${GREEN}${BOLD}Verifying OpenStack API Access${NC}${NORMAL}"
echo -e -n " - Verifying access to OpenStack Nova API ...\t\t"
nova list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying access to OpenStack Glance API ...\t\t"
glance image-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying access to OpenStack Cinder API ...\t\t"
cinder list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying access to OpenStack Neutron API ...\t\t"
neutron net-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying access to OpenStack Heat API ...\t\t"
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

for _UNITTOBEVALIDATED in "cms" "dsu" "lvu" "mau" "omu" "smu" "vm-asu"
do
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
                if $(cat ../${_ENV}|awk '/'${_UNITLOWER}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
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
                        _VOLUME_SOURCE_STATUS=$(cinder show temp-${_VOLUMEID}|grep status|grep -v extended_status|awk '{print $4}')
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
done

#TODO
# Add Quota Validation
# Add Generic Environment validation

exit 0

