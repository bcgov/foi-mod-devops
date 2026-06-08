#!/bin/bash

read -p "Make sure you're logged into the Openshift API before proceeding. Proceed (y) or Exit (n): " confirm && [[ $confirm == [yY] ]] || exit 1
read -p "Enter target database you're recovering (ex// foidb or foi-docreviewer): " database
read -p "What environment are you targetting? (ex// dev, test or prod): " environment

echo "This is the start of a disaster recovery exercise for $database"
read -p "To continue scaling all pods up in d7abee and d106d6 that consume $database, proceed (y) or exit (n): " confirm && [[ $confirm == [yY] ]] || exit 1

if [[ "$database" == "foidb" ]]; then

    echo "Turning on all consumers of the $database in the d7abee-$environment."
    oc project d7abee-$environment
    deployments_d7abee=$(oc get deployment -n d7abee-$environment -l foidb-disaster-recovery=true -o jsonpath='{.items[*].metadata.name}')

    echo "Found deployments. Starting to scale all deployments with label foidb-disaster-recovery=true to 1."

    for deployment in ${deployments_d7abee}; do
        echo "Scaling '${deployment}' down to 1...."
        oc scale deployment/"${deployment}" -n d7abee-$environment --replicas=1
    done

    echo "All deployments with label foidb-disaster-recovery=true have been scaled to one"

    echo "Turning on all consumers of the $database in the d106d6-$environment."

    oc project d106d6-$environment

    deployments_d106d6=$(oc get deployment -n d106d6-$environment -l foidb-disaster-recovery=true -o jsonpath='{.items[*].metadata.name}')

    echo "Found deployments. Starting to scall all deployments with foidb-disaster-recovery=true to zero."

    for deployment in $deployments_d106d6; do
        echo "Scaling $deployment down to 1..."
        oc scale deployment/$deployment -n d106d6-$environment --replicas=1
    done

    echo "All deployments with label foidb-disaster-recovery=true have been scaled to zero."

fi
