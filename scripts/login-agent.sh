#!/bin/bash

set -euf -o pipefail

abort() {
    echo 'ERROR'
    exit 1
}

trap 'abort' EXIT

username=$1
password=$2

echo Get LOGIN information
export SESSION_ID=$(curl -X POST -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"username\":\"${username}\",\"password\":\"${password}\"}" https://${LOGIN_DOMAIN}.informaticacloud.com/saas/public/core/v3/login | jq -r '.userInfo.sessionId')
export TOKEN=$(curl -H "icSessionid: $SESSION_ID" https://na1.dm-us.informaticacloud.com/saas/api/v2/agent/installerInfo/linux64 | jq -r '.installToken')

echo Configure agent

#cd $INFA_SA_HOME/apps/agentcore/; ./infaagent startup

while [[ ! -f $INFA_SA_HOME/apps/agentcore/conf/agentcore.properties ]]; do
    sleep 1
done
echo "agentcore.properties file found"

rmi_port="$(grep rmi_port_number $INFA_SA_HOME/apps/agentcore/conf/agentcore.properties | awk -F = '{print $2}')"

# wait for connect on rmi port
while ! ( echo > "/dev/tcp/localhost/${rmi_port}" ) >/dev/null 2>&1 ; do
    sleep 1
done

echo "Connected on RMI port ${rmi_port}"

sleep 30
cd $INFA_SA_HOME/apps/agentcore/; ./consoleAgentManager.sh configureToken ${username} $TOKEN

export HOSTNAME=`hostname`
echo "Server is running on ${HOSTNAME}"

trap - EXIT