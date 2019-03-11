#!/usr/bin/fish

function vsparc
  if test 0 -eq (count $argv)
    vsparc_help
    return
  end
  switch $argv[1]
    case pods
        vsparc_pods 
    case logs
        vsparc_logs $argv[2]
    case proxy
        vsparc_proxy_pod $argv[2] $argv[3] $argv[4] $argv[5]

    case tsdb
        vsparc_proxy_tsdb

    case kmgr
        vsparc_proxy_kafkamgr

    case grafana
        vsparc_proxy_grafana

    case pgadmin
        vsparc_proxy_pgadmin_dashboard

    case k8s
        vsparc_proxy_k8s_dashboard
    case help
        vsparc_help
    case '*'
      vsparc_help
  end
end

function vsparc_help -d "display usage info"
  
  echo "vSPARC:"
  echo ""
  echo ""

  echo "USAGE:"
  echo ""
  echo "vsparc <command> [options] [args]"
  echo ""
  
  echo "vsparc pods"
  echo "  get a list of the pods in thge vsparc namespace"
  echo ""

  echo "vsparc logs <pod name>"
  echo "  get logs for selected pod"
  echo ""

  echo "vsparc proxy <pod name> <port here> <port there> <namespace>"
  echo "  creates a proxy from the local port to the remote port on the named pod"
  echo ""

  echo "vsparc tsdb"
  echo "  creates a proxy to allow the use of timescale"
  echo ""

  echo "vsparc kmgr"
  echo "  creates a proxy to allow the use of kafka manager"
  echo ""

  echo "vsparc grafana"
  echo "  creates a proxy to allow the use of grafana"
  echo ""

  echo "vsparc pgadmin"
  echo "  creates a proxy to allow the use of pgadmin"
  echo ""

  echo "vsparc k8s"
  echo "  creates a proxy to allow the use of k8s dashboard"
  echo ""

  echo "vsparc help"
  echo "  this..."
  echo ""

end


function vsparc_pods
  Deployment/cmds.sh "prod" "get pods --namespace vsparc"
end

function vsparc_logs -a pod
  Deployment/cmds.sh "prod" "logs -f $pod --namespace vsparc"
end

function vsparc_proxy_pod -a podname localport remoteport ns
  set -l podip (k8s get pod $podname -n $ns -o json | jq -r '.status.podIP')
  ssh -L \*:$localport:$podip:$remoteport nsstltlb01 -N
end


function vsparc_proxy_tsdb
  vsparc_proxy_pod "vsparc-timescale-0" 5432 5432 'vsparc'
end

function vsparc_proxy_k8s_dashboard
  set -l depname (k8s get deploy -n kube-system | grep "kubernetes-dashboard" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n kube-system -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  display_proxy_details "k8s_dashboard" 7010
  vsparc_proxy_pod "$podname" 7010 9090 'kube-system'
end

function vsparc_proxy_kafkamgr
  set -l depname (k8s get deploy -n vsparc | grep "kafka-manager" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n vsparc -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  display_proxy_details "kafka manager" 7011
  vsparc_proxy_pod "$podname" 7011 80 'vsparc'
end


function vsparc_proxy_grafana
  set -l depname (k8s get deploy -n timescaledb | grep "grafana" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n timescaledb -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  display_proxy_details "grafana" 7012
  vsparc_proxy_pod "$podname" 7012 3000 'timescaledb'
end

function vsparc_proxy_pgadmin_dashboard
  set -l depname (k8s get deploy -n vsparc | grep "timescale-admin" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n vsparc -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  display_proxy_details "pgadmin" 7012
  vsparc_proxy_pod "$podname" 7013 80 'vsparc'
end

function vsparc_proxy_kafka
  set -l depname (k8s get deploy -n prod-tlive-es | grep "kafka" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n vsparc -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  display_proxy_details "kafka" 7013
  vsparc_proxy_pod "$podname" 7013 80 'vsparc'
end

function vsparc_get_ls2ts_pod_name
  set -l podname (k8s get pod -n vsparc -o json | jq -r ".items[].metadata.name | select(contains(\"vsparc-tsdb-logstash-deployment\"))")
  echo $podname
end

function display_proxy_details -a name port
  echo "proxying $name on port $port"
end
