#!/usr/bin/env fish


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
    case proxy;   k8s_proxy $argv[2] $argv[3] $argv[4]
    case sshkill; kill_all_ssh_tunnels_featuring_port $argv[2]
    case shell;   k8s_shell $argv[2] $argv[3]
    case swenv;   k8s_switch_env $argv[2]
    case swns;    k8s_switch_ns $argv[2]
    case ns;      k8s_display_current_ns
    case help;    k8s_help
    case '*';     k8s_help
  end
end

function _kc -a verb resource  -d 'helper function to pipe the named manifest to the default API host using the given k8s verb'
  echo "$resource ==> " (get_ssh_host)
  cat $resource  | ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl $verb -f -
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

function k8s_switch_env -a new_env -d "switch deployment environments"
  # use a validator to ensure no bogus env names are used
  if test \( $new_env = "dev" \) -o \( $new_env = "uat" \) -o \( $new_env = "test" \) -o \( $new_env = "prod" \) -o \( $new_env = "prod2" \) -o \( $new_env = "local" \)
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
  if test $K8S_ENV = "prod2"
    echo nsstltlb13
  end
end

function k8s_logs -a pattern
  set -l pod (get_pod_name $pattern)
  set -l ns (get_pod_ns $pattern)
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl logs $pod -n $ns
end

