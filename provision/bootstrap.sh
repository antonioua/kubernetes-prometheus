#!/bin/bash

cp /vagrant/provision/stuff/1.crt /etc/pki/ca-trust/source/anchors/
/usr/bin/update-ca-trust

timedatectl set-timezone Europe/Kiev
#yum update -y

# install tools
yum install net-tools telnet -y

# Installing Docker
yum install -y docker-1.13.1-63.git94f4240.el7.centos;\
systemctl enable docker && systemctl start docker

# Installing kubeadm, kubelet and kubectl
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
yum install -y kubelet kubeadm kubectl
systemctl enable kubelet && systemctl start kubelet

# Enable iptable kernel parameter"
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p

# Some users on RHEL/CentOS 7 have reported issues with traffic being routed incorrectly due to iptables being bypassed. You should ensure net.bridge.bridge-nf-call-iptables is set to 1
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
# sysctl net.bridge.bridge-nf-call-iptables=1
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
###sudo sed '/ExecStart=$/a Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"' -i /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

###kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=10.10.10.11 --kubernetes-version stable-1.11

# Set up admin creds for the vagrant user
###echo Copying credentials to /home/vagrant...
###sudo --user=vagrant mkdir -p /home/vagrant/.kube
###cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
###chown $(id -u vagrant):$(id -g vagrant) /home/vagrant/.kube/config
# echo "export KUBECONFIG=/home/vagrant/.kube/config" | tee -a /home/vagrant/.bashrc

# Apply pod network (flannel)
###kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
# You can confirm that it is working by checking that the CoreDNS pod is Running in the output of
###kubectl get pods --all-namespaces

# Master Isolation
# By default, your cluster will not schedule pods on the master for security reasons. If you want to be able to schedule pods on the master
###kubectl taint nodes --all node-role.kubernetes.io/master-
