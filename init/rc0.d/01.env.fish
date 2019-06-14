#!/usr/bin/env fish

if not set -q K8S_ENV
  set -U K8S_ENV local
end

if not set -q K8S_NS
  set -U K8S_NS (whoami)
end


function k8s_set_hosts -d 'sets up variables for things like docker registries and volume management' 
  set -e volume_hosts; set -e registry_hosts; set -e k8s_master_nodes
  switch $K8S_ENV
    case local
      set -U k8s_master_nodes "lok8stln01"
      set -U registry_hosts "lok8stln01"
      set -U volume_hosts "lok8stln01" "lok8stln02" "lok8stln03" "lok8stln04"
    case test
      set -U k8s_master_nodes "nsstltlb22"
      set -U registry_hosts "nsstltlb19" "nsstltlb20"
      set -U volume_hosts "nsstltlb19" "nsstltlb20" "nsstltlb21" "nsstltlb22" "nsstltlb23"
    case dev
      set -U k8s_master_nodes "root@nsda3tldv10"
      set -U registry_hosts "root@nsda3tldv10" "root@nsda3tldv11" "root@nsda3tldv12"
      set -U volume_hosts  "root@nsda3tldv10" "root@nsda3tldv11" "root@nsda3tldv12"
    case uat
      set -U k8s_master_nodes "root@nsda3bpltb01"
      set -U registry_hosts "root@nsda3bpltb01" "root@nsda3bpltb02" "root@nsda3bpltb03"
      set -U volume_hosts "root@nsda3bpltb01" "root@nsda3bpltb02" "root@nsda3bpltb03"
    case prod
      set -U k8s_master_nodes "root@nsstltlb01"
      set -U registry_hosts "root@nsstltlb01" "root@nsstltlb02" "root@nsstltlb03"
      # TODO: there may be more, of these... vvv
      set -U volume_hosts "root@nsstltlb01" "root@nsstltlb02" "root@nsstltlb03"
    case prod2
      set -U k8s_master_nodes "nsstltlb13"
      set -U registry_hosts "nsstltlb14" "nsstltlb44"
      set -U volume_hosts "nsstltlb34" "nsstltlb35" "nsstltlb36" "nsstltlb37" "nsstltlb38"
  end
end

k8s_set_hosts
