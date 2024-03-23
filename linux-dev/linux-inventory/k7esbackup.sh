#!/bin/bash

keywords=("deployments" "statefulsets" "services" "ingress" "pv" "pvc" "serviceaccounts")

for type in "${keywords[@]}"; do
    output=$(kubectl get $type --all-namespaces | awk 'NR>1 {print $1, $2}')
    if [ "$output" = "" ]; then
        echo "No $type"
        continue
    else
        while IFS= read -r line; do
            if [ "$type" = "pv" ]; then
                mkdir -p /opt/k8sbak/$type
                name=$(echo "$line" | awk '{print $1}')
                echo "Processing $type $name"
                kubectl get $type $name -o yaml > "/opt/k8sbak/$type/$name.yaml"
            else
                namespace=$(echo "$line" | awk '{print $1}')
                name=$(echo "$line" | awk '{print $2}')
                echo "Processing $type $name in namespace $namespace"
                mkdir -p /opt/k8sbak/$namespace/$type
                kubectl -n $namespace get $type $name -o yaml > "/opt/k8sbak/$namespace/$type/$name.yaml"
            fi
        done <<< "$output"
    fi
done
echo "Backups made in /opt/k8sbak"