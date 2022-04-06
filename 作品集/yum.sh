#!/bin/bash
cd /etc/yum.repos.d/
mkdir /etc/yum.repos.d/repo
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo
[ $? -eq 0 ] && echo "开始装yum仓库"
echo '[yum]
name=yum
baseurl=file:///media
gpgcheck=0' > /etc/yum.repos.d/dvd.repo
[ $? -eq 0 ] && echo "开始编写fstab文件"
echo '/dev/cdrom /media iso9660 defaults 0 0' >> /etc/fstab
[ $? -eq 0 ] && echo "挂载校验"
mount -a 
yum clean all 
yum repolist
[ $? -eq 0 ] && echo "yum完毕"



