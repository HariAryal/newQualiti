#!/bin/bash

  set -ex

  API_KEY='fa46137d6521d5b7'
  INTEGRATIONS_API_URL='https://api.qualiti-dev.com'
  PROJECT_ID='3'
  CLIENT_ID='6d119d75cae71978db692cf76ca5af0d'
  SCOPES=['"ViewTestResults"','"ViewAutomationHistory"']
  API_URL='https://3000-qualitiai-qualitiapi-f7dl5n54uwn.ws-us47.gitpod.io/public/api'
  INTEGRATION_JWT_TOKEN='7be2df4b86e2cf168f5e8a8f655b2dcf47522ef58f174c527b5e6e75961f9293e824d4bd0f1a98dc38c81dce565a29a88fe69b24f51ac82ca0ad1ce4881863ed68a9adee7245397c9f105fe8cbe3e2ec1bbdb3efcbbc03254246f479dc07d854cf0c182407d5f1be147d39342815072ceba42d16fb3ae227b13f42bc4cf966db8694278bf5bbb2185e7372c7cb0945e905b0776e45cfa4efa61dcd899f01f9ffacb36ebce6bc34fd47bfa602a43d3546821653755081eb0f6801c9e49d692c9eecd06def8489cfea4b2d76cd3e507a9f8e0a2a51230875b7d74fade54cf0c2124b3896ed49e81e3a28dd7fb8543e82dfb9714af09ba533e36c8123847075635a99755b6e2248e69dd9c0d93b8b4b1dd0|e34e529fdb8c1abda96d06a6784af525|80e45f7cbb16483e7eb9cb10eef11cfd'

  apt-get update -y
  apt-get install -y jq

  #Trigger test run
  TEST_RUN_ID="$( \
    curl -X POST -G ${INTEGRATIONS_API_URL}/integrations/github/${PROJECT_ID}/events \
      -d 'token='$INTEGRATION_JWT_TOKEN''\
      -d 'triggerType=Deploy'\
    | jq -r '.test_run_id')"

  AUTHORIZATION_TOKEN="$( \
    curl -X POST -G ${API_URL}/auth/token \
    -H 'x-api-key: '${API_KEY}'' \
    -H 'client_id: '${CLIENT_ID}'' \
    -H 'scopes: '${SCOPES}'' \
    | jq -r '.token')"

  # Wait until the test run has finished
  TOTAL_ITERATION=200
  I=1
  while : ; do
     RESULT="$( \
     curl -X GET ${API_URL}/automation-history?project_id=${PROJECT_ID}\&test_run_id=${TEST_RUN_ID} \
     -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
     -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].finished')"
    if [ "$RESULT" != null ]; then
      break;
    if [ "$I" -ge "$TOTAL_ITERATION" ]; then
      echo "Exit qualiti execution for taking too long time.";
      exit 1;
    fi
    fi
      sleep 15;
  done

  # # Once finished, verify the test result is created and that its passed
  TEST_RUN_RESULT="$( \
    curl -X GET ${API_URL}/test-results?test_run_id=${TEST_RUN_ID}\&project_id=${PROJECT_ID} \
      -H 'token: Bearer '$AUTHORIZATION_TOKEN'' \
      -H 'x-api-key: '${API_KEY}'' \
    | jq -r '.[0].status' \
  )"
  echo "Qualiti E2E Tests ${TEST_RUN_RESULT}"
  if [ "$TEST_RUN_RESULT" = "Passed" ]; then
    exit 0;
  fi
  exit 1;
  
