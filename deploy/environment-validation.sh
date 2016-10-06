
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

function csv_validation {
	echo -e -n "   - Verifying unit $(echo ${_UNITTOBEVALIDATED}|awk '{ print toupper($0) }') CSV file ${_CSV} ...\t\t"
	if [ ! -f ${_CSV} ] || [ ! -r ${_CSV} ] || [ ! -s ${_CSV} ]
	then
	        exit_for_error "CSV File ${_CSV} Network with mapping PortID,MacAddress,FixedIP does not exist." false soft
	fi
	echo -e "${GREEN} [OK]${NC}"
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

echo -e "${GREEN}${BOLD}Verifying Environment Files Integrity${NC}${NORMAL}"
_ENABLEGIT=false
if ${_ENABLEGIT}
then
	echo -e -n " - Verifying git binary ...\t\t\t\t\t\t\t"
	which git > /dev/null 2>&1 || exit_for_error "Error, Cannot find git and any changes will be commited." false soft
	echo -e "${GREEN} [OK]${NC}"
fi

echo -e -n " - Verifying dos2unix binary ...\t\t\t\t\t\t"
which dos2unix > /dev/null 2>&1 || exit_for_error "Error, Cannot find dos2unix binary, please install it\nThe installation will continue BUT the Wrapper cannot ensure the File Unix format consistency." false soft
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying md5sum binary ...\t\t\t\t\t\t\t"
which md5sum > /dev/null 2>&1 || exit_for_error "Error, Cannot find md5sum binary." false hard
echo -e "${GREEN} [OK]${NC}"

#####
# Convert every files exept the GITs one
#####
echo -e -n " - Eventually converting files in Standard Unix format ...\t\t\t"
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
echo -e -n " - Verifying if there is the environment file ...\t\t\t\t"
if [ ! -f ${_ENV} ] || [ ! -r ${_ENV} ] || [ ! -s ${_ENV} ]
then
	exit_for_error "Error, Environment file missing." false hard
fi
echo -e "${GREEN} [OK]${NC}"

#####
# Verify if there is any duplicated entry in the environment file
#####
echo -e -n " - Verifying duplicate entries in the environment file ...\t\t\t"
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
echo -e -n " - Verifying if there is a test for each entry in the environment file ...\t"
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
echo -e -n " - Verifying if the environment file has all of the right input values ...\t"
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

echo -e "\n${GREEN}${BOLD}Verifying OpenStack Binary${NC}${NORMAL}"
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

echo -e -n " - Verifying Heat Assume Yes ...\t"
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

#####
# Verify if the given credential are valid. This will also check if the use can contact Heat
#####
echo -e -n " - Verifying OpenStack credential ...\t"
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

echo -e -n " - Verifying access to OpenStack Neutron API ...\t"
neutron net-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Verifying access to OpenStack Heat API ...\t\t"
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

echo -e "\n${GREEN}${BOLD}Verifying Units Specific Characteristic${NC}${NORMAL}"
#####
# Change directory into the deploy one
#####
_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

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
                if $(cat ../${_ENV}|awk '/'${_UNITTOBEVALIDATED}'_local_boot/ {print $2}'|awk '{print tolower($0)}')
                then
                        echo -e " - ${GREEN}The Unit ${_UNITTOBEVALIDATED} will boot from the local hypervisor disk (aka Ephemeral Disk)${NC}"
                else
                        echo -e " - ${GREEN}The Unit ${_UNITTOBEVALIDATED} will boot from Volume (aka from the SAN)${NC}"
                fi
                echo -e -n "   - Validating chosen Glance Image ${_IMAGE} ...\t"
                glance image-show ${_IMAGEID}|grep "${_IMAGE}" >/dev/null 2>&1 || exit_for_error "Error, Image for Unit ${_UNITTOBEVALIDATED} not present or mismatch between ID and Name." true hard
                echo -e "${GREEN} [OK]${NC}"
        elif [[ "${_SOURCE}" == "cinder" ]]
        then
                echo -e " - ${GREEN}The Unit ${_UNITTOBEVALIDATED} will boot from Volume (aka from the SAN)${NC}"
                echo -e -n "   - Validating chosen Cinder Volume ${_VOLUMEID} ...\t\t\t\t"
                cinder show ${_VOLUMEID} >/dev/null 2>&1 || exit_for_error "Error, Volume for Unit ${_UNITTOBEVALIDATED} not present." true hard
                echo -e "${GREEN} [OK]${NC}"

                echo -e -n "   - Validating given volume size ...\t\t\t\t\t\t\t\t"
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
                echo -e -n "   - Validating if volume cloning/snapshotting feature is available ...\t\t\t"
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
        echo -e -n "   - Validating chosen Flavor ${_FLAVOR} ...\t\t\t\t\t\t"
        nova flavor-show "${_FLAVOR}" >/dev/null 2>&1 || exit_for_error "Error, Flavor for Unit ${_UNITTOBEVALIDATED} not present." true hard
        echo -e "${GREEN} [OK]${NC}"
done

echo -e "\n${GREEN}${BOLD}Verifying Units CVS Files${NC}${NORMAL}"
for _UNITTOBEVALIDATED in "cms" "dsu" "lvu" "mau" "omu" "smu" "vm-asu"
do
        _CSVFILEPATH=../environment/${_UNITTOBEVALIDATED}
        _ADMINCSVFILE=$(echo ${_CSVFILEPATH}/admin.csv)
        _SZCSVFILE=$(echo ${_CSVFILEPATH}/sz.csv)
        _SIPCSVFILE=$(echo ${_CSVFILEPATH}/sip.csv)
        _MEDIACSVFILE=$(echo ${_CSVFILEPATH}/media.csv)

	echo -e " - $(echo ${_UNITTOBEVALIDATED}|awk '{ print toupper($0) }')"
        for _CSV in "${_ADMINCSVFILE}" "${_SZCSVFILE}" "${_SIPCSVFILE}" "${_MEDIACSVFILE}"
        do
                #####
                # Check if the CSV File
                # - Does it exist?
                # - Is it readable?
                # - Does it have a size higher than 0Byte?
                # - Does it have the given starting line?
                # - Does it have the given ending line?
                #####
                if [[ "${_UNITTOBEVALIDATED}" == "cms" ]] && [[ "${_CSV}" =~ "sip.csv" || "${_CSV}" =~ "media.csv" ]]
                then
                        csv_validation
                fi

                if [[ "${_UNITTOBEVALIDATED}" != "mau" ]] && [[ "${_CSV}" =~ "sz.csv" ]]
                then
                        csv_validation
                fi

                if [[ "${_CSV}" =~ "admin.csv" ]]
                then
                        csv_validation
                fi
        done
done

echo -e "\n${GREEN}${BOLD}Verifying OpenStack Quota${NC}${NORMAL}"
echo -e -n " - Gathering CMS Quota ...\t\t"
_CMSFLAVOR=$(cat ../environment/common.yaml|awk '/cms_flavor_name/ {print $2}'|sed "s/\"//g")
_CMSFLAVOROUTPUT=$(nova flavor-show ${_CMSFLAVOR})
_CMSVCPU=$(echo "${_CMSFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_CMSVRAM=$(echo "${_CMSFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_CMSVDISK=$(echo "${_CMSFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_CMSUNITS=$(cat ../environment/cms/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering DSU Quota ...\t\t"
_DSUFLAVOR=$(cat ../environment/common.yaml|awk '/dsu_flavor_name/ {print $2}'|sed "s/\"//g")
if [[ "${_DSUFLAVOR}" == "${_CMSFLAVOR}" ]]
then
	_DSUFLAVOROUTPUT=${_CMSFLAVOROUTPUT}
else
	_DSUFLAVOROUTPUT=$(nova flavor-show ${_DSUFLAVOR})
fi
_DSUVCPU=$(echo "${_DSUFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_DSUVRAM=$(echo "${_DSUFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_DSUVDISK=$(echo "${_DSUFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_DSUUNITS=$(cat ../environment/dsu/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering LVU Quota ...\t\t"
_LVUFLAVOR=$(cat ../environment/common.yaml|awk '/lvu_flavor_name/ {print $2}'|sed "s/\"//g")
if [[ "${_LVUFLAVOR}" == "${_DSUFLAVOR}" ]]
then
	_LVUFLAVOROUTPUT=${_DSUFLAVOROUTPUT}
else
	_LVUFLAVOROUTPUT=$(nova flavor-show ${_LVUFLAVOR})
fi
_LVUVCPU=$(echo "${_LVUFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_LVUVRAM=$(echo "${_LVUFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_LVUVDISK=$(echo "${_LVUFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_LVUUNITS=$(cat ../environment/lvu/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering MAU Quota ...\t\t"
_MAUFLAVOR=$(cat ../environment/common.yaml|awk '/mau_flavor_name/ {print $2}'|sed "s/\"//g")
if [[ "${_MAUFLAVOR}" == "${_LVUFLAVOR}" ]]
then
	_MAUFLAVOROUTPUT=${_LVUFLAVOROUTPUT}
else
	_MAUFLAVOROUTPUT=$(nova flavor-show ${_MAUFLAVOR})
fi
_MAUVCPU=$(echo "${_MAUFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_MAUVRAM=$(echo "${_MAUFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_MAUVDISK=$(echo "${_MAUFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_MAUUNITS=$(cat ../environment/mau/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering OMU Quota ...\t\t"
_OMUFLAVOR=$(cat ../environment/common.yaml|awk '/omu_flavor_name/ {print $2}'|sed "s/\"//g")
if [[ "${_OMUFLAVOR}" == "${_MAUFLAVOR}" ]]
then
	_OMUFLAVOROUTPUT=${_MAUFLAVOROUTPUT}
else
	_OMUFLAVOROUTPUT=$(nova flavor-show ${_OMUFLAVOR})
fi
_OMUVCPU=$(echo "${_OMUFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_OMUVRAM=$(echo "${_OMUFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_OMUVDISK=$(echo "${_OMUFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_OMUUNITS=$(cat ../environment/omu/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering SMU Quota ...\t\t"
_SMUFLAVOR=$(cat ../environment/common.yaml|awk '/smu_flavor_name/ {print $2}'|sed "s/\"//g")
if [[ "${_SMUFLAVOR}" == "${_OMUFLAVOR}" ]]
then
	_SMUFLAVOROUTPUT=${_OMUFLAVOROUTPUT}
else
	_SMUFLAVOROUTPUT=$(nova flavor-show ${_SMUFLAVOR})
fi
_SMUVCPU=$(echo "${_SMUFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_SMUVRAM=$(echo "${_SMUFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_SMUVDISK=$(echo "${_SMUFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_SMUUNITS=$(cat ../environment/smu/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering VM-ASU Quota ...\t\t"
_VMASUFLAVOR=$(cat ../environment/common.yaml|awk '/vm-asu_flavor_name/ {print $2}'|sed "s/\"//g")
if [[ "${_VMASUFLAVOR}" == "${_SMUFLAVOR}" ]]
then
	_VMASUFLAVOROUTPUT=${_SMUFLAVOROUTPUT}
else
	_VMASUFLAVOROUTPUT=$(nova flavor-show ${_VMASUFLAVOR})
fi
_VMASUVCPU=$(echo "${_VMASUFLAVOROUTPUT}"|grep " vcpus "|awk '{print $4}')
_VMASUVRAM=$(echo "${_VMASUFLAVOROUTPUT}"|grep " ram "|awk '{print $4}')
_VMASUVDISK=$(echo "${_VMASUFLAVOROUTPUT}"|grep " disk "|awk '{print $4}')
_VMASUUNITS=$(cat ../environment/vm-asu/admin.csv|wc -l)
echo -e "${GREEN} [OK]${NC}"

echo -e -n " - Gathering Tenant Quota ...\t\t"
_TENANTQUOTA=$(nova quota-show)
_TENANTVCPU=$(echo "${_TENANTQUOTA}"|awk '/\| cores / {print $4}')
_TENANTVRAM=$(echo "${_TENANTQUOTA}"|awk '/\| ram / {print $4}')
_TENANTVDISK=$(echo "${_TENANTQUOTA}"|awk '/\| disk / {print $4}')
_TENANTVMS=$(echo "${_TENANTQUOTA}"|awk '/\| instances / {print $4}')
echo -e "${GREEN} [OK]${NC}"

echo -e " - Verifying Tenant Quota for all of the Units"
_NEEDEDVCPU=$(( (${_CMSVCPU} * ${_CMSUNITS}) + (${_DSUVCPU} * ${_DSUUNITS}) + (${_LVUVCPU} * ${_LVUUNITS}) + (${_MAUVCPU} * ${_MAUUNITS}) + (${_OMUVCPU} * ${_OMUUNITS}) + (${_SMUVCPU} * ${_SMUUNITS}) + (${_VMASUVCPU} * ${_VMASUUNITS}) ))
_NEEDEDVRAM=$(( (${_CMSVRAM} * ${_CMSUNITS}) + (${_DSUVRAM} * ${_DSUUNITS}) + (${_LVUVRAM} * ${_LVUUNITS}) + (${_MAUVRAM} * ${_MAUUNITS}) + (${_OMUVRAM} * ${_OMUUNITS}) + (${_SMUVRAM} * ${_SMUUNITS}) + (${_VMASUVRAM} * ${_VMASUUNITS}) ))
_NEEDEDVDISK=$(( (${_CMSVDISK} * ${_CMSUNITS}) + (${_DSUVDISK} * ${_DSUUNITS}) + (${_LVUVDISK} * ${_LVUUNITS}) + (${_MAUVDISK} * ${_MAUUNITS}) + (${_OMUVDISK} * ${_OMUUNITS}) + (${_SMUVDISK} * ${_SMUUNITS}) + (${_VMASUVDISK} * ${_VMASUUNITS}) ))
_NEEDEDUNITS=$(( ${_CMSUNITS} + ${_DSUUNITS} + ${_LVUUNITS} + ${_MAUUNITS} + ${_OMUUNITS} + ${_SMUUNITS} + ${_VMASUUNITS} ))

if (( ${_NEEDEDVCPU} <= ${_TENANTVCPU} )) || [[ ${_TENANTVCPU} == "-1" ]]
then
	if [[ ${_TENANTVCPU} == "-1" ]]
	then
		echo -e "   - The Tenant Quota has unlimited vCPU and you are going to use ${GREEN}${_NEEDEDVCPU}${NC}"
	else
		echo -e "   - The Tenant Quota has ${_TENANTVCPU} vCPU and you are going to use ${GREEN}${_NEEDEDVCPU}${NC}"
	fi
else
	echo -e "${RED}   - The Tenant Quota has ${_TENANTVCPU} vCPU and you are going to use ${_NEEDEDVCPU}${NC}"
fi

if (( ${_NEEDEDVRAM} <= ${_TENANTVRAM} )) || [[ ${_TENANTVRAM} == "-1" ]]
then
	if [[ ${_TENANTVRAM} == "-1" ]]
	then
		echo -e "   - The Tenant Quota has unlimited vRAM and you are going to use ${GREEN}${_NEEDEDVRAM}${NC}"
	else
		echo -e "   - The Tenant Quota has ${_TENANTVRAM} vRAM and you are going to use ${GREEN}${_NEEDEDVRAM}${NC}"
	fi
else
	echo -e "${RED}   - The Tenant Quota has ${_TENANTVRAM} vRAM and you are going to use ${_NEEDEDVRAM}${NC}"
fi

if [[ "$(echo ${_TENANTVDISK}|grep -E -v "[0-9]")" == "" && "${_TENANTVDISK}" != "" ]]
then 
	if (( ${_NEEDEDVDISK} <= ${_TENANTVDISK} )) || [[ ${_TENANTVDISK} == "-1" ]]
	then
		if [[ ${_TENANTVDISK} == "-1" ]]
		then
			echo -e "   - The Tenant Quota has unlimited vDISK and you are going to use ${GREEN}${_NEEDEDVDISK}${NC}"
		else
			echo -e "   - The Tenant Quota has ${_TENANTVDISK} vDISK and you are going to use ${GREEN}${_NEEDEDVDISK}${NC}"
		fi
	else
		echo -e "${RED}   - The Tenant Quota has ${_TENANTVDISK} vDISK and you are going to use ${_NEEDEDVDISK}${NC}"
	fi
#else
#	echo -e "${YELLOW}   - This OpenStack version does not support Tenant Disk Quota${NC}"
fi

if (( ${_NEEDEDUNITS} <= ${_TENANTVMS} )) || [[ ${_TENANTVMS} == "-1" ]]
then
	if [[ ${_TENANTVMS} == "-1" ]]
	then
		echo -e "   - The Tenant Quota has unlimited Instance and you are going to create ${GREEN}${_NEEDEDUNITS}${NC}"
	else
		echo -e "   - The Tenant Quota has ${_TENANTVMS} Instance and you are going to create ${GREEN}${_NEEDEDUNITS}${NC}"
	fi
else
	echo -e "${RED}   - The Tenant Quota has ${_TENANTVMS} Instance and you are going to create ${_NEEDEDUNITS}${NC}"
fi

#for _UNITTOBEVALIDATED in "cms" "dsu" "lvu" "mau" "omu" "smu" "vm-asu"
#do
#	_CSVFILEPATH=environment/${_UNITTOBEVALIDATED}
#	_ADMINCSVFILE=$(echo ${_CSVFILEPATH}/admin.csv)
#	_SZCSVFILE=$(echo ${_CSVFILEPATH}/sz.csv)
#	_SIPCSVFILE=$(echo ${_CSVFILEPATH}/sip.csv)
#	_MEDIACSVFILE=$(echo ${_CSVFILEPATH}/media.csv)
#
#	if [[ "${_UNITTOBEVALIDATED}" == "cms" ]]
#	then
#		cat ../${_SIPCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SIPCSVFILE}.tmp
#		cat ../${_MEDIACSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_MEDIACSVFILE}.tmp
#	fi
#
#	if [[ "${_UNITTOBEVALIDATED}" != "mau" ]]
#	then
#		cat ../${_SZCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_SZCSVFILE}.tmp
#	fi
#
#	cat ../${_ADMINCSVFILE}|tail -n+${_INSTANCESTART} | sed -e "s/\^M//g" | grep -v "^$" > ../${_ADMINCSVFILE}.tmp
#
#done

#TODO
# Add Quota Validation
# Add Network validation

cd ${_CURRENTDIR}
exit 0

