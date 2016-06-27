# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.hostname = "cookiestrap"

  config.vm.box_check_update = true

  config.vm.network "forwarded_port", guest: 8000, host: 8000
  config.vm.network "forwarded_port", guest: 35729, host: 35729

  config.vm.synced_folder "www/", "/srv/www", create: true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "cookiestrap"
    vb.memory = "512"
  end

  config.vm.provision "shell", path: "cookiestrap.sh", privileged: false
end
