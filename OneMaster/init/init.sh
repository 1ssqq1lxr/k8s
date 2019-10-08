# 安装 chrony 服务，centos7.6默认自带了，没有的按如下安装
yum install -y chrony
systemctl start chronyd
systemctl enable chronyd
yum install -y bash-completion

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux  #永久关闭 修改/etc/sysconfig/selinux文件设置
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
swapoff -a #临时关闭swap
sed -i 's/.*swap.*/#&/' /etc/fstab #永久关闭 注释/etc/fstab文件里swap相关的行
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.ip_forward = 1
vm.swappiness=0
EOF
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum install -y kubelet-1.15.3 kubeadm-1.15.3 kubectl-1.15.3
mkdir /etc/docker
cat  <<EOF > /etc/docker/daemon.json
{
 "registry-mirrors": ["https://iv7stq00.mirror.aliyuncs.com"],
"data-root": "/opt/docker",
"insecure-registries" : ["192.168.100.32:9777"],
 "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
yum makecache fast
yum install -y docker-ce-18.06.3.ce-3.el7

systemctl start docker
systemctl enable docker
systemctl start kubelet
systemctl enable kubelet


kubeadm init --apiserver-advertise-address=192.168.100.31  --kubernetes-version="v1.15.3" --pod-network-cidr=10.0.0.0/16 --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers | tee kubeadm-init.log
