#!/bin/bash

ANYPOINT_HOST=eu1.anypoint.mulesoft.com
ANYPOINT_ORGANIZATION=qconn
ANYPOINT_ORGANIZATION_ID=b00670d6-9a9c-4222-af9c-402c16fbf214
ANYPOINT_ENVIRONMENT=Sandbox
ANYPOINT_ENVIRONMENT_ID=42479915-a110-4dcb-9f8e-b1e022afd635
ANYPOINT_POLICIES_ORGANIZATION_ID=e0b4a150-f59b-46d4-ad25-5d98f9deb24a
ANYPOINT_USERNAME=$LOCAL_ENV_ANYPOINT_USERNAME
ANYPOINT_PASSWORD=$LOCAL_ENV_ANYPOINT_PASSWORD
FLEX_GATEWAY_NAME=flex-gateway-one
FLEX_GATEWAY_VERSION=1.8.1
ASSET_ID=echo-api
ENDPOINT_URI=http://localhost:8081
TARGET_URI=https://httpbin.org
API_INSTANCE_DEPLOYED="false"



#upload the API spec to Anypoint Exchange with Anypoint API Catalog CLI 
ASSET_INFO=$(api-catalog publish-asset -d ./catalog.yaml --json --silent)

ASSET_VERSION=$(echo $ASSET_INFO | jq -r '.projects[0].baseVersion')
echo "Asset ID is $ASSET_ID, Asset Version is $ASSET_VERSION"



# verify if THIS Asset Version is managed already
API_INSTANCE_INFO=$(anypoint-cli-v4 api-mgr:api:list \
    --assetId $ASSET_ID \
    --output json)



API_INSTANCE_ID=$(echo $API_INSTANCE_INFO | jq '.[0].id')
API_INSTANCE_STATUS=$(echo $API_INSTANCE_INFO | jq '.[0].status' | xargs)

if [ "$API_INSTANCE_ID" = "null" ] || [ -z "$API_INSTANCE_ID" ]; then
    echo "no API instance found, registering a new one ..."
    anypoint-cli-v4 api-mgr:api:manage \
    --isFlex \
    --withProxy \
    --port 8081 \
    --path /httpbin \
    --endpointUri "${ENDPOINT_URI}" \
    --output json \
    --scheme http \
    --type http \
    --apiInstanceLabel $ANYPOINT_ORGANIZATION-$ASSET_ID \
    --uri $TARGET_URI \
    "${ASSET_ID}" \
    "${ASSET_VERSION}"

    API_INSTANCE_ID=$(anypoint-cli-v4 api-mgr:api:list \
        --assetId $ASSET_ID \
        --output json | jq '.[0].id') 
else
    echo "This Asset is managed already. API Instance ID: $API_INSTANCE_ID"
fi




# apply policies, e.g. basic auth
POLICY_NAME='http-basic-authentication'
POLICY_VERSION='1.3.1'
POLICY_CONFIG='{"username":"user","password":"teste2"}'

# first verify if such policy exists already
ALL_POLICIES=$(anypoint-cli-v4 api-mgr:policy:list $API_INSTANCE_ID --output json)
# remove any existing policy 
echo $ALL_POLICIES | jq -r '.[] | "\(.ID) \(.["Asset ID"])"' | while read -r POLICY_ID ASSET_ID; do
    echo "Removing policy with ID: $POLICY_ID (Asset ID: $ASSET_ID)"
    anypoint-cli-v4 api-mgr:policy:remove "$API_INSTANCE_ID" "$POLICY_ID"
done
# apply updated policies
echo "Applying all the updated policies..."
anypoint-cli-v4 api-mgr:policy:apply $API_INSTANCE_ID $POLICY_NAME \
    --policyVersion $POLICY_VERSION \
    --groupId $ANYPOINT_POLICIES_ORGANIZATION_ID \
    --config $POLICY_CONFIG




# (re)deploy the API to Flex Gateway
if [ "$API_INSTANCE_STATUS" = "active" ]; then
    echo "API Instance is deployed already. Ensuring latest spec is applied: $ASSET_VERSION"
    anypoint-cli-v4 api-mgr:api:change-specification --output json $API_INSTANCE_ID $ASSET_VERSION
else
    # get access token
    echo "grabbing a Platform API access token"

    ACCESS_TOKEN=$(curl -s --location --globoff "https://${ANYPOINT_HOST}/accounts/login" \
    --header 'Content-Type: application/json' \
    --data "{
        \"username\": \"${ANYPOINT_USERNAME}\",
        \"password\": \"${ANYPOINT_PASSWORD}\"
    }" | jq -r '.access_token')

    echo "Fetched access token"

    # get flex gateway id by its name
    GATEWAYS=$(curl -s "https://${ANYPOINT_HOST}/apimanager/xapi/v1/organizations/${ANYPOINT_ORGANIZATION_ID}/environments/${ANYPOINT_ENVIRONMENT_ID}/flex-gateway-targets" \
        --header "Authorization: Bearer ${ACCESS_TOKEN}")

    FLEX_GATEWAY_ID=$(echo ${GATEWAYS} | jq -c ".[] | select(.name | contains(\"${FLEX_GATEWAY_NAME}\"))" | jq -r '.id')
    echo "Gateway ID is $FLEX_GATEWAY_ID"

    echo "Deploying the API Instance to Flex Gateway..."
    anypoint-cli-v4 api-mgr:api:deploy $API_INSTANCE_ID \
    --target $FLEX_GATEWAY_ID \
    --gatewayVersion $FLEX_GATEWAY_VERSION
fi
