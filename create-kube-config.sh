#!/bin/bash

echo "please enter the k8 server url"
read server
#server=$1

echo "please enter the name of the secret" #ex: kubectl get secrets -n xyz : "xyz-token-bdmkt"
read secret_name
#secret_name=$2

echo "please enter the name of the namespace"
read namespace
#namespace=$3

echo "please enter the name of serviceaccount"
read serviceaccount


ca=$(kubectl get secret $secret_name -n $namespace -o jsonpath='{.data.ca\.crt}')
token=$(kubectl get secret $secret_name -n $namespace -o jsonpath='{.data.token}' | base64 --decode)

echo "
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    certificate-authority-data: ${ca}
    server: ${server}
contexts:
- name: default-context
  context:
    cluster: default-cluster
    namespace: ${namespace}
    user: ${serviceaccount}
current-context: default-context
users:
- name: ${serviceaccount}
  user:
    token: ${token}
" > ~/environment/sa.kubeconfig