#!/bin/bash
# $1 为网页文件内容   $2为访问的域名
yum -y install httpd
[ $? -eq 0 ] && echo "appache 包安装完毕"
echo $1 >> /var/www/html/index.html
[ $? -eq 0 ] && echo "网页测试文件部署完毕"
systemctl stop firewalld
setenforce 0
getenforce
echo "<VirtualHost *:80>
ServerName $2
DocumentRoot /var/www/html
</VirtualHost>
" >> /etc/httpd/conf.d/web.conf
[ $? -eq 0 ] && echo "web虚拟机部署完毕 重启appache"
systemctl restart httpd
systemctl enable httpd
[ $? -eq 0 ] && echo "重启成功开始验证"
echo $3 $2 >> /etc/hosts
curl $2


