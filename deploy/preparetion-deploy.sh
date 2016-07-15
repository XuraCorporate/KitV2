#!/bin/bash

if [[ "$1" == "" ]]
then
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> [StackName - default PreparetionStack]"
	exit 1
fi

_RCFILE=$1
_ACTION=$2
_STACKNAME=${3-PreparetionStack}

if [ ! -e ${_RCFILE} ]
then
	echo "RC File does not exist."
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> [StackName]"
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
	echo "Usage bash $0 <RC File> <Create/Update/List/Delete> [StackName]"
	exit 1
fi

source ${_RCFILE}

_CURRENTDIR=$(pwd)
cd ${_CURRENTDIR}/$(dirname $0)

if [[ "${_ACTION}" != "Delete" && "${_ACTION}" != "List" ]]
then
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') \
	 --template-file ../templates/preparation.yaml \
	 --environment-file ../environment/common.yaml \
	${_STACKNAME} || (echo "Error during Stack ${_ACTION}." ; exit 1)
elif [[ "${_ACTION}" != "List" ]]
then
	heat stack-$(echo "${_ACTION}" | awk '{print tolower($0)}') ${_STACKNAME} || (echo "Error during Stack ${_ACTION}." ; exit 1)
else
	heat resource-$(echo "${_ACTION}" | awk '{print tolower($0)}') -n 20 ${_STACKNAME} || (echo "Error during Stack ${_ACTION}." ; exit 1)
fi

cd ${_CURRENTDIR}

exit 0

