Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"

  config.vm.define "app01" do |app|
    app.vm.hostname = "app01"
    app.vm.network "private_network", ip: "192.168.56.11"
    #app.vm.provision "shell", path: "provision/app.sh"
    app.vm.network "forwarded_port", guest: 80, host: 8081
    app.vm.network "forwarded_port", guest: 22, host: 2225 
    app.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
  end

  config.vm.define "mon01" do |mon|
    mon.vm.hostname = "mon01"
    mon.vm.network "private_network", ip: "192.168.56.12"
    #mon.vm.provision "shell", path: "provision/mon.sh"
    mon.vm.network "forwarded_port", guest: 3000, host: 3000
    mon.vm.network "forwarded_port", guest: 22, host: 2200
    mon.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
      vb.cpus = 2
    end
  end

  config.vm.define "prom01" do |prom|
    prom.vm.hostname = "prom01"
    prom.vm.network "private_network", ip: "192.168.56.13"
    #prom.vm.provision "shell", path: "provision/prom.sh"
    prom.vm.network "forwarded_port", guest: 9090, host: 9090
    prom.vm.network "forwarded_port", guest: 22, host: 2202
    prom.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end

  config.vm.define "ansible01" do |ansible|
    ansible.vm.hostname = "ansible01"
    ansible.vm.network "private_network", ip: "192.168.56.10" 
    ansible.vm.network "forwarded_port", guest: 22, host: 2210 
    ansible.vm.provision "shell", path: "provision/ansible_setup.sh"
    ansible.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
    end
  end
end