#!/bin/bash
yum -y install vsftpd 
echo "修改配置文件允许匿名用户传参"
sed -i '29s/#//' /etc/vsftpd/vsftpd.conf
systemctl enable --now vsftpd 
chmod 777 /var/ftp/pub
echo "关闭防火墙与selinux"
systemctl stop firewalld 
setenforce 0
