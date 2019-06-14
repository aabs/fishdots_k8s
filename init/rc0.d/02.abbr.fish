#!/usr/bin/env fish

abbr --add kc "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=off (get_ssh_host) kubectl"
