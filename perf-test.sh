#!/bin/sh

#
# Copyright 2011 FuseSource
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

#ACTIVEMQ_VERSION=5.3.2
ACTIVEMQ_VERSION=5.5.1-fuse-01-13

#
# Broker config file using the pattern
# conf/<name>.xml
#
#ACTIVEMQ_CONFIG=broker
ACTIVEMQ_CONFIG=activemq-specjms

REPORT_BASE_DIR="report/${ACTIVEMQ_VERSION}/${ACTIVEMQ_CONFIG}"
mkdir -p ${REPORT_BASE_DIR}

#export MAVEN_OPTS="-Xmx2g -Xms1g -XX:+UseLargePages"
export MAVEN_OPTS="-Xmx2g -Xms2g"
mvn -Dactivemq.version=${ACTIVEMQ_VERSION} activemq:run -DconfigUri=xbean:file:src/main/resources/conf/${ACTIVEMQ_CONFIG}.xml -Dorg.apache.activemq.UseDedicatedTaskRunner=false &> ${REPORT_BASE_DIR}/JmsBroker_console.log &
echo $! > broker.pid

# Give Broker a chance to fully startup...
sleep 30

for DELIVERY_MODE in "nonpersistent" "persistent"
do

	REPORT_DIR="${REPORT_BASE_DIR}/${DELIVERY_MODE}/"
	mkdir -p ${REPORT_DIR}

	for NUM_CLIENTS in 1 10
	do
		for MSG_SIZE in 1024 2048
		do

			export MAVEN_OPTS="-Xmx1g -Xms1g"
			mvn -Dactivemq.version=${ACTIVEMQ_VERSION} activemq-perf:consumer "-DsysTest.reportDir=${REPORT_DIR}" -DsysTest.numClients=${NUM_CLIENTS} -Dconsumer.durable=true &> "${REPORT_DIR}/JmsConsumer_${NUM_CLIENTS}pub_${NUM_CLIENTS}sub_${MSG_SIZE}size_console.log" &
			mvn -Dactivemq.version=${ACTIVEMQ_VERSION} activemq-perf:producer "-DsysTest.reportDir=${REPORT_DIR}" -DsysTest.numClients=${NUM_CLIENTS} -Dproducer.messageSize=${MSG_SIZE} -Dfactory.useAsyncSend=false -Dproducer.deliveryMode=${DELIVERY_MODE} &> "${REPORT_DIR}/JmsProducer_${NUM_CLIENTS}pub_${NUM_CLIENTS}sub_${MSG_SIZE}size_console.log"

			sleep 10

		done
	done

done

#
# Clean up Broker
#

kill `cat broker.pid`
rm broker.pid
