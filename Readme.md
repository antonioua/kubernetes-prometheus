# K8s cluster: 1 master and 1 worker + monitoring with prometheus

## Prerequisites:
- Install varant and VirtualBox
- vagrant plugin install vagrant-proxyconf

If you machine behind proxy then change var: p_enable = true

## Launch 2 virtualbox vms with vagrant and provision them with shell script
~~~bash
$ vagrant up
$ vagrant status
~~~

## Setup kuber master node1
~~~bash
$ vagrant ssh node1

# Resolve "cannot access /provision: Stale file handle"
# sudo umount /provision
$ sudo mount 10.10.10.1:/home/antonku/Documents/pycharm-prjs/automatization/kubernetes-prometheus/provision /provision

# Init kuber master node
$ sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.10.10.11 --kubernetes-version stable-1.11

# Copy credentials to /home/vagrant + some tweaks
$ sudo --user=vagrant mkdir -p /home/vagrant/.kube; \
  sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config; \
  sudo chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config; \
  echo "export KUBECONFIG=/home/vagrant/.kube/config" | tee -a /home/vagrant/.bashrc; \
  echo "KUBE_EDITOR=vim" | tee -a /home/vagrant/.bashrc

# By default, your cluster will not schedule pods on the master for security reasons. If you want to be able to schedule pods on the master
$ kubectl taint nodes --all node-role.kubernetes.io/master-

# Deploy the Container Networking Interface (CNI) - apply pod network (flannel) + RBAC permissions: master or v0.10.0
$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml

# Check kubernetes cluster
$ kubectl get pods --all-namespaces

# Generate join token for minions/workers 
$ kubeadm token create --print-join-command
~~~

## Setup kuber minion/worker node2
~~~bash
$ vagrant ssh node2
$ sudo kubeadm join 10.10.10.11:6443 --token zuaaz7.s3iykge1y2vz1xa5 --discovery-token-ca-cert-hash sha256:<Your token generated from master node>
~~~

## Setup Prometheus
For automatic spin up the prometheus service with all of it's components:
~~~bash
$ vagrant ssh node1
$ cd /provision/ && chmod u+x ./build_deployment_file.sh && ./build_deployment_file.sh
$ kubectl apply -f /provision/manifests-all.yaml
$ kubectl get pods --all-namespaces
$ kubectl get services --all-namespaces
~~~

For manual setup:
~~~bash
# Create namespace for monitoring deployment
$ kubectl create namespace monitoring
$ kubectl get namesapces

# Create Role-based access control config for Prometheus
# Assign cluster reader permission to "monitoring" namespace so that prometheus can fetch the metrics from kubernetes API’s
$ kubectl create -f /provision/yaml/prometheus/prometheus-rbac.yaml
$ kubectl get roles --all-namespaces
$ kubectl get serviceaccounts --all-namespaces

# Create config map
$ kubectl create -f /provision/yaml/prometheus/prometheus-configmap.yaml -n monitoring
$ kubectl get configmaps --all-namespaces

# Apply configmap with rules for Prometheus
$ kubectl apply -f /provision/yaml/prometheus/prometheus-rules-configmap.yaml --namespace=monitoring

# Create deployment
$ kubectl create -f /provision/yaml/prometheus/prometheus-deployment.yaml --namespace=monitoring
$ kubectl get pods --namespace=monitoring
# Check logs if sth  went wrong
$ kubectl describe pod prometheus-core-86b8455f76-px847 --namespace=monitoring

# Run prometheus pod as a service, expose Prometheus on all kubernetes nodes on port 30000.
$ kubectl create -f /provision/yaml/prometheus/prometheus-service.yaml --namespace=monitoring
$ kubectl get services --all-namespaces

# Deploy Alertmanager - got CreateContainerConfigError, need to check logs
$ kubectl apply -f /provision/yaml/alertmanager/alertmanager-configmap.yaml --namespace=monitoring
$ kubectl apply -f /provision/yaml/alertmanager/alertmanager-templates.yaml --namespace=monitoring
$ kubectl apply -f /provision/yaml/alertmanager/alertmanager-deployment.yaml --namespace=monitoring
$ kubectl apply -f /provision/yaml/alertmanager/alertmanager-service.yaml --namespace=monitoring

# Deploy manualy other components
# ToDO
~~~

To delete everything and play again:
~~~bash
$ kubectl delete -f /provision/manifests-all.yaml
$ kubectl delete namespace monitoring --grace-period=0 --force
~~~

## Conclusion
Used resources:
- https://github.com/prometheus/
- https://github.com/prometheus/prometheus/tree/master/documentation/examples
- https://github.com/giantswarm/kubernetes-prometheus/