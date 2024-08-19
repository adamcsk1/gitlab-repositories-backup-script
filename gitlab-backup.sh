#!/bin/bash

# Gitlab SSH key setup is prerequirement.

declare -r PRIVATE_TOKEN="" # Gitlab personal access token (read scopes are enough)
declare -r BACKUP_BASE_FOLDER="" # Backup target folder
declare -r BACKUP_FOLDER="$BACKUP_BASE_FOLDER/live/"
declare -r ARCHIVED_FOLDER="$BACKUP_BASE_FOLDER/archived/"
declare -r END_RESPONSE="{\"error\":\"page is invalid\"}"

page=1
projects=""

echo "[Backup started]"

rm -rf $ARCHIVED_FOLDER
mv $BACKUP_FOLDER $ARCHIVED_FOLDER
mkdir $BACKUP_FOLDER

cd $BACKUP_FOLDER

while [ "$projects" != "$END_RESPONSE" ]; do 

    projects=$(curl --header "PRIVATE-TOKEN: $PRIVATE_TOKEN" --insecure "https://gitlab.com/api/v4/projects/?simple=yes&owned=true&per_page=100&page=$page")
    page=page+1

    if [ "$projects" != "$END_RESPONSE" ]; then
        for row in $(echo $projects | jq -r '.[] | @base64'); do
            _jq() {
                echo "${row}" | base64 -di | jq -r "${1}"
            }

            name_with_namespace=$( _jq '.name_with_namespace')
            folder_name=$(echo $name_with_namespace | sed 's/ \/ /-/g')
            folder_name_cleared=$(echo $folder_name | sed 's/ //g')
            ssh_url_to_repo=$(_jq '.ssh_url_to_repo')

           echo "folder_name=$folder_name_cleared ; ssh_url_to_repo=$ssh_url_to_repo"

           rm -rf $folder_name_cleared
           git clone $ssh_url_to_repo $folder_name_cleared
        done
    fi
done

echo "[Backup finished]"
