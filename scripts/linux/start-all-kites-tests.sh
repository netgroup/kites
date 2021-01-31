#!/bin/bash

. ext/kites/scripts/linux/utils/logging.sh

function cleanup_mount() {
    log_inf "Start Cleanup cluster K8s and remount shared dir"
    log_debug "Start provision Cleanup"
    vagrant provision --provision-with cleanup
    log_debug "wait 60 seconds"
    sleep 60
    log_debug "Start provision mount-shared"
    vagrant provision --provision-with mount-shared
}

log_inf "Start Tests"
#log_inf "Cleanup environment"
#vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --clean-all'

#CALICO-VPP IPIP
# cleanup_mount
# log_debug "SETTING CALICO ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/flannel: true/flannel: false/g' env.yaml
# sed -i 's/weavenet: true/weavenet: false/g' env.yaml
# sed -i 's/calico: true/calico: false/g' env.yaml
# sed -i 's/calico-vpp: false/calico-vpp: true/g' env.yaml
# log_debug "SETTING CALICO ENCAPSULATION (IPIP)"
# sed -i 's/CALICO_IPV4POOL_IPIP: false/CALICO_IPV4POOL_IPIP: true/g' env.yaml
# sed -i 's/CALICO_IPV4POOL_VXLAN: true/CALICO_IPV4POOL_VXLAN: false/g' env.yaml
# log_debug "Vagrant quick-setup with CALICO IPIP"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH  CALICO-VPP IPIP"
# vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoIPIP -t udp --nodes 2'


# #WEAVE NET
# cleanup_mount
# log_debug "SETTING WEAVE NET IN ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/weavenet: false/weavenet: true/g' env.yaml
# sed -i 's/calico: true/calico: false/g' env.yaml
# sed -i 's/calico-vpp: true/calico-vpp: false/g' env.yaml
# sed -i 's/flannel: true/flannel: false/g' env.yaml
# log_debug "Vagrant quick-setup with WEAVE NET"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH WEAVE NET"
# vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni weavenet --nodes 2 -t udp -r 5'

# # CALICO IPIP IPv6
# cleanup_mount
# log_debug "SETTING CALICO ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/flannel: true/flannel: false/g' env.yaml
# sed -i 's/weavenet: true/weavenet: false/g' env.yaml
# sed -i 's/calico: false/calico: true/g' env.yaml
# sed -i 's/calico-vpp: true/calico: false/g' env.yaml
# log_debug "SETTING CALICO ENCAPSULATION (IPIP)"
# sed -i 's/CALICO_IPV4POOL_IPIP: false/CALICO_IPV4POOL_IPIP: true/g' env.yaml
# sed -i 's/CALICO_IPV4POOL_VXLAN: true/CALICO_IPV4POOL_VXLAN: false/g' env.yaml
# log_debug "Vagrant quick-setup with CALICO IPIP"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH  CALICO IPIP"
#vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoIPIP -t udp  --nodes 2'

# # CALICO VXLAN IPv6
# cleanup_mount
# log_debug "SETTING CALICO ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/flannel: true/flannel: false/g' env.yaml
# sed -i 's/weavenet: true/weavenet: false/g' env.yaml
# sed -i 's/calico: false/calico: true/g' env.yaml
# log_debug "SETTING CALICO ENCAPSULATION (VXLAN)"
# sed -i 's/CALICO_IPV4POOL_IPIP: true/CALICO_IPV4POOL_IPIP: false/g' env.yaml
# sed -i 's/CALICO_IPV4POOL_VXLAN: false/CALICO_IPV4POOL_VXLAN: true/g' env.yaml
# log_debug "Vagrant quick-setup with CALICO VXLAN"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH  CALICO VXLAN"
# vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoVXLAN6 -t tcp -6 --nodes 2'

# CALICO IPIP
#cleanup_mount
# log_debug "SETTING CALICO ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/flannel: true/flannel: false/g' env.yaml
# sed -i 's/weavenet: true/weavenet: false/g' env.yaml
# sed -i 's/calico: false/calico: true/g' env.yaml
# sed -i 's/calico-vpp: true/calico-vpp: false/g' env.yaml
# log_debug "SETTING CALICO ENCAPSULATION (IPIP)"
# sed -i 's/CALICO_IPV4POOL_IPIP: false/CALICO_IPV4POOL_IPIP: true/g' env.yaml
# sed -i 's/CALICO_IPV4POOL_VXLAN: true/CALICO_IPV4POOL_VXLAN: false/g' env.yaml
# log_debug "Vagrant quick-setup with CALICO IPIP"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH  CALICO IPIP"
vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoIPIP --nodes 2 -t udp -6'

# # CALICO VXLAN
# cleanup_mount
# log_debug "SETTING CALICO ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/flannel: true/flannel: false/g' env.yaml
# sed -i 's/weavenet: true/weavenet: false/g' env.yaml
# sed -i 's/calico: false/calico: true/g' env.yaml
# log_debug "SETTING CALICO ENCAPSULATION (VXLAN)"
# sed -i 's/CALICO_IPV4POOL_IPIP: true/CALICO_IPV4POOL_IPIP: false/g' env.yaml
# sed -i 's/CALICO_IPV4POOL_VXLAN: false/CALICO_IPV4POOL_VXLAN: true/g' env.yaml
# log_debug "Vagrant quick-setup with CALICO VXLAN"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH  CALICO VXLAN"
# vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoVXLAN --nodes 2'

# # FLANNEL
# cleanup_mount
# log_debug "SETTING FLANNEL IN ENV.YAML"
# sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
# sed -i 's/flannel: false/flannel: true/g' env.yaml
# sed -i 's/weavenet: true/weavenet: false/g' env.yaml
# sed -i 's/calico: true/calico: false/g' env.yaml
# log_debug "Vagrant quick-setup with FLANNEL"
# vagrant provision --provision-with quick-setup
# log_debug "wait 60 seconds"
# sleep 60
# log_debug "START TEST WITH FLANNEL"
# vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni flannel --nodes 2'

log_inf "End Tests"