#!/bin/bash
#WEAVE NET
echo -e "\n ###-----> SETTING WEAVE NET IN ENV.YAML <-----###\n"
sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
sed -i 's/weavenet: false/weavenet: true/g' env.yaml
sed -i 's/calico: true/calico: false/g' env.yaml
sed -i 's/flannel: true/flannel: false/g' env.yaml
echo -e "\n ###-----> VAGRANT UP WITH WEAVE NET <-----###\n"
vagrant up
echo -e "\n ###-----> START TEST WITH WEAVE NET <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh weavenet'
# CALICO IPIP
echo -e "\n ###-----> VAGRANT PROVISION CLEAN UP <-----###\n"
vagrant provision --provision-with cleanup
echo -e "\n ###-----> WAIT 60 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> VAGRANT PROVISION MOUNT-SHARED <-----###\n"
vagrant provision --provision-with mount-shared
echo -e "\n ###-----> SETTING CALICO ENV.YAML <-----###\n"
sed -i 's/weavenet: true/weavenet: false/g' env.yaml
sed -i 's/calico: false/calico: true/g' env.yaml
echo -e "\n ###-----> SETTING CALICO ENCAPSULATION (IPIP)<-----###\n"
sed -i 's/CALICO_IPV4POOL_IPIP: false/CALICO_IPV4POOL_IPIP: true/g' env.yaml
sed -i 's/CALICO_IPV4POOL_VXLAN: true/CALICO_IPV4POOL_VXLAN: false/g' env.yaml
echo -e "\n ###-----> VAGRANT PROVISION QUICK-SETUP (CALICO) <-----###\n"
vagrant provision --provision-with quick-setup
echo -e "\n ###-----> WAIT 60 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> START TEST WITH CALICO IPIP <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh calicoIPIP'
# CALICO VXLAN
echo -e "\n ###-----> VAGRANT PROVISION CLEAN UP <-----###\n"
vagrant provision --provision-with cleanup
echo -e "\n ###-----> WAIT 60 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> VAGRANT PROVISION MOUNT-SHARED <-----###\n"
vagrant provision --provision-with mount-shared
echo -e "\n ###-----> SETTING CALICO ENCAPSULATION (VXLAN)<-----###\n"
sed -i 's/CALICO_IPV4POOL_IPIP: true/CALICO_IPV4POOL_IPIP: false/g' env.yaml
sed -i 's/CALICO_IPV4POOL_VXLAN: false/CALICO_IPV4POOL_VXLAN: true/g' env.yaml
echo -e "\n ###-----> VAGRANT PROVISION QUICK-SETUP (CALICO) <-----###\n"
vagrant provision --provision-with quick-setup
echo -e "\n ###-----> WAIT 60 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> START TEST WITH CALICO VXLAN <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh calicoVXLAN'
# FLANNEL
echo -e "\n ###-----> VAGRANT PROVISION CLEAN UP <-----###\n"
vagrant provision --provision-with cleanup
echo -e "\n ###-----> WAIT 60 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> VAGRANT PROVISION MOUNT-SHARED <-----###\n"
vagrant provision --provision-with mount-shared
echo -e "\n ###-----> SETTING FLANNEL IN ENV.YAML <-----###\n"
sed -i 's/calico: true/calico: false/g' env.yaml
sed -i 's/flannel: false/flannel: true/g' env.yaml
echo -e "\n ###-----> VAGRANT PROVISION QUICK-SETUP (FLANNEL) <-----###\n"
vagrant provision --provision-with quick-setup
sleep 60
echo -e "\n ###-----> START TEST WITH FLANNEL <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh flannel'
