#!/usr/bin/env bash
set -euo pipefail

REGION="${REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-m8i.2xlarge}"
ROOT_VOLUME_SIZE_GB="${ROOT_VOLUME_SIZE_GB:-200}"
ROLE_NAME="${ROLE_NAME:-cake-wallet-gh-runner-ssm}"
PROFILE_NAME="${PROFILE_NAME:-cake-wallet-gh-runner-ssm}"
PRIVATE_SUBNET_TAG_NAME="${PRIVATE_SUBNET_TAG_NAME:-cake-wallet-gh-runner-private-us-east-1d}"
RUNNER_AMI_PARAMETER_NAME="${RUNNER_AMI_PARAMETER_NAME:-/cake-wallet/github-runners/android/ami-id}"
FALLBACK_AMI_PARAMETER_NAME="${FALLBACK_AMI_PARAMETER_NAME:-/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id}"
JOB_CONTAINER_IMAGE="${JOB_CONTAINER_IMAGE:-ghcr.io/cake-tech/cake_wallet:debian13-flutter3.32.0-ndkr28-go1.24.1-ruststablenightly}"
RUNNER_CACHE_DIR="${RUNNER_CACHE_DIR:-/opt/actions-runner-cache}"
IMAGE_NAME_PREFIX="${IMAGE_NAME_PREFIX:-cake-wallet-gh-runner-android}"
BOOTSTRAP_IAM="${BOOTSTRAP_IAM:-true}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

need aws

aws sts get-caller-identity >/dev/null

TRUST_FILE="$(mktemp)"
USER_DATA_FILE="$(mktemp)"

cleanup() {
  rm -f "$TRUST_FILE" "$USER_DATA_FILE"
}
trap cleanup EXIT

cat >"$TRUST_FILE" <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
JSON

if [[ "$BOOTSTRAP_IAM" == "true" ]]; then
  if ! aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    aws iam create-role \
      --role-name "$ROLE_NAME" \
      --assume-role-policy-document "file://${TRUST_FILE}" \
      >/dev/null
  fi

  aws iam attach-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore \
    >/dev/null

  if ! aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null 2>&1; then
    aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null
  fi

  if ! aws iam get-instance-profile \
    --instance-profile-name "$PROFILE_NAME" \
    --query 'InstanceProfile.Roles[].RoleName' \
    --output text | tr '\t' '\n' | grep -qx "$ROLE_NAME"; then
    aws iam add-role-to-instance-profile \
      --instance-profile-name "$PROFILE_NAME" \
      --role-name "$ROLE_NAME" \
      >/dev/null || true
  fi

  aws iam wait instance-profile-exists --instance-profile-name "$PROFILE_NAME"
fi

BASE_AMI_ID="$(
  aws ssm get-parameter \
    --region "$REGION" \
    --name "$FALLBACK_AMI_PARAMETER_NAME" \
    --query 'Parameter.Value' \
    --output text
)"

SUBNET_ID="${SUBNET_ID:-$(
  PRIVATE_SUBNET_ID="$(
    aws ec2 describe-subnets \
      --region "$REGION" \
      --filters Name=tag:Name,Values="$PRIVATE_SUBNET_TAG_NAME" \
      --query 'Subnets[0].SubnetId' \
      --output text 2>/dev/null || true
  )"
  if [[ -n "$PRIVATE_SUBNET_ID" && "$PRIVATE_SUBNET_ID" != "None" ]]; then
    printf '%s\n' "$PRIVATE_SUBNET_ID"
  else
    aws ec2 describe-subnets \
      --region "$REGION" \
      --filters Name=default-for-az,Values=true \
      --query 'Subnets[0].SubnetId' \
      --output text
  fi
)}"

VPC_ID="$(
  aws ec2 describe-subnets \
    --region "$REGION" \
    --subnet-ids "$SUBNET_ID" \
    --query 'Subnets[0].VpcId' \
    --output text
)"

SECURITY_GROUP_ID="${SECURITY_GROUP_ID:-$(
  aws ec2 describe-security-groups \
    --region "$REGION" \
    --filters Name=vpc-id,Values="$VPC_ID" Name=group-name,Values=default \
    --query 'SecurityGroups[0].GroupId' \
    --output text
)}"

TIMESTAMP="$(date -u +%Y%m%d-%H%M%S)"
INSTANCE_NAME="${IMAGE_NAME_PREFIX}-bake-${TIMESTAMP}"
AMI_NAME="${IMAGE_NAME_PREFIX}-${TIMESTAMP}"

cat >"$USER_DATA_FILE" <<'EOF'
#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/cake-wallet-runner-bake.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

retry() {
  local attempts="$1"
  shift

  local attempt=1
  until "$@"; do
    if (( attempt >= attempts )); then
      return 1
    fi
    sleep $(( attempt * 5 ))
    attempt=$(( attempt + 1 ))
  done
}

retry 5 apt-get update
retry 5 apt-get install -y docker.io qemu-system-x86 jq curl unzip ca-certificates git

systemctl enable --now docker
usermod -aG docker,kvm ubuntu || true

install -d -o ubuntu -g ubuntu \
  /opt/cw_cache_android/root/.cache \
  /opt/cw_cache_android/root/.android/avd \
  /opt/cw_cache_android/root/.ccache \
  /opt/cw_cache_android/root/.pub-cache \
  /opt/cw_cache_android/root/.gradle \
  /opt/cw_cache_android/root/.android \
  /opt/cw_cache_android/root/go/pkg \
  /opt/cw_cache_android/opt/generic_cache \
  __RUNNER_CACHE_DIR__

runner_version="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')"
runner_tarball="__RUNNER_CACHE_DIR__/actions-runner-linux-x64-${runner_version}.tar.gz"
if [[ ! -f "$runner_tarball" ]]; then
  curl -fsSL -o "$runner_tarball" -L "https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-x64-${runner_version}.tar.gz"
  chown ubuntu:ubuntu "$runner_tarball"
fi

docker pull "__JOB_CONTAINER_IMAGE__"

install -d /var/lib/cake-wallet
cat >/var/lib/cake-wallet/runner-image.json <<JSON
{
  "job_container_image": "__JOB_CONTAINER_IMAGE__",
  "runner_tarball": "$runner_tarball",
  "baked_at_utc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
JSON

touch /var/lib/cake-wallet/android-runner-ami-ready
EOF

python3 - <<'PY' "$USER_DATA_FILE" "$RUNNER_CACHE_DIR" "$JOB_CONTAINER_IMAGE"
from pathlib import Path
import sys

path = Path(sys.argv[1])
replacements = {
    "__RUNNER_CACHE_DIR__": sys.argv[2],
    "__JOB_CONTAINER_IMAGE__": sys.argv[3],
}

text = path.read_text()
for key, value in replacements.items():
    text = text.replace(key, value)
path.write_text(text)
PY

INSTANCE_ID="$(
  aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$BASE_AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --cpu-options NestedVirtualization=enabled \
    --iam-instance-profile Name="$PROFILE_NAME" \
    --subnet-id "$SUBNET_ID" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --metadata-options HttpTokens=required,HttpEndpoint=enabled,HttpPutResponseHopLimit=1 \
    --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${ROOT_VOLUME_SIZE_GB},\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true}}]" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${INSTANCE_NAME}},{Key=Project,Value=cake-wallet},{Key=Role,Value=github-runner-baker}]" "ResourceType=volume,Tags=[{Key=Name,Value=${INSTANCE_NAME}-root}]" \
    --user-data "file://${USER_DATA_FILE}" \
    --query 'Instances[0].InstanceId' \
    --output text
)"

echo "Launched bake instance: ${INSTANCE_ID}" >&2

aws ec2 wait instance-running --region "$REGION" --instance-ids "$INSTANCE_ID"

wait_for_ssm() {
  local attempts=0
  while (( attempts < 120 )); do
    local ping_status
    ping_status="$(
      aws ssm describe-instance-information \
        --region "$REGION" \
        --filters Key=InstanceIds,Values="$INSTANCE_ID" \
        --query 'InstanceInformationList[0].PingStatus' \
        --output text 2>/dev/null || true
    )"
    if [[ "$ping_status" == "Online" ]]; then
      return 0
    fi
    attempts=$((attempts + 1))
    sleep 10
  done

  echo "instance ${INSTANCE_ID} did not register with SSM in time" >&2
  return 1
}

wait_for_bake_ready() {
  local attempts=0
  while (( attempts < 180 )); do
    local command_id
    command_id="$(
      aws ssm send-command \
        --region "$REGION" \
        --instance-ids "$INSTANCE_ID" \
        --document-name AWS-RunShellScript \
        --comment "check cake-wallet runner bake readiness" \
        --parameters 'commands=["test -f /var/lib/cake-wallet/android-runner-ami-ready && cat /var/lib/cake-wallet/runner-image.json"]' \
        --query 'Command.CommandId' \
        --output text
    )"

    local status="Pending"
    while [[ "$status" == "Pending" || "$status" == "InProgress" || "$status" == "Delayed" ]]; do
      sleep 5
      status="$(
        aws ssm get-command-invocation \
          --region "$REGION" \
          --command-id "$command_id" \
          --instance-id "$INSTANCE_ID" \
          --query 'Status' \
          --output text 2>/dev/null || true
      )"
    done

    if [[ "$status" == "Success" ]]; then
      aws ssm get-command-invocation \
        --region "$REGION" \
        --command-id "$command_id" \
        --instance-id "$INSTANCE_ID" \
        --query 'StandardOutputContent' \
        --output text >&2
      return 0
    fi

    attempts=$((attempts + 1))
    sleep 10
  done

  echo "bake readiness marker was not created on ${INSTANCE_ID}" >&2
  aws ssm send-command \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --document-name AWS-RunShellScript \
    --comment "dump bake logs" \
    --parameters 'commands=["tail -n 200 /var/log/cake-wallet-runner-bake.log || true","tail -n 200 /var/log/cloud-init-output.log || true"]' \
    --query 'Command.CommandId' \
    --output text >&2 || true
  return 1
}

wait_for_image_available() {
  local attempts=0
  while (( attempts < 120 )); do
    local image_state
    image_state="$(
      aws ec2 describe-images \
        --region "$REGION" \
        --image-ids "$AMI_ID" \
        --query 'Images[0].State' \
        --output text
    )"

    if [[ "$image_state" == "available" ]]; then
      return 0
    fi

    attempts=$((attempts + 1))
    sleep 15
  done

  echo "image ${AMI_ID} did not become available in time" >&2
  return 1
}

wait_for_ssm
wait_for_bake_ready

aws ec2 stop-instances --region "$REGION" --instance-ids "$INSTANCE_ID" >/dev/null
aws ec2 wait instance-stopped --region "$REGION" --instance-ids "$INSTANCE_ID"

AMI_ID="$(
  aws ec2 create-image \
    --region "$REGION" \
    --instance-id "$INSTANCE_ID" \
    --name "$AMI_NAME" \
    --description "Cake Wallet ephemeral Android runner image baked ${TIMESTAMP}" \
    --tag-specifications "ResourceType=image,Tags=[{Key=Name,Value=${AMI_NAME}},{Key=Project,Value=cake-wallet},{Key=Role,Value=github-runner},{Key=ImageType,Value=android-runner}]" "ResourceType=snapshot,Tags=[{Key=Project,Value=cake-wallet},{Key=Role,Value=github-runner}]" \
    --query 'ImageId' \
    --output text
)"

echo "Created image: ${AMI_ID}" >&2

wait_for_image_available

aws ssm put-parameter \
  --region "$REGION" \
  --name "$RUNNER_AMI_PARAMETER_NAME" \
  --type String \
  --overwrite \
  --value "$AMI_ID" \
  >/dev/null

aws ec2 terminate-instances --region "$REGION" --instance-ids "$INSTANCE_ID" >/dev/null

printf '{"ImageId":"%s","ImageName":"%s","InstanceId":"%s","ParameterName":"%s","Region":"%s"}\n' \
  "$AMI_ID" \
  "$AMI_NAME" \
  "$INSTANCE_ID" \
  "$RUNNER_AMI_PARAMETER_NAME" \
  "$REGION"
