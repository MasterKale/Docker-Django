# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.network "forwarded_port", guest: 8000, host: 8000
  config.vm.network "forwarded_port", guest: 5432, host: 15432
  config.vm.synced_folder ".", "/home/ubuntu/data"

  config.vm.box = "ubuntu/xenial64"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "3072"
    vb.cpus = 1
    vb.customize ['modifyvm', :id, '--ostype', 'Ubuntu_64']
    vb.name = "DVD-R"
  end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
    # Typical system update
    apt-get update
    apt-get upgrade -y

    # Install prereqs for installing official Docker from Docker, not Ubuntu
    apt-get install -y apt-transport-https ca-certificates
    apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" > /etc/apt/sources.list.d/docker.list
    apt-get purge lxc-docker
    apt-get update

    # Install linux-image-extra for aufs support, then Docker itself
    apt-get install -y linux-image-extra-$(uname -r) docker-engine

    # Add default ubuntu user to the docker group
    groupadd docker
    usermod -aG docker ubuntu
    
    # Start Docker
    service docker start

    # Install docker-compose
    curl -sSL https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Add machine name to the bash prompt
    sudo -u ubuntu sed -i -e 's/${debian_chroot:+($debian_chroot)}/${debian_chroot:+($debian_chroot)}(DVD-R) /g' /home/ubuntu/.bashrc

    # Enable color prompts
    sudo -u ubuntu sed -i -e 's/#force_color_prompt=yes/force_color_prompt=yes/g' /home/ubuntu/.bashrc

    # Add a `dc` alias for `docker-compose`
    touch /home/ubuntu/.bash_aliases
    echo "alias dc=\"docker-compose\"" >> /home/ubuntu/.bash_aliases

  SHELL
end