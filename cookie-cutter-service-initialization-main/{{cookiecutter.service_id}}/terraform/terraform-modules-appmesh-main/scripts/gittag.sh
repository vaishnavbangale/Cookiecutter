#!/bin/bash
set -e

if [ -z "${REPOSITORY_NAME}" ]
then
    echo "REPOSITORY_NAME environment variable not defined"
    exit 1
fi

current_commit=${CODEBUILD_RESOLVED_SOURCE_VERSION}
branch=${CODEBUILD_WEBHOOK_TRIGGER}
primary_branch="branch/main"
echo "branch $branch"

# files
version_json="version.json"
commit_response_json="commit_response.json"
tag_response_json="list_tag_response.json"
applytag_response_json="applytag_response.json"
reftag_response_json="reftag_response.json"
diff_response_json="diff_response.json"

# Github api variables
git_repo="HappyMoneyInc/${REPOSITORY_NAME}"
tag_url="https://api.github.com/repos/$git_repo/git/tags"
repo_tag_url="https://api.github.com/repos/$git_repo/tags"
commit_url="https://api.github.com/repos/$git_repo/git/commits/$current_commit"
tag_ref_url="https://api.github.com/repos/$git_repo/git/refs"

# load git token
git_token=$(aws ssm get-parameters --names "/devops/github/oauth" --with-decryption --region us-east-1 --query "Parameters[].Value" --output text)

# Get repo version
version=$(cat $version_json | jq -r .version)
# Test version pattern
if ! [[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "ERROR: Version in $version_json does not match regex ^v[0-9]+\.[0-9]+\.[0-9]+$"
  exit 1
fi

# Get list of tags
curl -sS -H "Authorization: token $git_token" "$repo_tag_url" -o $tag_response_json

# Sort list of latest tags that are in format
tag_names=( $(cat $tag_response_json | 
                jq -r '.[].name
                | select(. | test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))') )
sorted_tag_names=( $( echo $tag_names | tr " " "\n" | sort -rV ) )
latest_version=${sorted_tag_names[0]}
newer_version=$(printf "$version\n$latest_version" | sort -rV | head -n1)

echo "branch_version:$version ; latest_version:$latest_version ; newer_version:$newer_version"

# Create the tag from version.json if running from main branch
if [[ "$branch" == "$primary_branch" ]]
then
    if [[ "$version" == "$latest_version" ]]
    then
        echo "WARN: Branch is $branch. Tag is already applied."
    elif [[ "$version" != "$newer_version" ]]
    then
        echo "ERROR: Version specified in $version_json is an older version compared to latest. Fix the tags on repository."
        exit 1
    else
        # Apply new tag and reference
        echo "Getting commit message"
        curl -sS -H "Authorization: token $git_token" "$commit_url" -o $commit_response_json
        commit_msg=$(cat $commit_response_json | jq -r .message)
        
        echo "Creating new tag $version"
        curl -sS -X POST -H "Authorization: token $git_token" "$tag_url" \
            -d "{\"tag\": \"$version\", \"message\": \"$commit_msg\", \"object\": \"$current_commit\", \"type\": \"commit\"}" -o $applytag_response_json
        
        echo "Creating reference to tag $version"
        curl -sS -X POST -H "Authorization: token $git_token" "$tag_ref_url" \
            -d "{\"ref\": \"refs/tags/$version\", \"sha\": \"$current_commit\"}" -o $reftag_response_json
        cat $reftag_response_json
    fi
else
    echo "Branch is $branch. Testing tag."
    if [[ "$version" == "$latest_version" ]]
    then
        # Fail if any file changed that match version control source pattern
        source_pattern=$(cat $version_json | jq -r '.source_pattern|@json')
        ./scripts/get_commit_diff.sh "main...${CODEBUILD_RESOLVED_SOURCE_VERSION}" $diff_response_json
        source_pattern_regex=$(sed -e 's/^"//' -e 's/"$//' <<<$source_pattern)
        file_paths=( $(cat $diff_response_json | 
                        jq -r ".files[].filename | select(. | test(\"$source_pattern_regex\"))") )
        if ! [ ${#file_paths[@]} -eq 0 ]
        then
            echo "Error: Version specified in $version_json is already applied. Please update the version and commit again"
            exit 1
        else
            echo "WARN: Version specified in $version_json is already applied."
        fi
    elif [[ "$version" != "$newer_version" ]]
    then
        echo "ERROR: Version specified in $version_json is an older version compared to latest, $latest_version. Please update the version and commit again"
        exit 1
    else
        echo "$version will be tagged when pushed to $primary_branch"
    fi
fi