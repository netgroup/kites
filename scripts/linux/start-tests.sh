#!/bin/bash
echo -e "\n ###-----> VAGRANT UP WITH WEAVE NET <-----###\n"
vagrant up
echo -e "\n ###-----> START TEST WITH WEAVE NET <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh weavenet'

echo -e "\n ###-----> VAGRANT PROVISION CLEAN UP <-----###\n"
vagrant provision --provision-with cleanup
echo -e "\n ###-----> WAIT 40 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> VAGRANT PROVISION MOUNT-SHARED <-----###\n"
vagrant provision --provision-with mount-shared
echo -e "\n ###-----> SETTING CALICO IN ENV.YAML <-----###\n"
sed -i 's/weavenet/calico/g' env.yaml
echo -e "\n ###-----> VAGRANT PROVISION QUICK-SETUP (CALICO) <-----###\n"
vagrant provision --provision-with quick-setup
echo -e "\n ###-----> WAIT 40 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> START TEST WITH CALICO <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh calico'

echo -e "\n ###-----> VAGRANT PROVISION CLEAN UP <-----###\n"
vagrant provision --provision-with cleanup
echo -e "\n ###-----> WAIT 40 SECONDS <-----###\n"
sleep 60
echo -e "\n ###-----> VAGRANT PROVISION MOUNT-SHARED <-----###\n"
vagrant provision --provision-with mount-shared
echo -e "\n ###-----> SETTING FLANNEL IN ENV.YAML <-----###\n"
sed -i 's/calico/flannel/g' env.yaml
echo -e "\n ###-----> VAGRANT PROVISION QUICK-SETUP (FLANNEL) <-----###\n"
vagrant provision --provision-with quick-setup
sleep 60
echo -e "\n ###-----> START TEST WITH FLANNEL <-----###\n"
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh flannel'
echo -e "\n ###-----> SETTING WEAVENET IN ENV.YAML <-----###\n"
sed -i 's/flannel/weavenet/g' env.yaml