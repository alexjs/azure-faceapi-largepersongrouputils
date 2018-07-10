#!/bin/bash

## Vars
# Define your API Key
apiKey=""

# Define your region (defaults to southeastasia)
regionOverride=""

# Define your LPG Name
lpgNameOverride=""
# Define your WorkSpace Key (this is used by certain apps to filter, and is placed into the metadata)
workspaceKey=""

## Defaults
region=${regionOverride:=southeastasia}
lpgName=${lpgNameOverride:=employees}


# Execute

requestBody="{
    \"name\": \"${lpgName}\",
    \"userData\": \"${workspaceKey}\"
}"

requestOutput=$(echo ${requestBody} | curl -s \
    -H "Ocp-Apim-Subscription-Key: ${apiKey}" \
    -H "Content-Type: application/json" \
    -T - \
    https://${region}.api.cognitive.microsoft.com/face/v1.0/largepersongroups/${lpgName}
)
if [[ ${requestOutput} == '' ]]; then
    echo "Group ${lpgName} created"
elif [[ ${requestOutput} =~ .*LargePersonGroupExists.* ]]; then
    echo "Creation failed, group already exists (name: \"${lpgName}\")"
else
    echo "Creation failed, unhandled reason"
fi
