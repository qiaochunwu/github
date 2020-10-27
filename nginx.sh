#!/bin/bash
tar -xf  nginx-1.12.2.tar.gz
cd nginx-1.12.2
yum -y install gcc pcre-devel openssl-devel
./configure
make && make install
systemctl stop httpd 
/usr/local/nginx/sbin/nginx 
[ $? -eq 0 ] || echo "安装启动完毕，进行端口检查"
netstat -nultp | grep nginx 
