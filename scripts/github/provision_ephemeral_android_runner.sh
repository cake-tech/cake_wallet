#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-adrienlacombe/cake_wallet}"
REGION="${REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-m8i.2xlarge}"
ROOT_VOLUME_SIZE_GB="${ROOT_VOLUME_SIZE_GB:-200}"
RUNNER_LABELS="${RUNNER_LABELS:-amd64,android}"
ROLE_NAME="${ROLE_NAME:-cake-wallet-gh-runner-ssm}"
PROFILE_NAME="${PROFILE_NAME:-cake-wallet-gh-runner-ssm}"
RUNNER_GROUP="${RUNNER_GROUP:-Default}"
PRIVATE_SUBNET_TAG_NAME="${PRIVATE_SUBNET_TAG_NAME:-cake-wallet-gh-runner-private-us-east-1d}"
RUNNER_AMI_PARAMETER_NAME="${RUNNER_AMI_PARAMETER_NAME:-/cake-wallet/github-runners/android/ami-id}"
FALLBACK_AMI_PARAMETER_NAME="${FALLBACK_AMI_PARAMETER_NAME:-/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id}"
JOB_CONTAINER_IMAGE="${JOB_CONTAINER_IMAGE:-ghcr.io/cake-tech/cake_wallet:debian13-flutter3.32.0-ndkr28-go1.24.1-ruststablenightly}"
RUNNER_CACHE_DIR="${RUNNER_CACHE_DIR:-/opt/actions-runner-cache}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

need aws
need gh
need python3

aws sts get-caller-identity >/dev/null

GH_AUTH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
if [[ -n "$GH_AUTH_TOKEN" ]]; then
  export GH_TOKEN="$GH_AUTH_TOKEN"
else
  gh auth status >/dev/null
fi

BOOTSTRAP_IAM="${BOOTSTRAP_IAM:-true}"

TRUST_FILE="$(mktemp)"
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

cleanup() {
  rm -f "$TRUST_FILE" "${USER_DATA_FILE:-}" "${PARAMS_FILE:-}"
}
trap cleanup EXIT

resolve_ami_id() {
  if [[ -n "${AMI_ID:-}" ]]; then
    printf '%s\n' "$AMI_ID"
    return 0
  fi

  local custom_ami_id=""
  set +e
  custom_ami_id="$(
    aws ssm get-parameter \
      --region "$REGION" \
      --name "$RUNNER_AMI_PARAMETER_NAME" \
      --query 'Parameter.Value' \
      --output text 2>/dev/null
  )"
  local status=$?
  set -e

  if [[ $status -eq 0 && -n "$custom_ami_id" && "$custom_ami_id" != "None" ]]; then
    printf '%s\n' "$custom_ami_id"
    return 0
  fi

  aws ssm get-parameter \
    --region "$REGION" \
    --name "$FALLBACK_AMI_PARAMETER_NAME" \
    --query 'Parameter.Value' \
    --output text
}

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

AMI_ID="$(resolve_ami_id)"

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

if [[ -n "${EPHEMERAL_RUNNER_NAME:-}" ]]; then
  RUNNER_NAME="$EPHEMERAL_RUNNER_NAME"
elif [[ -n "${RUNNER_NAME:-}" && -z "${GITHUB_ACTIONS:-}" ]]; then
  RUNNER_NAME="$RUNNER_NAME"
else
  RUNNER_NAME="cake-android-$(date -u +%Y%m%d-%H%M%S)"
fi
RUNNER_TOKEN="$(
  gh api -X POST "repos/${REPO}/actions/runners/registration-token" --jq .token
)"

USER_DATA_FILE="$(mktemp)"
cat >"$USER_DATA_FILE" <<'EOF'
#!/bin/bash
set -euxo pipefail
exec > >(tee -a /var/log/cake-wallet-runner-bootstrap.log) 2>&1

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

ensure_packages() {
  local missing=()

  command -v docker >/dev/null 2>&1 || missing+=(docker.io)
  command -v jq >/dev/null 2>&1 || missing+=(jq)
  command -v curl >/dev/null 2>&1 || missing+=(curl)
  command -v unzip >/dev/null 2>&1 || missing+=(unzip)
  command -v git >/dev/null 2>&1 || missing+=(git)
  [[ -e /dev/kvm ]] || missing+=(qemu-system-x86)

  if (( ${#missing[@]} > 0 )); then
    retry 5 apt-get update
    retry 5 apt-get install -y "${missing[@]}"
  fi
}

ensure_packages

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
  __RUNNER_CACHE_DIR__ \
  /home/ubuntu/actions-runner

runner_tarball="$(ls -1 __RUNNER_CACHE_DIR__/actions-runner-linux-x64-*.tar.gz 2>/dev/null | sort | tail -n1 || true)"
if [[ -z "$runner_tarball" ]]; then
  runner_version="$(curl -fsSL https://api.github.com/repos/actions/runner/releases/latest | jq -r .tag_name | sed 's/^v//')"
  runner_tarball="__RUNNER_CACHE_DIR__/actions-runner-linux-x64-${runner_version}.tar.gz"
  curl -fsSL -o "$runner_tarball" -L "https://github.com/actions/runner/releases/download/v${runner_version}/actions-runner-linux-x64-${runner_version}.tar.gz"
  chown ubuntu:ubuntu "$runner_tarball"
fi

rm -rf /home/ubuntu/actions-runner/*
tar -xzf "$runner_tarball" -C /home/ubuntu/actions-runner
chown -R ubuntu:ubuntu /home/ubuntu/actions-runner

if [[ -f /var/lib/cake-wallet/android-runner-ami-ready ]]; then
  echo "Skipping runner dependency install on baked AMI"
else
  retry 5 bash -lc 'cd /home/ubuntu/actions-runner && ./bin/installdependencies.sh'
fi

if ! docker image inspect "__JOB_CONTAINER_IMAGE__" >/dev/null 2>&1; then
  docker pull "__JOB_CONTAINER_IMAGE__" || true
fi

bash -lc 'cd /home/ubuntu/actions-runner && chown -R ubuntu:ubuntu /home/ubuntu/actions-runner && sudo -u ubuntu ./config.sh --url https://github.com/__REPO__ --token __RUNNER_TOKEN__ --name __RUNNER_NAME__ --labels __RUNNER_LABELS__ --runnergroup __RUNNER_GROUP__ --unattended --replace --ephemeral'

cat >/etc/systemd/system/cake-wallet-gh-runner.service <<'UNIT'
[Unit]
Description=GitHub Actions Runner (__REPO__)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/actions-runner
ExecStart=/home/ubuntu/actions-runner/run.sh
Restart=no
TimeoutStopSec=300
ExecStopPost=/usr/bin/sudo -n shutdown -h now

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now cake-wallet-gh-runner.service
EOF

python3 - <<'PY' "$USER_DATA_FILE" "$REPO" "$RUNNER_TOKEN" "$RUNNER_NAME" "$RUNNER_LABELS" "$RUNNER_GROUP" "$RUNNER_CACHE_DIR" "$JOB_CONTAINER_IMAGE"
from pathlib import Path
import sys

path = Path(sys.argv[1])
replacements = {
    "__REPO__": sys.argv[2],
    "__RUNNER_TOKEN__": sys.argv[3],
    "__RUNNER_NAME__": sys.argv[4],
    "__RUNNER_LABELS__": sys.argv[5],
    "__RUNNER_GROUP__": sys.argv[6],
    "__RUNNER_CACHE_DIR__": sys.argv[7],
    "__JOB_CONTAINER_IMAGE__": sys.argv[8],
}

text = path.read_text()
for key, value in replacements.items():
    text = text.replace(key, value)
path.write_text(text)
PY

aws ec2 run-instances \
  --region "$REGION" \
  --image-id "$AMI_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --cpu-options NestedVirtualization=enabled \
  --instance-initiated-shutdown-behavior terminate \
  --iam-instance-profile Name="$PROFILE_NAME" \
  --subnet-id "$SUBNET_ID" \
  --security-group-ids "$SECURITY_GROUP_ID" \
  --metadata-options HttpTokens=required,HttpEndpoint=enabled,HttpPutResponseHopLimit=1 \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":${ROOT_VOLUME_SIZE_GB},\"VolumeType\":\"gp3\",\"DeleteOnTermination\":true}}]" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${RUNNER_NAME}},{Key=Project,Value=cake-wallet},{Key=Role,Value=github-runner},{Key=RunnerType,Value=ephemeral}]" "ResourceType=volume,Tags=[{Key=Name,Value=${RUNNER_NAME}-root}]" \
  --user-data "file://${USER_DATA_FILE}" \
  --query 'Instances[0].{InstanceId:InstanceId,State:State.Name,Region:`'"$REGION"'`,RunnerName:`'"$RUNNER_NAME"'`,SubnetId:SubnetId,PrivateIp:PrivateIpAddress}'
