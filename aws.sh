#!/bin/bash

function getVPCInformation {
	echo
	echo "Overview of VPC Contents:"
        echo
        VPC_HEADER="VPC ID\tState\tDHCP Options ID\tCIDR Block"
        #HEADER="${VPC_HEADER}"
        COMMAND="ec2 describe-vpcs"
        QUERY='Vpcs[*].[VpcId,State,DhcpOptionsId,CidrBlock]'
        OUTPUT="text"
        runCommand
	#echo "${COMMAND_OUTPUT}"
	#echo
	OLDIFS=${IFS}
	IFS=$'\n'
	for LINE in ${COMMAND_OUTPUT}
	do
		VPCS+=( ${LINE} )
	done
	for VPC in ${VPCS[@]}
	do
		IFS=$'\n'
		#echo -e "${VPC_HEADER}" | column -s$'\t' -t
		#echo "${VPC}" | column -s$'\t' -t
		#echo
		VPC_ID=$( echo ${VPC} | awk -F'\t' '{ print $1 }' )
		VPC_STATE=$( echo ${VPC} | awk -F'\t' '{ print $2 }' )
		VPC_DHCP=$( echo ${VPC} | awk -F'\t' '{ print $3 }' )
		VPC_CIDR=$( echo ${VPC} | awk -F'\t' '{ print $4 }' )
		echo
		echo "${VPC_ID}"
		echo "-----"
		echo -e "State:\t\t\t${VPC_STATE}"
		echo -e "DHCP Options ID:\t${VPC_DHCP}"
		echo -e "CIDR:\t\t\t${VPC_CIDR}"
		echo
		IFS=${OLDIFS}
                HEADER="\tInstance ID\t\tName\tState\tPrivate IP\tPublic IP\tVPC ID"
                COMMAND="ec2 describe-instances"
                FILTER="Name=vpc-id,Values=${VPC_ID}"
                QUERY="Reservations[*].Instances[*].[InstanceId,Tags[?Key==\`Name\`].Value|[0],State.Name,PrivateIpAddress,PublicIpAddress,VpcId]"
                runCommand
		INSTANCE_COUNT=0
		IFS=$'\n'
		for LINE in ${COMMAND_OUTPUT}
		do
			echo -e "\t${LINE}"
			(( INSTANCE_COUNT+=1 ))
		done
                #echo -e "\t${COMMAND_OUTPUT}" | column -s$'\t' -t
		echo
		echo -e "\t${INSTANCE_COUNT} instances"
		echo
	done
}

function runCommand {
	COMMAND_OUTPUT=""
	if [[ "${HEADER}" != "" ]]
	then
		echo -e "${HEADER}"
	fi
	if [ -z "${FILTER}" ] && [ -z "${QUERY}" ] && [ -z "${OUTPUT}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} )
	elif [ -z "${FILTER}" ] && [ -z "${QUERY}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --output "${OUTPUT}" )
	elif [ -z "${FILTER}" ] && [ -z "${OUTPUT}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --query "${QUERY}" )
	elif [ -z "${QUERY}" ] && [ -z "${OUTPUT}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --filters "${FILTER}" )
	elif [ -z "${FILTER}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --query "${QUERY}" --output "${OUTPUT}" )
	elif [ -z "${QUERY}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --filters "${FILTER}" --output "${OUTPUT}" )
	elif [ -z "${OUTPUT}" ]
	then
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --filters "${FILTER}" --query "${QUERY}" )
	else
	        COMMAND_OUTPUT=$( aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --filters "${FILTER}" --query "${QUERY}" --output "${OUTPUT}" )
	        #echo "aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --filters ${FILTER} --query ${QUERY} --output ${OUTPUT}"
	fi
}

while [ ${#} -gt 0 ]
do
	case ${1} in
		"-p"|"--profile")
			PROFILE=${2}
			shift
			;;
		"-r"|"--region")
			REGION=${2}
			shift
			;;
		"-t"|"--type")
			TYPE=${2}
			shift
			;;
	esac
	shift
done

if [ -z ${PROFILE} ] || [ -z ${REGION} ] || [ -z ${TYPE} ]
then
	echo
	echo "ERROR: You must provide a profile, region and type"
	echo
	echo "E.g. ${0} -p myprofile -r eu-west-2 -t overview"
	echo
	exit 1
fi

case ${TYPE} in
	"ec2")
		echo "Instances:"
		echo
		HEADER="Instance ID\tName\tState\tPrivate IP\tPublic IP\tVPC ID"
		COMMAND="ec2 describe-instances"
		#FILTER="Name=vpc-id,Values=vpc-075a716e"
		QUERY='Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress,PublicIpAddress,VpcId]'
		OUTPUT="text"
		#OUTPUT="json"
		#runCommand | column -s$'\t' -t
		runCommand
		echo "COMMAND_OUTPUT: ${COMMAND_OUTPUT}"
		;;
	"vpcs")
		echo "VPCs:"
		echo
		HEADER="VPC ID\tState\tDHCP Options ID\tCIDR Block"
		COMMAND="ec2 describe-vpcs"
		QUERY='Vpcs[*].[VpcId,State,DhcpOptionsId,CidrBlock]'
		OUTPUT="text"
		runCommand | column -s$'\t' -t
		;;
	"overview")
		getVPCInformation
		;;
	*)
		echo
		echo "ERROR: Unknown type: ${TYPE}"
		echo
		exit 1
		;;
esac

exit 0
