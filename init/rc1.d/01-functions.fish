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
        vsparc_proxy_pod $argv[2] $argv[3] $argv[4]

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

  echo "vsparc logs"
  echo "  get logs for selected pod"
  echo ""

  echo "vsparc proxy"
  echo "  creates a proxy from the local port to the remote port on the named pod"
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


function vsparc_proxy_k8s_dashboard
  set -l depname (k8s get deploy -n kube-system | grep "kubernetes-dashboard" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n kube-system -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  vsparc_proxy_pod "$podname" 9092 9090 'kube-system'
end

function vsparc_proxy_pgadmin_dashboard
  set -l depname (k8s get deploy -n vsparc | grep "timescale-admin" | cut -d' ' -f 1)
  set -l podname (k8s get pod -n vsparc -o json | jq -r ".items[].metadata.name | select(contains(\"$depname\"))")
  vsparc_proxy_pod "$podname" 16667 80 'vsparc'
end
