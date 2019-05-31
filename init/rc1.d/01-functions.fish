#!/usr/bin/env fish

if not set -q K8S_ENV
  set -U K8S_ENV local
end

if not set -q K8S_NS
  set -U K8S_NS (whoami)
end


function k8s
  if test 0 -eq (count $argv)
    k8s_help
    return
  end
  switch $argv[1]
    case env;     k8s_display_current_env
    case grafana; k8s_proxy_grafana
    case k8s;     k8s_proxy_k8s_dashboard
    case kmgr;    k8s_proxy_kafkamgr
    case logs;    k8s_logs $argv[2]
    case pgadmin; k8s_proxy_pgadmin_dashboard
    case pod;     get_all_pods | grep $argv[2]
    case podx;    describe_pod $argv[2]
    case pods;    get_all_pods 
    case proxy;   proxy $argv[2] $argv[3] $argv[4]
    case sshkill; kill_all_ssh_tunnels_featuring_port $argv[2]
    case shell;   k8s_shell $argv[2] $argv[3]
    case swenv;   k8s_switch_env $argv[2]
    case swns;    k8s_switch_ns $argv[2]
    case ns;      k8s_display_current_ns
    case help;    k8s_help
    case '*';     k8s_help
  end
end


function kill_all_ssh_tunnels_featuring_port -a port
  ps --forest ax | grep ssh | grep $port | awk '{print $1;}'| xargs kill
end

function display_option -a name desc
  echo "k8s $name"
  echo "  $desc"
  echo ""

end

function k8s_help -d "display usage info"
  echo "Usage"
  echo ""
  echo "k8s <command> [options] [args]"
  echo ""

  display_option 'help' 'this...'
  display_option 'env' 'display current deployment env'
  display_option 'grafana' 'create a proxy to allow use of grafana'
  display_option 'k8s' 'create a proxy to allow use of k8s dashboard'
  display_option 'kmgr' 'create a proxy to allow use of kafka manager'
  display_option 'logs' 'get logs for selected pod'
  display_option 'ns' 'display current namespace'
  display_option 'pgadmin' 'create a proxy to allow use of pgadmin'
  display_option 'pod' 'get main k8s relay pod'
  display_option 'pods' 'get a list of the pods in the k8s namespace'
  display_option 'proxy' '<podname> <port here> <port there> creates a proxy from the local port to the remote port on the named pod'
  display_option 'psql' 'run psql on the chosen kind of postgres instance (primary or replica)'
  display_option 'sshkill <port>' 'kill any proxies listening on port provided'
  display_option 'shell <pod> <container>' 'open a shell in the container matching the pod'
  display_option 'swenv' 'switch env'
  display_option 'swns' 'switch namespace'
end

complete -c k8s -x -a pod -d 'get main k8s relay pod'
complete -c k8s -x -a pods -d 'get a list of the pods in the k8s namespace'
complete -c k8s -x -a logs -d 'get logs for selected pod'
complete -c k8s -x -a proxy -d ' <podname> <port here> <port there> creates a proxy from the local port to the remote port on the named pod'
complete -c k8s -x -a kmgr -d 'create a proxy to allow use of kafka manager'
complete -c k8s -x -a grafana -d 'create a proxy to allow use of grafana'
complete -c k8s -x -a pgadmin -d 'create a proxy to allow use of pgadmin'
complete -c k8s -x -a sshkill -d 'kill ssh proxies listening on port'
complete -c k8s -x -a swenv -d 'switch env'
complete -c k8s -x -a swns -d 'switch namespace'
complete -c k8s -x -a k8s -d 'create a proxy to allow use of k8s dashboard'
complete -c k8s -x -a help -d 'this...'
complete -c k8s -x -a env -d 'display current deployment env'
complete -c k8s -x -a ns -d 'display current namespace' 

function k8s_switch_env -a new_env -d "switch deployment environments"
  # use a validator to ensure no bogus env names are used
  if test \( $new_env = "dev" \) -o \( $new_env = "uat" \) -o \( $new_env = "test" \) -o \( $new_env = "prod" \) -o \( $new_env = "local" \)
    set -U K8S_ENV $new_env
  end
end

function k8s_switch_ns -a new_env -d "switch namespace"
  set -U K8S_NS $new_env
end

function k8s_display_current_env
  echo -n "the current working deployment environment is "
  echo $K8S_ENV
end

function k8s_display_current_ns
  echo -n "the current working namespace is "
  echo $K8S_NS
end


function get_ssh_host -d "look up, based on target deployment env, where we should be invoking kubectl"
  if test $K8S_ENV = "local"
    echo lok8stln01
  end
  if test $K8S_ENV = "test"
    echo nsstltlb22
  end
  if test $K8S_ENV = "dev"
    echo root@nsda3tldv10 
  end
  if test $K8S_ENV = "uat"
    echo root@nsda3bpltb01 
  end
  if test $K8S_ENV = "prod"
    echo root@nsstltlb01 
  end
end

function k8s_logs -a pattern
  set -l pod (get_pod_name $pattern)
  set -l ns (get_pod_ns $pattern)
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl logs $pod -n $ns
end

function describe_pod -a pattern
  set -l name (get_pod_name $pattern | command head -n 1)
  set -l ns (get_pod_ns $pattern | command head -n 1)
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get pod $name -n $ns -o=yaml
end

function get_pod_details
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get pods -n $K8S_NS -o=custom-columns=name:.metadata.name,podIP:.status.podIP,hostIP:.status.hostIP
end

function get_all_pods
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get pods -o=custom-columns=namespace:.metadata.namespace,name:.metadata.name,podIP:.status.podIP,hostIP:.status.hostIP --all-namespaces
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


####################################################################################
##############################[PROXYING COMMON APPS]################################
####################################################################################
function k8s_proxy -a podname localport remoteport
  set -l host (get_ssh_host)
  set -l ns (get_pod_ns $podname | command head -n 1)
  set -l podip (get_pod_ip $podname | command head -n 1)
  echo "proxying $podname $localport $remoteport $ns"
  ssh -L \*:$localport:$podip:$remoteport $host -N
end

function k8s_proxy_k8s_dashboard
	set -l pattern dashboard
	k8s_proxy $pattern 7010 9090 
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
  set -l svcClusterIP (ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl get svc --all-namespaces 2> /dev/null \
  | grep "$clusterName-$spiloRole" \
  | awk '{ print $4; }')
  echo "proxying $clusterName-$spiloRole"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) -L \*:5432:$svcClusterIP:5432 -N
end

function k8s_shell -a pod container -d 'open a shell on the target container'
  set -l podname (get_pod_name $pod)
  set -l podns (get_pod_ns $pod)
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl exec -i -t -n $podns $podname -c $container -- /bin/bash -l
end

