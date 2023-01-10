#!/bin/bash
#使用yum安装部署lnmp，说明需要提前配置yum源，否者该脚本会失效。
#本脚本在版本centos7.2或者rhel7.2上使用
#安装http
yum -y isntall httpd
#安装相应的数据库包
yum -y install mariadb mariadb-server mariadb-devel
#安装相应的php包
yum -y install php php-mysql
#开启各项软件
systemctl start httpd
systemctl start mariadb
systemctl enable httpd
systemctl enable mariadb
