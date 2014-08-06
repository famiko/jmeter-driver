#!/bin/sh --

#
# The environment
SLAVE_IMAGE=srisankaran/jmeter-server
MASTER_IMAGE=srisankaran/jmeter
DATADIR=
JMX_SCRIPT=
CWD=$(readlink -f .)
NUM_SERVERS=1
HOST_WRITE_PORT=49500
HOST_READ_PORT=49501

#
# Getopts to read - datadir, CWD, count of servers, script dir
# script -d data-dir -s script-dir -w work-dir -n num-servers
while getopts :d:s:w:n: opt
do
	case ${opt} in
		d) DATADIR=$(readlink -f ${OPTARG}) ;;
		s) JMX_SCRIPT=$(readlink -f ${OPTARG}) ;;
		w) CWD=$(readlink -f ${OPTARG}) ;;
		n) NUM_SERVERS=${OPTARG} ;;
		:) echo "The -${OPTARG} option requires a parameter"
			 exit 1 ;;
		?) echo "Invalid option: -${OPTARG}"
			 exit 1 ;;
	esac
done
shift $((OPTIND -1))

#
# Validate environment
if [[ ! -d ${CWD} ]] ; then
  echo "The working directory '${CWD}' does not exist"
	exit 1
fi
if [[ ! -d ${DATADIR} ]] ; then
  echo "The data directory '${DATADIR}' does not exist"
	exit 1
fi
if [[ ! -f ${JMX_SCRIPT} ]] ; then
  echo "The script file '${JMX_SCRIPT}' does not exist"
	exit 1
fi
if [[ ${NUM_SERVERS} -lt 1 ]]; then
	echo "Must start at least 1 JMX server."
	exit 1
fi
echo "DATADIR=${DATADIR}"
echo "JMX_SCRIPT=${JMX_SCRIPT}"
echo "CWD=${CWD}"
echo "NUM_SERVERS=${NUM_SERVERS}"

#
# Set a working directory.
cd ${CWD}

#
# Create a place for all the log files
mkdir -p ${CWD}/logs

#
# Start the specified number of jmeter-server containers
n=1
while [[ ${n} -lt ${NUM_SERVERS} ]]
do
	LOGDIR=${CWD}/logs/${n}
  mkdir -p ${LOGDIR}

	docker run --cidfile ${LOGDIR}/cid \
				-d \
				-p 0.0.0.0:${HOST_READ_PORT}:1099 \
				-p 0.0.0.0:${HOST_WRITE_PORT}:60000 \
				-v ${LOGDIR}:/logs \
				-v ${DATADIR}:/scripts \
				${SLAVE_IMAGE}
  n=$((${n} + 1))
	HOST_READ_PORT=$((${HOST_READ_PORT} +  2))
	HOST_WRITE_PORT=$((${HOST_WRITE_PORT} + 2))
done

#
# Get the IP addresses for the servers
SERVER_IPS=
for pid in $(docker ps | grep jmeter-server | awk '{print $1}')
do
  x=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${pid})
	if [[ ! -z "${SERVER_IPS}" ]]; then
		SERVER_IPS=${SERVER_IPS},
	fi
	SERVER_IPS=${SERVER_IPS}$x
done
# SERVER_IPS will be string of the form 1.2.3.4,9.8.7.6

#
# Start the jmeter (client) container and connect to the servers
LOGDIR=${CWD}/logs/client
mkdir -p ${LOGDIR}
docker run --cidfile ${LOGDIR}/cid \
				-d \
				-v ${LOGDIR}:/logs \
				${MASTER_IMAGE} -n -t ${JMX_SCRIPT} -l ${LOGDIR}/jtl.jtl -LDEBUG -R${SERVER_IPS}

# TODO Client must somehow notify host of job completion

# TODO Shutdown the client

# TODO Shutdown the servers

# TODO Clean up dirs