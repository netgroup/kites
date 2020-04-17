#!/bin/bash
#TODO INSERIRE DIVISIONI PER RENDERE PIU' LEGGIBILE IL LOG 
vagrant up
vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh weavenet'

vagrant provision --provision-with cleanup
sleep 20
vagrant provision --provision-with mount-shared
sed -i 's/weavenet/calico/g' env.yaml
vagrant provision --provision-with quick-setup
sleep 20

vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh calico'

vagrant provision --provision-with cleanup
sleep 20
vagrant provision --provision-with mount-shared
sed -i 's/calico/flannel/g' env.yaml
vagrant provision --provision-with quick-setup
sleep 20

vagrant ssh k8s-master-1.k8s-play.local -- -t '/vagrant/ext/kites/scripts/linux/start.sh flannel'
sed -i 's/flannel/weavenet/g' env.yaml