#!/bin/bash

item=$1
p_enable=$2


certs_chain_file="/vagrant/provision/certificates/1.crt"
if [ -f "${certs_chain_file}" ] && [ "${p_enable}" == "true" ]; then
  cp ${certs_chain_file} /etc/pki/ca-trust/source/anchors/ && /usr/bin/update-ca-trust
fi

timedatectl set-timezone Europe/Kiev
#yum update -y

# Install tools
yum install epel-release -y
yum install net-tools telnet ntp jq vim lsof -y

systemctl start ntpd
systemctl enable ntpd

# Install Docker
yum install -y yum-utils \
  device-mapper-persistent-data \
  lvm2

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Install recommended by kuber version of docker
#yum list docker-ce --showduplicates | sort -r
yum install -y --setopt=obsoletes=0 \
  docker-ce-17.03.2.ce-1.el7.centos \
  docker-ce-selinux-17.03.2.ce-1.el7.centos
systemctl enable docker && systemctl start docker

# Avoid kuber warning [WARNING RequiredIPVSKernelModulesAvailable]: the IPVS proxier will not be used
cat <<EOF > /etc/modules-load.d/k8s_modules.conf
ip_vs_sh
ip_vs_rr
ip_vs_wrr
EOF

systemctl restart systemd-modules-load.service

# Add k8s repo
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Disabling SELinux is required to allow containers to access the host filesystem, which is required by pod networks for example. You have to do this until SELinux support is improved in the kubelet.
setenforce 0
sed -i 's/=enforcing/=disabled/g' /etc/selinux/config
# kubelet: the component that runs on all of the machines in your cluster and does things like starting pods and containers.
# kubeadm: the command to bootstrap the cluster.
# kubectl: the command line util to talk to your cluster.
systemctl stop firewalld

# Install kuber node components: kubeadm, kubelet and kubectl
yum install -y kubelet kubeadm kubectl

#yum install -y --setopt=obsoletes=0 \
#  kubelet-1.8.15-0 \
#  kubeadm-1.8.15-0 \
#  kubectl-1.8.15-0

systemctl enable kubelet && systemctl start kubelet

# Enable iptables kernel parameter"
# Some users on RHEL/CentOS 7 have reported issues with traffic being routed incorrectly due to iptables being bypassed. You should ensure net.bridge.bridge-nf-call-iptables is set to 1
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptables=1
EOF
sysctl -p /etc/sysctl.conf

# The kubelet is now restarting every few seconds, as it waits in a crashloop for kubeadm to tell it what to do.

# Disable swap
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab
#lvremove -fAy /dev/VolGroup00/LogVol01
#lvextend -l +100%FREE /dev/VolGroup00/LogVol00
#sed 's/rd.lvm.lv=VolGroup00\/LogVol01//' -i /etc/default/grub
#grub2-mkconfig >/etc/grub2.cfg

# Setup kubernetes Master node
# Configure Kubernetes to use the same CGroup driver as Docker
sed '/ExecStart=$/a Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=cgroupfs"' -i /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
systemctl daemon-reload
systemctl restart kubelet.service

# let's check if our k8s is already running
docker ps | grep -v grep | grep -q etcd
check_kubelet=$(echo $?)

# Let's prepare master node
###if [ "${item}" == "1" ] && [ "${check_kubelet}" == "1" ]; then
###  kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.10.10.11 --kubernetes-version stable-1.11
###
###  echo Copying credentials to /home/vagrant...
###  sudo --user=vagrant mkdir -p /home/vagrant/.kube
###  cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
###  chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config
###  echo "export KUBECONFIG=/home/vagrant/.kube/config" | tee -a /home/vagrant/.bashrc
###  echo "KUBE_EDITOR="vim" | tee -a /home/vagrant/.bashrc
###
###  # Master unIsolation
###  # By default, your cluster will not schedule pods on the master for security reasons. If you want to be able to schedule pods on the master
###  kubectl taint nodes --all node-role.kubernetes.io/master-
###
###  # Deploy the Container Networking Interface (CNI)
###  # Apply pod network (flannel)
###  #kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
###  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
###  # To bundle RBAC permissions
###  #kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
###  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
###  # You can confirm that it is working by checking that the CoreDNS pod is Running in the output of
###  kubectl get pods --all-namespaces
###else
###  echo -e "This is not a master node or kubelet is already running here"
###fi