#!/usr/bin/env bash

# Default namespaces
DEFAULT_NAMESPACES="04d1a3-prod d106d6-prod d7abee-prod eeced3-prod c84b95-prod"

# Prompt user with default
read -rp "Enter OpenShift namespaces (space-separated) [default: $DEFAULT_NAMESPACES]: " NAMESPACES

# Use default if empty
if [ -z "$NAMESPACES" ]; then
  NAMESPACES="$DEFAULT_NAMESPACES"
fi

# Colors
RED="\033[31m"
RESET="\033[0m"

# Loop through each namespace
for NAMESPACE in $NAMESPACES; do

  echo -e "\n=============================================="
  echo "Namespace: $NAMESPACE"
  echo "=============================================="

  # Check namespace exists
  if ! oc get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "Namespace '$NAMESPACE' does not exist or you don't have access"
    continue
  fi

  # Print table header
  printf "%-30s %-40s %-25s\n" "ROUTE" "HOST" "CERT EXPIRY"
  printf "%-30s %-40s %-25s\n" "-----" "----" "-----------"

  oc get route -n "$NAMESPACE" -o json | jq -r '
  .items[] |
  {
    name: .metadata.name,
    host: .spec.host,
    cert: .spec.tls.certificate
  } |
  @base64' | while read -r row; do

    _jq() {
      echo "$row" | base64 --decode | jq -r "$1"
    }

    NAME=$(_jq '.name')
    HOST=$(_jq '.host')
    CERT=$(_jq '.cert')

    # Truncate HOST if too long
    MAX_HOST_LEN=40
    if [ ${#HOST} -gt $MAX_HOST_LEN ]; then
      HOST="${HOST:0:37}..."
    fi

    # Determine expiry
    if [ "$CERT" = "null" ] || [ -z "$CERT" ]; then
      EXPIRY="N/A"
      COLOR=$RESET
    else
      EXPIRY=$(echo "$CERT" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
      [ -z "$EXPIRY" ] && EXPIRY="INVALID CERT"
      COLOR=$RED
    fi

    printf "%-30s %-40s ${COLOR}%-25s${RESET}\n" "$NAME" "$HOST" "$EXPIRY"
  done

done