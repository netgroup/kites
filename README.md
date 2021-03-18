# KITES : Kubernetes networking Infrastructure TESting platform

KITES is a plugin of [kubernetes-playground](https://github.com/ferrarimarco/kubernetes-playground).

## Requirements

- [kubernetes-playground](https://github.com/ferrarimarco/kubernetes-playground).

## Install guide

Kites must be located in the ext/kites folder of a kubernetes-playground.

```sh
    cd kubernetes-playground/ext/
    git clone https://github.com/netgroup/kites
```

### Examples

As described [here](https://github.com/ferrarimarco/kubernetes-playground/blob/master/README.md#quick-cni-provisioning), if you want to test a different CNI plugin, first need to run:

```sh
    vagrant provision --provision-with cleanup
    vagrant provision --provision-with mount-shared
```

#### Execute tests on Calico with IPIP overlay

1. Enable Calico CNI and select IPIP encapsulation from the env.yaml:

```sh
    cd kubernetes-playground/
    sed -i 's/no-cni-plugin: true/no-cni-plugin: false/g' env.yaml
    sed -i 's/flannel: true/flannel: false/g' env.yaml
    sed -i 's/weavenet: true/weavenet: false/g' env.yaml
    sed -i 's/calico: false/calico: true/g' env.yaml
    sed -i 's/CALICO_IPV4POOL_IPIP: false/CALICO_IPV4POOL_IPIP: true/g' env.yaml
    sed -i 's/CALICO_IPV4POOL_VXLAN: true/CALICO_IPV4POOL_VXLAN: false/g' env.yaml
```

2. Vagrant quick-setup with CALICO IPIP

```sh
    vagrant provision --provision-with quick-setup
```

3. Start tests with Calico IPIP

   - Start test with all default options

   ```sh
       vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoIPIP --nodes 2'
   ```

   - Start test for TCP with IPv6

   ```sh
       vagrant ssh k8s-master-1.k8s-play.local -- -t 'cd /vagrant/ext/kites/scripts/linux/ && ./kites.sh --cni calicoIPIP --config -6 --nodes 2'
   ```

### Authors-Contributors

- Simone Zaccariello
- Stefano Salsano
- Carla Santangelo
- Francesco Lombardo
