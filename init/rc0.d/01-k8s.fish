#!/usr/bin/env fish

function k8s 
  pushd .
  cd $HOME/etc/kubectl/
  ./prod-01.sh $argv
  popd
end

