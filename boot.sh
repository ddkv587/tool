#!/bin/bash

# config
config_hostname=$1
config_timezone=Asia/Shanghai
config_cockpit_port=8000
config_pwd=ddkV587_2021
config_device=/dev/mmcblk0
config_device_fs=/dev/mmcblk0p3
config_device_size=31.9GB
config_root_path=$PWD
config_proxy=1
config_http_proxy="http://proxy:1082"
config_https_proxy="http://proxy:1082"
config_no_proxy="localhost, 127.0.0.1, 172.17.0.0/16, 172.244.0.0/16, 10.96.0.0/12, 10.80.105.0/24, ddkV587, proxy, master, master2, node1, node2, node3, ::1"
config_docker=1
config_k8s=0
config_zsh=1
config_add_to_master=0
config_master_pwd=ddkV587_2021

env_os=Unknown

#
# $1: start prex 
# $2: end prex
# $3: replace file
# $4: target file
#
replace () {
    if [ $# -lt 4 ]; then
        echo "USAGE: replace( {start}, {end}, {replace}, {target} )"
    fi

    if grep -Fxq "$1" $4; then
        sed -i -e "/$1/{r $3" -e '};' -e "/$1/,/$2/ {d}" $4
    else
        cat $3 >> $4
    fi
}

checkOS () {
    if [ "$(uname)" = "Darwin" ]; then
        env_os="MacOS"
    elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
        if [ -f /etc/debian_version ]; then
            env_os="debian"
        elif [ -f /etc/redhat-release ]; then
            env_os="centos"
        else
            env_os="debian"
        fi
    elif [ "$(expr substr $(uname -s) 1 10)" = "MINGW32_NT" ]; then
        env_os="Windows"
    fi

    if [ "$env_os" != "debian" ] && [ "$env_os" != "centos" ]; then 
        ehco "unsupport system $env_os"
        exit 1
    fi
}

checkOS

echo "current system $env_os"

# init
parted $config_device resizepart 3 $config_device_size
resize2fs $config_device_fs

ENV_PREX_START_HOSTNAME="## __HOSTNAME START__ ##"
ENV_PREX_END_HOSTNAME="## __HOSTNAME END__ ##"

ENV_PREX_START_PROXY="## __PROXY START__ ##"
ENV_PREX_END_PROXY="## __PROXY END__ ##"

ENV_PREX_START_NAMESERVER="## __NAMESERVER START__ ##"
ENV_PREX_END_NAMESERVER="## __NAMESERVER END__ ##"

ENV_PREX_START_ZSHRC="## __ZSHRC START__ ##"
ENV_PREX_END_ZSHRC="## __ZSHRC END__ ##"

mkdir -p ._boot
cat << EOF > ._boot/hosts
$ENV_PREX_START_HOSTNAME
127.0.0.1 $config_hostname
10.80.105.1 proxy
10.80.105.220 omv
10.80.105.120 master
10.80.105.121 master2
10.80.105.140 node1
10.80.105.141 node2
10.80.105.142 node3
185.199.109.133 raw.githubusercontent.com
$ENV_PREX_END_HOSTNAME
EOF

cat << EOF > ._boot/proxy
$ENV_PREX_START_PROXY
export http_proxy="$config_http_proxy"
export https_proxy="$config_https_proxy"
export no_proxy="$config_no_proxy"
$ENV_PREX_END_PROXY
EOF

cat << EOF > ._boot/nameserver
$ENV_PREX_START_NAMESERVER
nameserver 1.1.1.1
$ENV_PREX_END_NAMESERVER
EOF

cat << EOF > ._boot/zshrc
$ENV_PREX_START_ZSHRC
if [ ${TERM} ]; then
    unset zle_bracketed_paste
fi
$ENV_PREX_END_ZSHRC
EOF

# set passwd
echo $config_pwd | passwd root --stdin

# set hostname and host
hostnamectl set-hostname $config_hostname

replace "$ENV_PREX_START_HOSTNAME" "$ENV_PREX_END_HOSTNAME" "._boot/hosts" "/etc/hosts"
replace "$ENV_PREX_START_NAMESERVER" "$ENV_PREX_END_NAMESERVER" "._boot/nameserver" "/etc/resolv.conf"

# set proxy
if [ "$config_proxy" -eq "1" ]; then
    replace "$ENV_PREX_START_PROXY" "$ENV_PREX_END_PROXY" "._boot/proxy" "$config_root_path/.bashrc"
    # source $config_root_path/.bashrc
    # cat << EOF >> /etc/yum.conf
    # proxy="$config_http_proxy"
    # EOF
fi

# set time zone
timedatectl set-timezone $config_timezone

# disable selinux
# setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config

# install apps
if [ "$env_os" = "debian" ]; then
    apt update
    apt install -y vim exuberant-ctags curl wget git tree zsh sshpass tar
else 
    yum update -y
    yum install -y util-linux-user yum-utils epel-release
    yum install -y vim ctags curl wget git tree zsh sshpass tar
fi

# config vim
wget --no-check-certificate https://github.com/ddkv587/tool/blob/master/vim.tar.gz?raw=true -O vim.tar.gz \
    && tar xvf vim.tar.gz \
    && cp -rf vim/.vim* $config_root_path/ \
    && rm -rf vim*

# gen ssh key and add to master
cat /dev/zero | ssh-keygen -q -N "" > /dev/null
if [ "$config_add_to_master" -eq "1" ]; then
    sshpass -p "$config_master_pwd" ssh-copy-id -o StrictHostKeyChecking=no root@master
fi

if [ "$config_zsh" -eq "1" ]; then
    chsh -s /bin/zsh root
    wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

    if [ -e $config_root_path/.oh-my-zsh/templates/zshrc.zsh-template ]; then
        cp -f $config_root_path/.oh-my-zsh/templates/zshrc.zsh-template $config_root_path/.zshrc
    fi
    if [ -e $config_root_path/.zshrc ]; then
        sed -i 's/^ZSH_THEME=.*/ZSH_THEME="ys"/' $config_root_path/.zshrc

        replace "$ENV_PREX_START_ZSHRC" "$ENV_PREX_END_ZSHRC" "._boot/zshrc" "$config_root_path/.zshrc"

        if [ "$config_proxy" -eq "1" ]; then
            replace "$ENV_PREX_START_PROXY" "$ENV_PREX_END_PROXY" "._boot/proxy" "$config_root_path/.zshrc"
        fi
        # source $config_root_path/.zshrc
    fi
fi

# install and config cockpit
if [ "$env_os" = "debian" ]; then
    apt-get install -y cockpit
else
    yum install -y cockpit
fi
mkdir -p /etc/systemd/system/cockpit.socket.d/
echo "[Socket]"                                 > /etc/systemd/system/cockpit.socket.d/listen.conf
echo "ListenStream="                            >> /etc/systemd/system/cockpit.socket.d/listen.conf
echo "ListenStream=$config_cockpit_port"        >> /etc/systemd/system/cockpit.socket.d/listen.conf
mkdir -p /etc/cockpit/ws-certs.d/
sshpass -p "$config_master_pwd" scp -r root@master:/etc/cockpit/ws-certs.d/* /etc/cockpit/ws-certs.d/
systemctl enable --now cockpit.socket
systemctl start cockpit

# install docker
if [ "$config_docker" -eq "1" ]; then
    if [ "$env_os" = "debian" ]; then
        apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io
    else
        yum install -y yum-utils
        yum-config-manager \
            --add-repo \
            https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
    fi
    systemctl enable docker

    # config cgroup driver
    mkdir -p /etc/docker/
cat << EOF >> /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

    # set docker daemon proxy
    if [ "$config_proxy" -eq "1" ]; then
        mkdir -p /etc/systemd/system/docker.service.d
cat << EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=$config_http_proxy"
Environment="HTTPS_PROXY=$config_https_proxy"
Environment="NO_PROXY=$config_no_proxy"
EOF

    # set docker container proxy
        mkdir -p $config_root_path/.docker/
cat << EOF > $config_root_path/.docker/config.json
{
    "proxies": {
        "default": {
            "httpProxy": "$config_http_proxy",
            "httpsProxy": "$config_https_proxy",
            "noProxy": "$config_no_proxy"
        }
    }
}
EOF
    fi # proxy
    systemctl daemon-reload
    systemctl restart docker
    systemctl show --property=Environment docker
    docker info

    # config cgroup_memory
    sed -i '1s/$/ cgroup_enable=memory swapaccount=1 cgroup_memory=1 cgroup_enable=cpuset/' /boot/cmdline.txt
fi # docker

# install k8s
if [ "$config_k8s" -eq "1" ]; then
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
    sysctl --system

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

    if [ "$config_zsh" -eq "1" ]; then
cat <<EOF >> ~/.zshrc
alias k="kubectl"
alias ka="kubectl -n app"
alias ks="kubectl -n kube-system"
alias kd="kubectl -n kubernetes-dashboard"
alias ki="kubectl -n ingress-nginx"
alias kn="kubectl -n nginx"
alias wk="watch kubectl"
alias wks="watch kubectl -n kube-system"
alias tool="k run -it --image index.docker.io/ddkv587/tool:0.1.0 tool --restart=Never --rm"
EOF
    else 
cat <<EOF >> ~/.bashrc
alias k="kubectl"
alias ka="kubectl -n app"
alias ks="kubectl -n kube-system"
alias kd="kubectl -n kubernetes-dashboard"
alias ki="kubectl -n ingress-nginx"
alias kn="kubectl -n nginx"
alias wk="watch kubectl"
alias wks="watch kubectl -n kube-system"
alias tool="k run -it --image index.docker.io/ddkv587/tool:0.1.0 tool --restart=Never --rm"
EOF
    fi

    if [ "$env_os" = "debian" ]; then
        apt-get install -y apt-transport-https ca-certificates curl
        curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
        echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        apt-get install -y kubelet kubeadm kubectl
        apt-mark hold kubelet kubeadm kubectl
    else
        yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    fi
    systemctl enable --now kubelet
fi # k8s

# install ufw
if [ "$env_os" = "debian" ]; then
    apt-get install -y ufw
else
    yum install -y ufw
fi
systemctl enable ufw
echo y | ufw enable

sed -i 's/^IPV6=yes$/IPV6=no/' /etc/default/ufw
systemctl restart ufw

ufw default allow outgoing
ufw default deny incoming
ufw limit from 10.80.105.0/24 to any port 22
ufw allow $config_cockpit_port
ufw reload

rm -rf ._boot
reboot