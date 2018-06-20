#!/bin/bash
#
# This script creates people within an LPG, populates faces, and trains that group.
# 
# The script assumes that there is a directory full of images, and each image is 
# uniquely named with an identifier for that person (for instance, Employee ID)
# 
# Further mapping / metadata can be inserted in the future to make resolution simpler
# 
# This script will iterate over every image, create a person in a LargePersonGroup
# with the name of that file (stripped of extension), and then upload the image
# to that person.
#
# At the end, it'll also 

### TODO
# 1) Add in arg support (e.g. -a to do all, -c to just create people, 
#    -i to attach images(?), -t to train)
# 2) Add in opt support (e.g. path to images, subscription)
# 3) Add debug support (currently commented out)
#

## Vars
# Define your API Key
apiKey="0e1ba9b68a33439d8e219c0c0e83de56"

# Define your region 
# If unspecified, defaults to southeastasia
regionOverride=""

# Define your Large Person Group Name. 
# If unspecified, defaults to 'employees'
lpgNameOverride=""

# Add a custom name for the logfile
# If unspecified, defaults to 'populate-[epoch seconds date].log'
logFileOverride=""

# Enable debugging (set to 'true' if desired)
debugPrintOverride=""

# Configure custom path for image source
# If unspecified, defaults to files/
filePathOverride=""



## Defaults
region=${regionOverride:=southeastasia}
lpgName=${lpgNameOverride:=employees}
debugPrint=${debugPrintOverride:=false}
logFile=${logFileOverride:=populate-$(date +%s).log}
filePath=${filePathOverride:=files}



# Functions

# Create a person
# pass personName
createPerson () {
    personName=${1}
    requestBody="{
        \"name\": \"${personName}\",
        \"userData\": \"Created by lpg-populate.sh at $(date)\"
    }"

    requestOutput=$(echo ${requestBody} | curl -s \
        -H "Ocp-Apim-Subscription-Key: ${apiKey}" \
        -H "Content-Type: application/json" \
        -d "${requestBody}" \
        https://${region}.api.cognitive.microsoft.com/face/v1.0/largepersongroups/${lpgName}/persons
    )
    personId=$(echo ${requestOutput} | grep personId | awk -F\" '{ print $4}' )

    ##TODO
    # Insert the personId into a list?
    # Hacky attempt first
    echo "$(date +%s),${personName},${personId}" >> ${logFile}
    if [[ ${debugPrint} == 'true' ]]; then
        if [[ ${requestOutput} == '' ]]; then
            echo "Creation of ${personName} failed"
        elif [[ ${requestOutput} =~ [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} ]]; then
            echo "Creation succeeded"
        else
            echo "Creation failed, unhandled reason"
        fi 
    fi

    echo ${personId}

}

# Associate the face image with the person
# Max file size is 4MB -- we should check for that
#
# Pass personId, faceFile (path)

addFacetoPerson () {
    ## personId="c46b0dff-afc1-4c80-94fb-380ef769185e"
    ## faceFile="AlexSmith-2017.jpg"
    personId=${1}
    faceFile=${2}
    
    requestOutput=$(curl -v \
        -H "Ocp-Apim-Subscription-Key: ${apiKey}" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @${faceFile} \
        https://${region}.api.cognitive.microsoft.com/face/v1.0/largepersongroups/${lpgName}/persons/${personId}/persistedfaces

    )
    requestOutput=$(echo ${requestOutput})
    if [[ ${debugPrint} == 'true' ]]; then
        if [[ ${requestOutput} == '' ]]; then
            echo "Face Attach of ${personName} failed"
        elif [[ ${requestOutput} =~ [0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12} ]]; then
            echo "Face attachment succeeded"
        else
            echo "Creation failed, unhandled reason"
        fi  
    fi
}

# Train the group
# No args required
# only called at the end
trainGroup() {
    requestOutput=$(curl -s \
        -H "Ocp-Apim-Subscription-Key: ${apiKey}" \
        -d - \
        -w "%{http_code}" \
        https://${region}.api.cognitive.microsoft.com/face/v1.0/largepersongroups/${lpgName}/train

    )

    if [[ ${debugPrint} == 'true' ]]; then
        if [[ ${requestOutput} == '202' ]]; then
            echo "Training request accepted"
        else
            echo "Creation failed, unhandled reason"
        fi
    fi  
}

fileList=$(find ${filePath} -type f)

for image in ${fileList}; do
    derivedName=$(basename $(echo ${image}) | awk -F. '{print $1}')
    personId=$(createPerson ${derivedName})
    addFacetoPerson ${personId} ${image}
done

# Once complete, train the group
trainGroup

echo "complete"
