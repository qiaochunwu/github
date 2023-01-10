#!/bin/bash
d=repo
cd /etc/yum.repos.d/
if [ -d $d ];then
echo "有repo目录"
else
echo "repo目录不存在,开始创建" && mkdir /etc/yum.repos.d/$d && echo "创建文件完毕"
fi
[ -d $d ] && echo "repo已经存在" && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$d &>/dev/null
echo "开始配置yum文件"
echo "[rh7_baseos]
name=base
baseurl=file:///media
gpgcheck=0" >/etc/yum.repos.d/dvd.repo
echo "文件配置完毕" && echo "开始验证"
yum clean all 
yum makecache
yum repolist
echo "开始自动开机挂载"
echo "/dev/cdrom /media iso9660 defaults 0 0 " >> /etc/fstab
echo "完毕开始验证"
umount /media
mount -a 
echo "验证完毕请检查"
echo "开始安装"
yum -y install vim net-tools bash-completion
