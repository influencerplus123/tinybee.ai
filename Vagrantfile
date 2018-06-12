# -*- mode: ruby -*-
# vi: set ft=ruby :

# PyBossa Vagrantfile

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(2) do |config|

  config.vm.provision "shell", 
  inline: "which python || sudo apt -y install python"

  config.vm.box = "ubuntu/xenial64"
  # set up network ip and port forwarding
  config.vm.network "forwarded_port", guest: 5000, host: 5000, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 5001, host: 5001, host_ip: "127.0.0.1"
  config.vm.network :private_network, ip: "192.168.33.10"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "512"
    vb.cpus = 1
  end
  # Copy your ssh keys for github so that your git credentials work
  if File.exists?(File.expand_path("~/.ssh/id_rsa"))
    config.vm.provision "file", source: "~/.ssh/id_rsa", destination: "~/.ssh/id_rsa"
    config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "~/.ssh/id_rsa.pub"
  end
  config.vm.synced_folder ".", "/vagrant", mount_options: ["dmode=775,fmode=664"]
  # turn off warning message `stdin: is not a tty error`
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
    ansible.inventory_path = "provisioning/inventory/ansible_hosts"
  end
end
