#!/usr/bin/env fish

function k8s 
  ssh prod-k8s-1 kubectl $argv
end

