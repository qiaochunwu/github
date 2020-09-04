# 云计算基础 -- 虚拟化技术

## Linux虚拟化技术

#### 常用虚拟化技术

  vmware（收费，企业版 esxi ）
  https://www.proxmox.com/en/proxmox-ve
  redhat kvm rhev

#### 虚拟化平台安装

查看是否支持虚拟化

```shell 
[root@localhost ~]# grep -P "vmx|svm" /proc/cpuinfo
flags		: ... ... vmx
[root@localhost ~]# lsmod |grep kvm
kvm_intel             174841  6 
kvm                   578518  1 kvm_intel
irqbypass              13503  1 kvm
```

创建虚拟机 2cpu，4G内存（base-vm.zip 模板的默认用户名: root  密码: a）
配置 yum 源，安装 libvirt 软件
1、把 CentOS-7.5-1804.iso 加载到虚拟机的光驱里
2、虚拟机里面 mount 该 iso 到 /var/centos-1804
3、配置 yum 源

```shell
[root@localhost ~]# mkdir -p /var/centos-1804
[root@localhost ~]# vim /etc/fstab
dev/cdrom              /var/centos-1804        iso9660 defaults,ro     0 0
[root@localhost ~]# mount /var/centos-1804
[root@localhost ~]# vim /etc/yum.repos.d/local.repo
[CentOS-Base]
name=CentOS-$releasever - Base
baseurl="file:///var/centos-1804"
enabled=1
gpgcheck=0
```

4、安装 libvirtd

```shell
[root@localhost ~]# yum install qemu-kvm libvirt-daemon libvirt-client libvirt-daemon-driver-qemu
[root@localhost ~]# systemctl enable --now libvirtd
[root@localhost ~]# virsh version
```

**虚拟机组成**
​    硬盘文件  /var/lib/libvirt/images/
​    配置文件  /etc/libvirt/qemu/

#### 虚拟化实验图例

```mermaid
graph TB
  subgraph <font color=#ff0000>windows/真机</font>
      subgraph linux
        style linux color:#ff0000,fill:#11aaff
        H1(虚拟机1) --> B{{虚拟网桥 <font color=#ff0000>vbr</font>}} --> E[eth0]
        H2(虚拟机2) --> B
        H3(虚拟机3) --> B
      end
      E --> W(vmnet 设备)
  end
```

#### Linux虚拟机

###### 虚拟机硬盘磁盘文件

通过xshell上传 cirros.qcow2 到虚拟机
通过 qemu-img 创建虚拟机磁盘
格式: qemu-img  子命令  子命令参数  虚拟机磁盘文件  大小

```shell
[root@localhost ~]# cp cirros.qcow2 /var/lib/libvirt/images/
[root@localhost ~]# cd /var/lib/libvirt/images/
[root@localhost ~]# qemu-img create -f qcow2 -b cirros.qcow2 vmhost.img 30G
[root@localhost ~]# qemu-img info vmhost.img #查看信息
```

###### 虚拟机配置文件

官方文档地址 https://libvirt.org/format.html

1、拷贝 node_base.xml 到虚拟机中

2、拷贝 node_base.xml 到 /etc/libvirt/qemu/虚拟机名字.xml

3、修改配置文件，启动运行虚拟机

```shell
[root@localhost ~]# cp node_base.xml /etc/libvirt/qemu/vmhost.xml
[root@localhost ~]# vim /etc/libvirt/qemu/vmhost.xml
2:	<name>vmhost</name>
3:	<memory unit='KB'>1024000</memory>
4:	<currentMemory unit='KB'>1024000</currentMemory>
5:	<vcpu placement='static'>2</vcpu>
26:	<source file='/var/lib/libvirt/images/vmhost.img'/>
```

###### 虚拟网络配置

虚拟网络管理命令

| 命令                   | 说明                    |
| ---------------------- | -----------------------|
| virsh net-list [--all] | 列出虚拟网络|
| virsh net-start        | 启动虚拟交换机|
| virsh net-destroy      | 强制停止虚拟交换机|
| virsh net-define       | 根据xml文件创建虚拟网络|
| virsh net-undefine     | 删除一个虚拟网络设备|
| virsh net-edit         | 修改虚拟交换机的配置|
| virsh net-autostart    | 设置开机自启动|

创建配置文件 /etc/libvirt/qemu/networks/vbr.xml

```shell
[root@localhost ~]# vim /etc/libvirt/qemu/networks/vbr.xml
<network>
  <name>vbr</name>
  <forward mode='nat'/>
  <bridge name='vbr' stp='on' delay='0'/>
  <ip address='192.168.100.254' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.100' end='192.168.100.200'/>
    </dhcp>
  </ip>
</network>
```

创建虚拟交换机

```shell
[root@localhost ~]# cd /etc/libvirt/qemu/networks/
[root@localhost ~]# virsh net-define vbr.xml
[root@localhost ~]# virsh net-start vbr
[root@localhost ~]# virsh net-autostart vbr
[root@localhost ~]# ifconfig # 查看验证
```

#### 虚拟机管理

虚拟机管理命令

|命令|说明|
|----|----|
|virsh list [--all]|列出虚拟机|
|virsh start/shutdown|启动/关闭虚拟机|
|virsh destroy|强制停止虚拟机|
|virsh define/undefine|创建/删除虚拟机|
|virsh ttyconsole|显示终端设备|
|virsh console|连接虚拟机的 console|
|virsh edit|修改虚拟机的配置|
|virsh autostart|设置虚拟机自启动|
|virsh domfsinfo|查看文件系统信息|
|virsh dominfo|查看虚拟机摘要信息|
|virsh domiflist|查看虚拟机网卡信息|
|virsh domblklist|查看虚拟机硬盘信息|

###### 创建虚拟机

```shell
[root@localhost ~]# virsh list
[root@localhost ~]# virsh define /etc/libvirt/qemu/vmhost.xml
[root@localhost ~]# virsh start vmhost
[root@localhost ~]# virsh console vmhost # 两次回车
退出使用 ctrl + ]
```

## 公有云简介

#### 常用终端管理工具

###### xshell 使用技巧

使用 lrzsz 上传下载文件

安装软件 

```shell
[root@localhost ~]# yum install lrzsz
```

配置 xshell 激活 zmodem

退出重新登录以后，即可，上传(rz),下载(sz)