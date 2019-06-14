#!/usr/bin/env fish

function describe_pod -a pattern
  set -l name (get_pod_name $pattern | command head -n 1)
  set -l ns (get_pod_ns $pattern | command head -n 1)
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get pod $name -n $ns -o=yaml
end

function get_pod_details
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get pods -n $K8S_NS -o=custom-columns=name:.metadata.name,podIP:.status.podIP,hostIP:.status.hostIP
end

function get_svc_details
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get svc -n $K8S_NS -o=custom-columns=name:.metadata.name,clusterIP:.status.clusterIP
end

function get_all_pods
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get pods -o=custom-columns=namespace:.metadata.namespace,name:.metadata.name,podIP:.status.podIP,hostIP:.status.hostIP --all-namespaces
end

function get_all_svcs
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get svc -o=custom-columns=namespace:.metadata.namespace,name:.metadata.name,clusterIP:.spec.clusterIP --all-namespaces
end

function get_pod_ns -a pattern
  get_all_pods | grep $pattern | awk '{print $1;}'
end


function get_pod_name -a pattern
  get_all_pods | grep $pattern | awk '{print $2;}'
end


function get_pod_ip -a pattern
  get_all_pods | grep $pattern | awk '{print $3;}'
end

function get_pod_hostip -a pattern
  get_all_pods | grep $pattern | awk '{print $4;}'
end

function get_svc_ns -a pattern
  get_all_svcs | grep $pattern | awk '{print $1;}'
end


function get_svc_name -a pattern
  get_all_svcs | grep $pattern | awk '{print $2;}'
end


function get_svc_ip -a pattern
  get_all_svcs | grep $pattern | awk '{print $3;}'
end



