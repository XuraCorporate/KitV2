#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function exit_for_error {
        _MESSAGE=$1
	_CHANGEDIR=$2
	echo -e "${RED}${_MESSAGE}${NC}"
	if ${_CHANGEDIR}
	then
		cd ${_CURRENTDIR}
	fi
        exit 1
}

if [[ "$1" == "" ]]
then
	echo -e "${RED}Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete>${NC}"
	exit 1
fi

_RCFILE=$1
_ACTION=$2
_STACKNAME=PreparetionStack
#_STACKNAME=${3-PreparetionStack}

if [ ! -e ${_RCFILE} ]
then
	echo -e "${RED}"
	echo "OpenStack RC environment file does not exist."
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete>"
	echo -e "${NC}"
	exit 1
fi

if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" ]]
then
	echo -e "${RED}"
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "Usage bash $0 <OpenStack RC environment file> <Create/Update/List/Delete>"
	echo -e "${NC}"
	exit 1
fi

for _ENV in $(env|grep ^OS|awk -F "=" '{print $1}')
do
	unset ${_ENV}
done
echo -e -n "Loading environment file ...\t\t"
source ${_RCFILE}
echo -e "${GREEN} [OK]${NC}"

echo -e -n "Verifing Heat binary ...\t\t"
which heat > /dev/null 2>&1 || exit_for_error "Error, Cannot find pythonheat-client." false
echo -e "${GREEN} [OK]${NC}"
echo -e -n "Verifing OpenStack credential ...\t\t"
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false
echo -e "${GREEN} [OK]${NC}"

_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

echo -e "${GREEN}Performing Action ${_ACTION}${NC}"
if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
then
	echo -e -n "Verifing if ${_STACKNAME} is already loaded ...\t\t"
	heat resource-list ${_STACKNAME} > /dev/null 2>&1
	if [[ "${_ACTION}" == "Create" && "${?}" == "0" ]]
	then
		exit_for_error "Error, The Stack already exist." true
	fi
	echo -e "${GREEN} [OK]${NC}"
	
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') \
	 --template-file ../templates/preparation.yaml \
	 --environment-file ../environment/common.yaml \
	${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
elif [[ "${_ACTION}" != "List" ]]
then
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
else
	heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKNAME} || exit_for_error "Error, During Stack ${_ACTION}." true
fi

cd ${_CURRENTDIR}

exit 0

