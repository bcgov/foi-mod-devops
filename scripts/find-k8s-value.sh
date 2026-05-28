#!/usr/bin/env bash

# Default namespaces
DEFAULT_NAMESPACES="04d1a3-prod d106d6-prod d7abee-prod eeced3-prod c84b95-prod 04d1a3-dev d106d6-dev d7abee-dev eeced3-dev c84b95-dev 04d1a3-test d106d6-test d7abee-test eeced3-test c84b95-test"

# Prompt user with default
read -rp "Enter OpenShift namespaces (space-separated) [default: $DEFAULT_NAMESPACES]: " NAMESPACES
if [ -z "$NAMESPACES" ]; then
  NAMESPACES="$DEFAULT_NAMESPACES"
fi

# Prompt for the target value to search
read -rp "Enter the specific value to search for [example: any keyword, password or username] : " TARGET_VALUE
if [ -z "$TARGET_VALUE" ]; then
  echo "Error: No value provided. Stopping the script."
  exit 1
fi

# We use grep -Fi to do a Fixed-string, case-insensitive search so special characters don't act as regex
GREP_CMD="grep -Fi"

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
    continue
  fi

  # Print table header
  printf "%-45s %-15s %-15s %-40s\n" "RESOURCE NAME" "TYPE" "MATCH FOUND" "MATCHED VALUE"
  printf "%-45s %-15s %-15s %-40s\n" "-------------" "----" "-----------" "-------------"

  # 1. Check Secrets
  oc get secret -n "$NAMESPACE" -o json | jq -r '
  .items[] | { name: .metadata.name, data: .data } | @base64' | while read -r row; do
    _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
    NAME=$(_jq '.name')
    DATA=$(_jq '.data')
    MATCH="NO"
    MATCHED_VAL=""
    if [ "$DATA" != "null" ] && [ -n "$DATA" ]; then
      while read -r k v; do
        if [ -z "$k" ] || [ -z "$v" ]; then continue; fi
        decoded_val=$(echo "$v" | base64 --decode 2>/dev/null | tr '\n' ' ')
        if echo "$decoded_val" | $GREP_CMD "$TARGET_VALUE" || echo "$k" | $GREP_CMD "$TARGET_VALUE"; then
          MATCH="YES"
          MATCHED_VAL="${decoded_val:0:37}..."
          break
        fi
      done < <(echo "$DATA" | jq -r 'to_entries[] | "\(.key) \(.value)"' 2>/dev/null)
    fi
    if [ "$MATCH" == "YES" ]; then
      PRINT_NAME="${NAME:0:42}"
      printf "%-45s %-15s ${RED}%-15s${RESET} %-40s\n" "$PRINT_NAME" "Secret" "$MATCH" "$MATCHED_VAL"
    fi
  done

  # 2. Check ConfigMaps
  oc get configmap -n "$NAMESPACE" -o json | jq -r '
  .items[] | { name: .metadata.name, data: .data } | @base64' | while read -r row; do
    _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
    NAME=$(_jq '.name')
    DATA=$(_jq '.data')
    MATCH="NO"
    MATCHED_VAL=""
    if [ "$DATA" != "null" ] && [ -n "$DATA" ]; then
      while read -r k v; do
        if [ -z "$k" ] || [ -z "$v" ]; then continue; fi
        if echo "$v" | $GREP_CMD "$TARGET_VALUE" || echo "$k" | $GREP_CMD "$TARGET_VALUE"; then
          MATCH="YES"
          v_clean=$(echo "$v" | tr '\n' ' ')
          MATCHED_VAL="${v_clean:0:37}..."
          break
        fi
      done < <(echo "$DATA" | jq -r 'to_entries[] | "\(.key) \(.value | tostring | gsub("\n"; " "))"' 2>/dev/null)
    fi
    if [ "$MATCH" == "YES" ]; then
      PRINT_NAME="${NAME:0:42}"
      printf "%-45s %-15s ${RED}%-15s${RESET} %-40s\n" "$PRINT_NAME" "ConfigMap" "$MATCH" "$MATCHED_VAL"
    fi
  done

  # 3. Check CronJobs
  oc get cronjob -n "$NAMESPACE" -o json | jq -r '
  .items[] | { name: .metadata.name, spec: .spec } | @base64' | while read -r row; do
    _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
    NAME=$(_jq '.name')
    SPEC=$(_jq '.spec')
    MATCH="NO"
    if echo "$SPEC" | $GREP_CMD "$TARGET_VALUE"; then
      MATCH="YES"
      MATCHED_VAL="(Found in CronJob spec)"
      PRINT_NAME="${NAME:0:42}"
      printf "%-45s %-15s ${RED}%-15s${RESET} %-40s\n" "$PRINT_NAME" "CronJob" "$MATCH" "$MATCHED_VAL"
    fi
  done

  # 4. Check Deployments (catches hardcoded envs)
  oc get deploy -n "$NAMESPACE" -o json | jq -r '
  .items[] | { name: .metadata.name, spec: .spec } | @base64' | while read -r row; do
    _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
    NAME=$(_jq '.name')
    SPEC=$(_jq '.spec')
    MATCH="NO"
    if echo "$SPEC" | $GREP_CMD "$TARGET_VALUE"; then
      MATCH="YES"
      MATCHED_VAL="(Found in Deployment spec)"
      PRINT_NAME="${NAME:0:42}"
      printf "%-45s %-15s ${RED}%-15s${RESET} %-40s\n" "$PRINT_NAME" "Deployment" "$MATCH" "$MATCHED_VAL"
    fi
  done

  # 5. Check StatefulSets
  oc get sts -n "$NAMESPACE" -o json 2>/dev/null | jq -r '
  .items[]? | { name: .metadata.name, spec: .spec } | @base64' | while read -r row; do
    if [ -z "$row" ]; then continue; fi
    _jq() { echo "$row" | base64 --decode | jq -r "$1"; }
    NAME=$(_jq '.name')
    SPEC=$(_jq '.spec')
    MATCH="NO"
    if echo "$SPEC" | $GREP_CMD "$TARGET_VALUE"; then
      MATCH="YES"
      MATCHED_VAL="(Found in StatefulSet spec)"
      PRINT_NAME="${NAME:0:42}"
      printf "%-45s %-15s ${RED}%-15s${RESET} %-40s\n" "$PRINT_NAME" "StatefulSet" "$MATCH" "$MATCHED_VAL"
    fi
  done

  # 6. Check Pod Environments via exec
  oc get pods -n "$NAMESPACE" --field-selector=status.phase=Running -o custom-columns=":metadata.name" --no-headers 2>/dev/null | while read -r pod; do
    if [ -z "$pod" ]; then continue; fi
    
    ENV_DATA=$(oc exec "$pod" -n "$NAMESPACE" -- printenv 2>/dev/null || true)
    if [ -n "$ENV_DATA" ]; then
      MATCH="NO"
      COLOR=$RESET
      MATCHED_VAL=""
      
      while IFS='=' read -r k v; do
        if [ -z "$k" ]; then continue; fi
        
        if echo "$k" | $GREP_CMD "$TARGET_VALUE" || echo "$v" | $GREP_CMD "$TARGET_VALUE"; then
          MATCH="YES"
          COLOR=$RED
          MATCHED_VAL="${v:0:37}..."
          break
        fi
      done <<< "$ENV_DATA"
      
      if [ "$MATCH" == "YES" ]; then
        PRINT_NAME="${pod:0:42}"
        printf "%-45s %-15s ${COLOR}%-15s${RESET} %-40s\n" "$PRINT_NAME" "Pod (Env)" "$MATCH" "$MATCHED_VAL"
      fi
    fi
    
    # Check Vault secrets mounted in the pod
    VAULT_DATA=$(oc exec "$pod" -n "$NAMESPACE" -- sh -c 'cat /vault/secrets/* 2>/dev/null' 2>/dev/null || true)
    if [ -n "$VAULT_DATA" ]; then
      if echo "$VAULT_DATA" | $GREP_CMD "$TARGET_VALUE"; then
        PRINT_NAME="${pod:0:42}"
        MATCHED_VAL="(Found in /vault/secrets/)"
        printf "%-45s %-15s ${RED}%-15s${RESET} %-40s\n" "$PRINT_NAME" "Pod (Vault)" "YES" "$MATCHED_VAL"
      fi
    fi
    
  done

done

echo -e "\nScan complete."
