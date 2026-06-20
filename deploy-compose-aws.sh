#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   chmod +x deploy-compose-aws.sh
#   ./deploy-compose-aws.sh
#
# Optional overrides:
#   AWS_REGION=us-east-1 ECR_REGISTRY=405834051687.dkr.ecr.us-east-1.amazonaws.com ./deploy-compose-aws.sh

AWS_REGION="${AWS_REGION:-us-east-1}"
ECR_REGISTRY="${ECR_REGISTRY:-405834051687.dkr.ecr.us-east-1.amazonaws.com}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.aws.yml}"
ENV_FILE="${ENV_FILE:-.env}"

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
else
  echo "ERROR: Neither 'docker compose' nor 'docker-compose' is available."
  exit 1
fi

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "ERROR: ${COMPOSE_FILE} not found in current directory."
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  cat > "${ENV_FILE}" <<'EOF'
POSTGRES_PASSWORD=123456789
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin
CONFIGSERVERLOCAL_TAG=latest
DASHBOARDEUREKASERVER_TAG=latest
ACCOUNTSERVICE_TAG=latest
LEDGERSERVICE_TAG=latest
FRAUDSERVICE_TAG=latest
NOTIFICATIONSERVICE_TAG=latest
APIGATEWAYSERVICE_TAG=latest
EOF
  echo "Created ${ENV_FILE}. Update tags/passwords if needed."
fi

echo "Logging into ECR: ${ECR_REGISTRY}"
aws ecr get-login-password --region "${AWS_REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo "Pulling images..."
${COMPOSE_CMD} -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" pull

echo "Starting services..."
${COMPOSE_CMD} -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" up -d --remove-orphans

echo "Done. Current status:"
${COMPOSE_CMD} -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" ps
