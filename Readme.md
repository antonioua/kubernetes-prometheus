# This is repo for automated k8s cluster start with 2 nodes
## Prerequisites:
install varant and VirtualBox

$ vagrant plugin install vagrant-proxyconf








???

 if settings[:proxy_state] == 'present'
     config.vm.provision 'proxy', type: 'shell', inline: <<-SHELL
       sudo echo "export http_proxy=http://#{settings[:proxy_host]}:#{settings[:proxy_port]}" >> /etc/environment
       sudo echo "export https_proxy=http://#{settings[:proxy_host]}:#{settings[:proxy_port]}" >> /etc/environment
       sudo echo "proxy=http://#{settings[:proxy_host]}:#{settings[:proxy_port]}" >> /etc/yum.conf
       sudo echo "sslverify=false" >> /etc/yum.conf
SHELL
  end



https://vagrantcloud.com/centos/boxes/7/versions/1803.01/providers/virtualbox.box


Tested with
Vagrant version 2.1.2
Virtualbox version 5.2.12


ip addr


//view cgroups and slices
$ sudo systemd-cgls

//check docker cgroup driver
sudo docker info | grep -i cgroup


sudo kubectl version -o yaml

kubeadm config images list

# How to use local kubectl to connect to remote k8s master/api server
vagrant plugin install vagrant-scp
vagrant scp <some_local_file_or_dir> [vm_name]:<somewhere_on_the_vm>
vagrant scp node1:/home/vagrant/.kube/config ~/Downloads/
kubectl --kubeconfig ~/Downloads/config get nodes


curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

yum install bash-completion -y
To add kubectl autocompletion to your current shell, run source <(kubectl completion bash).

To add kubectl autocompletion to your profile, so it is automatically loaded in future shells run:


echo "source <(kubectl completion bash)" >> ~/.bashrc


Tear down
On Master
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
kubectl delete node <node name>

On node that was removed - reset all kubeadm installed state:
kubeadm reset




Kuber dashboard:
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml