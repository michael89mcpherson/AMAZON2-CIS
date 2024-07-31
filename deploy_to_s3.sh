#!/usr/bin/env bash

# Deploy this role and playbooks to the deployment asset bucket
function debug() {
    local message="$1"
    if [ "$DEBUG" = true ]; then
        printf '[DEBUG] %s\n' "$message"
    fi
}

function error() {
    local message="$1"
    printf '[ERROR] %s\n' "$message"
}

function info() {
    local message="$1"
    printf '[INFO] %s\n' "$message"
}

function warning() {
    local message="$1"
    printf '[WARNING] %s\n' "$message"
}

usage() { echo "Usage: $0 -v <version> -p <profile_name>" 1>&2; exit 1; }

while getopts "p:v:" options; do
    case "${options}" in
        p)
            AWS_PROFILE=${OPTARG}
            ;;
        v)
            VERSION=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

if [ -z "$AWS_PROFILE" ] || [ -z "$VERSION" ]; then
    usage
    exit 1
fi

if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Version must be symantically versioned (ie 1.0.0)"
    exit 1
fi

BUCKET_NAME="deployment-imagebuilder-assets-us-gov-east-1-240970342469"
TARBALL_NAME="cis-v${VERSION}.tgz"

info "Checking for existance of ${TARBALL_NAME} in S3."
file_check=$(aws s3 ls s3://${BUCKET_NAME}/ansible/${TARBALL_NAME} --profile "${AWS_PROFILE}")
if [ -n "$file_check" ]; then
    error "${TARBALL_NAME} already exists in ${BUCKET_NAME}/ansible. Check the file version and try again."
    exit 1
fi

info "Archiving directory contents"
tar --exclude="deploy_to_s3.sh" --exclude="playbooks/" --exclude=".vscode" --exclude=".git" -czvf "/var/tmp/${TARBALL_NAME}" . > /dev/null 2>&1

info "Uploading archive to S3"
aws s3 mv /var/tmp/${TARBALL_NAME} s3://${BUCKET_NAME}/ansible/ --profile "$AWS_PROFILE"
