#!/bin/bash

function exit_for_error {
        _MESSAGE=$1
	_CHANGEDIR=$2
        echo ${_MESSAGE}
	if ${_CHANGEDIR}
	then
		cd ${_CURRENTDIR}
	fi
        exit 1
}

if [[ "$1" == "" ]]
then
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete>"
	exit 1
fi

_RCFILE=$1
_ACTION=$2
_STACKNAME=PreparetionStack
#_STACKNAME=${3-PreparetionStack}

if [ ! -e ${_RCFILE} ]
then
	echo "RC File does not exist."
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete>"
	exit 1
fi

if [[ "${_ACTION}" != "Create" && "${_ACTION}" != "Update" && "${_ACTION}" != "List" && "${_ACTION}" != "Delete" ]]
then
	echo "Action not valid."
	echo "It must be in the following format:"
	echo "\"Create\" - To create a new ${_STACKNAME}"
	echo "\"Update\" - To update the stack ${_STACKNAME}"
	echo "\"List\" - To list the resource in the stack ${_STACKNAME}"
	echo "\"Delete\" - To delete the stack ${_STACKNAME} - WARNING cannot be reversed!"
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete>"
	exit 1
fi

source ${_RCFILE}

which heat > /dev/null 2>&1 || exit_for_error "Error, Cannot find pythonheat-client." false
heat stack-list > /dev/null 2>&1 || exit_for_error "Error, During credential validation." false

_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
then
	heat resource-list ${_STACKNAME} > /dev/null 2>&1
	if [[ "${_ACTION}" == "Create" && "${?}" == "0" ]]
	then
		exit_for_error "Error, The Stack already exist." true
	fi
	
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

