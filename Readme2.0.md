Spin up k8s behind proxy:

node1 - 10.148.1.225
node2 - 10.148.0.245
node3 - 10.148.1.229


$ yum install -y --setopt=obsoletes=0 \
  docker-ce-18.06.0.ce-3.el7

$ yum install -y kubelet-1.12.1 kubeadm-1.12.1 kubectl-1.12.1

$ vi /etc/systemd/system/docker.service.d/docker.conf
[Service]
Environment="HTTP_PROXY=http://172.29.50.100:8080/"
Environment="HTTPS_PROXY=http://172.29.50.100:8080/"
Environment="http_proxy=http://172.29.50.100:8080/"
Environment="https_proxy=http://172.29.50.100:8080/"

$ systemctl daemon-reload; systemctl restart docker; systemctl enable docker.service

$ local_ip_addr=$(ip address show ens192 |grep "inet " | awk '{ print $2}' | cut -f1 -d"/")

$ cat >> ~/.bashrc <<EOF
export http_proxy=http://172.29.50.100:8080/
export https_proxy=$http_proxy
export HTTP_PROXY=$http_proxy
export HTTPS_PROXY=$http_proxy
#printf -v lan '%s,' ${local_ip_addr}
printf -v pool '%s,' 10.244.0.{1..255}
printf -v service '%s,' 192.168.0.{1..255}
export no_proxy="10.148.1.225,10.148.0.245,10.148.1.229,${service%,},${pool%,},127.0.0.1";
export NO_PROXY=$no_proxy
EOF

$ kubeadm init --help
$ kubeadm init --service-cidr=192.168.0.0/24 --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=${local_ip_addr} --kubernetes-version v1.12.1

$ kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

