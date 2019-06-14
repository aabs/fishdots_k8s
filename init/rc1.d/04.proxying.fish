#!/usr/bin/env fish

function kill_all_ssh_tunnels_featuring_port -a port
  ps --forest ax | grep ssh | grep $port | awk '{print $1;}'| xargs kill
end

function k8s_proxy -a podname localport remoteport
  set -l host (get_ssh_host)
  set -l ns (get_pod_ns $podname | command head -n 1)
  set -l podip (get_pod_ip $podname | command head -n 1)
  echo "proxying $podname $localport $remoteport $ns"
  ssh -L \*:$localport:$podip:$remoteport $host -N
end


function k8s_proxy_svc -a svcname localport remoteport
  set -l host (get_ssh_host)
  set -l ns (get_svc_ns $svcname | command head -n 1)
  set -l svcip (get_svc_ip $svcname | command head -n 1)
  echo "proxying $svcname $localport $remoteport $ns"
  ssh -L \*:$localport:$svcip:$remoteport $host -N
end

function k8s_proxy_k8s_dashboard
	set -l pattern dashboard
  if test $K8S_ENV = "prod2"
 	  k8s_proxy $pattern 7010 8443 
  else
  	k8s_proxy $pattern 7010 9090 
  end
end

function k8s_proxy_kafkamgr
	set -l pattern 'kafka-manager'
	k8s_proxy $pattern 7011 80
end

function k8s_proxy_grafana
	set -l pattern 'grafana'
	k8s_proxy $pattern 7012 3000
end

function k8s_proxy_pgadmin_dashboard
	set -l pattern 'timescale-admin'
	k8s_proxy $pattern 7013 80
end

function k8s_proxy_kafka
	set -l pattern 'es-kafka'
	k8s_proxy $pattern 7014 80
end

function k8s_proxy_postgresql -a clusterName spiloRole
  set -l svcClusterIP (ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get svc --all-namespaces 2> /dev/null  | grep "$clusterName-$spiloRole"  | awk '{ print $4; }')
  echo "proxying $clusterName-$spiloRole"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) -L \*:5432:$svcClusterIP:5432 -N
end

function k8s_shell -a pod container -d 'open a shell on the target container'
  set -l podname (get_pod_name $pod)
  set -l podns (get_pod_ns $pod)
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl exec -i -t -n $podns $podname -c $container -- /bin/bash -l
end

