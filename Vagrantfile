# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # centos 6.5
  config.vm.box = "bradallenfisher/centos7"
  # ip address
  config.vm.network "private_network", ip: "192.168.19.07"
  # host name
  config.vm.hostname = "local.phpng.dev"

  # run script as root
  config.vm.provision "shell",
    path: "install/install.sh"

  # virtual box name
  config.vm.provider "virtualbox" do |v|
    v.name = "php-7"
    v.memory = 4096
    v.cpus = 2
  end
end