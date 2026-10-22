# vi: ft=ruby:ts=2:ai:sw=2
# 2 VM Ubuntu 24.04 ; Ansible installe Docker + Terraform, puis Terraform crée le conteneur CV One Page
# sur le port 8001 de vm1 et 8002 de vm2.
CV_VMS = [
  { name: "vm1", ip: "192.168.56.21", cv_port: 8001, host_port: 9001 },
  { name: "vm2", ip: "192.168.56.22", cv_port: 8002, host_port: 9002 },
]

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  CV_VMS.each do |vm|
    config.vm.define vm[:name] do |node|
      node.vm.hostname = vm[:name]
      node.vm.network "private_network", ip: vm[:ip]
      # Accès depuis le PC : http://IP-VM-LAB:9001 (vm1) et :9002 (vm2)
      node.vm.network "forwarded_port", guest: vm[:cv_port], host: vm[:host_port], host_ip: "0.0.0.0"

      node.vm.provider "virtualbox" do |vb|
        vb.name   = "tp6-#{vm[:name]}"
        vb.memory = 1024
        vb.cpus   = 1
      end

      node.vm.provision "ansible" do |a|
        a.playbook = "playbook.yml"
        a.compatibility_mode = "2.0"
        a.host_vars = {
          "vm1" => { "cv_port" => 8001 },
          "vm2" => { "cv_port" => 8002 },
        }
      end
    end
  end
end
