# -*- mode: ruby -*-
# vi: set ft=ruby :


ENV["LC_ALL"] = "en_US.UTF-8"
ENV["VAGRANT_DEFAULT_PROVIDER"] = "virtualbox"

#image_path = "file:///home/kyrron/Downloads/CentOS-7-x86_64-Vagrant-1804_02.VirtualBox.box"
# https://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7-x86_64-Vagrant-1804_02.VirtualBox.box
image_path = "centos/7"


$instances_amount = 2

Vagrant.configure("2") do |config|
  # v2 configs...
  # Using nfs ver=3 is dangerous I know, but there is no other otion for now for my laptop
  config.vm.synced_folder "provision/", "/provision", nfs_version: 3, type: "nfs", nfs_udp: false

  # setup vagrant plugin to automatically configure proxy on vms
  if Vagrant.has_plugin?("vagrant-proxyconf")
      #p_enable = true
      p_enable = false
      p_host = "172.29.50.100"
      p_port = 8080
      proxy = "http://#{p_host}:#{p_port}"
      no_proxy = "127.0.0.1, localhost, 10.10.10.11, 10.10.10.12, 10.244.0.0, 10.244.0.1, 10.244.0.2, 10.244.0.3, 10.244.0.0/16, 10.96.0.0, 10.96.0.0/12"
      config.proxy.http     = p_enable ? proxy : ""
      config.proxy.https    = config.proxy.http
      config.proxy.no_proxy = p_enable ? no_proxy : ""
  end

  # Sync time with the local host - I really don't know now how it works ;)
  ###config.vm.provider "virtualbox" do |vb|
  ###  vb.customize [ "guestproVagrant.configureperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
  ###end

  (1..$instances_amount).each do |item|

    config.vm.define "node#{item}" do |node|
      node.vm.box = "#{image_path}"
      node.vm.hostname = "node-#{item}"
      ip = "10.10.10.#{10+item}"
      node.vm.network "private_network", ip: ip
      #node.vm.box_check_update = "false"

      node.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        vb.gui = false
        vb.memory = "3072"
        vb.cpus = 1
        vb.name = "node#{item}"
      end

      #config.vm.network "forwarded_port", guest: 80, host: 9090

      node.vm.provision "shell", privileged: true, path: "./provision/bootstrap.sh", :args => ["#{item}", "#{p_enable}"]

    end

  end

end