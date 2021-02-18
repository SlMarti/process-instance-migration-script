#!/bin/bash

# Authorization
# change to you auth preferences

secret=`cat ../secret`
curl -s -X POST --data "{}" --header "Content-type: application/json" "http://web_app:changeit@192.168.1.24:9999/oauth/token?username=martynyuk.mstislav&password=${secret}&grant_type=password" | jq -r '.access_token' > access_token
token=`cat access_token`

# Process definition key
PROCESS_DEF_KEY="loan-contract"
# Camunda REST API URL
REST_API_URL="http://192.168.1.26:8084/engine-rest"
# Update event triggers
UPDATE_EVT_TRIGGERS="true"

TARGET_VERSION=`curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "${REST_API_URL}/process-definition/key/${PROCESS_DEF_KEY}" | jq -r '.id'`
SOURCE_VERSIONS=`curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" "${REST_API_URL}/process-instance?processDefinitionKey=${PROCESS_DEF_KEY}" | jq -r '.[].definitionId' | sort | uniq`

for i in ${SOURCE_VERSIONS}
do
    if [ ${i} == ${TARGET_VERSION} ]
    then
	echo "Skipping target version..."
	continue
    fi
    echo "Migration of process definition id: ${i}"
    echo "Generating migration plan..."
    curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" -X POST --data "{ \"sourceProcessDefinitionId\": \"${i}\", \"targetProcessDefinitionId\":\"${TARGET_VERSION}\", \"updateEventTriggers\": ${UPDATE_EVT_TRIGGERS}}" -o response_generate_${i}.json "${REST_API_URL}/migration/generate"
    echo "Validating migration plan"
    curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" -X POST --data "@response_generate_${i}.json" -o response_validate_${i}.json "${REST_API_URL}/migration/validate"
    if [ `cat response_validate_${i}.json | jq -r '.instructionReports | length'` -gt 0 ]
    then
	echo "Migration plan is invalid. Check response: response_validate_${i}.json"
	continue
    else
	echo "...OK"
    fi
    echo "Execution..."
    response=$(curl -s --header "Authorization: Bearer ${token}" --header "Content-Type: application/json" -w '%{http_code}'-X POST --data "{ \"migrationPlan\": `cat response_generate_${i}.json`, \"processInstanceQuery\": { \"processDefinitionId\": \"${i}\" }}" -o response_execute_${i}.json "${REST_API_URL}/migration/execute")
    echo "Response is: ${response}"
done

