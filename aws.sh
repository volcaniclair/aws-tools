#!/bin/bash

PROFILE="wca_dev"
REGION="eu-west-2"

TYPE="ec2"

function runCommand {
	echo -e "${HEADER}"
	if [ -z ${QUERY} ] && [ -z ${OUTPUT} ]
	then
	        aws --profile ${PROFILE} --region ${REGION} ${COMMAND}
	elif [ -z ${QUERY} ]
	then
	        aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --output ${OUTPUT}
	elif [ -z ${OUTPUT} ]
	then
	        aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --query ${QUERY}
	else
	        aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --query ${QUERY} --output ${OUTPUT}
	fi
}

while [ ${#} -gt 0 ]
do
	case ${1} in
		"-t"|"--type")
			TYPE=${2}
			shift
			;;
	esac
	shift
done

case ${TYPE} in
	"ec2")
		echo "Instances:"
		echo
		HEADER="Instance ID\tName\tState\tPrivate IP\tPublic IP"
		COMMAND="ec2 describe-instances"
		QUERY='Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress,PublicIpAddress]'
		OUTPUT="text"
		runCommand | column -s$'\t' -t
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
		echo
		${0} -t vpcs
		echo
		${0} -t ec2
		;;
esac

exit 0


echo -e "${HEADER}"
#aws --profile ${PROFILE} --region ${REGION} ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress,PublicIpAddress]' --output text
#aws --profile ${PROFILE} --region ${REGION} ${COMMAND}
if [ -z ${QUERY} ] && [ -z ${OUTPUT} ]
then
	aws --profile ${PROFILE} --region ${REGION} ${COMMAND}
elif [ -z ${QUERY} ]
then
	aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --output ${OUTPUT}
elif [ -z ${OUTPUT} ]
then
	aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --query ${QUERY}
else
	aws --profile ${PROFILE} --region ${REGION} ${COMMAND} --query ${QUERY} --output ${OUTPUT}
fi
