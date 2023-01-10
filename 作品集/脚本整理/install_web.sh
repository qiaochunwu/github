#!/bin/bash

#安装PHP
yum -y install php php-fpm php-mysql mariadb-server &> /dev/null

#源码安装Nginx
yum -y install gcc pcre-devel  openssl-devel &> /dev/null
tar -xf /root/nginx-1.12.2.tar.gz
cd /root/nginx-1.12.2
./configure --with-http_ssl_module --with-http_stub_status_module   &> /dev/null
make  &> /dev/null && make install  &> /dev/null
echo  "源码安装Nginx  OK"

#修改nginx配置,实现动静分离.
conf="/usr/local/nginx/conf/nginx.conf"
sed -i  '65,71s/#//'  $conf
sed -i  '/SCRIPT_FILENAME/d'  $conf
sed -i  's/fastcgi_params/fastcgi.conf/'  $conf

echo  "修改nginx配置,实现动静分离 OK"

#启动服务
systemctl  start  php-fpm
systemctl  enable  php-fpm &> /dev/null
/usr/local/nginx/sbin/nginx

echo /usr/local/nginx/sbin/nginx >> /etc/rc.local
chmod +x  /etc/rc.local
echo  "启动服务nginx php-fpm 设置开机自启  OK" 


#上传网页代码
tar -xf   /root/php-redis-demo.tar.gz  -C /root
cp -rf  /root/php-redis-demo/*  /usr/local/nginx/html/

echo  "上传网页资源代码  OK"

#挂载NFS共享目录
#yum  -y install nfs-utils  &> /dev/null
#showmount -e 192.168.1.21 &> /dev/null
#mkdir /data
#echo '192.168.1.21:/common /data nfs defaults 0 0' >> /etc/fstab
#mount -a

#echo  "挂载NFS服务器共享目录 OK"

#更改Nginx配置 添加location匹配静态资源
sed -ri "71 a location ~ .*\\\.(gif|jpg|png) { root /data; expires 30d;}"  $conf
/usr/local/nginx/sbin/nginx -s reload

#PHP实现Session共享
yum  -y  install autoconf  automake php-cli php-devel &> /dev/null
tar -xf  /root/php-redis-2.2.4.tar.gz  -C /root &> /dev/null
cd  /root/phpredis-2.2.4/
phpize  &> /dev/null
./configure  --with-php-config=/usr/bin/php-config &> /dev/null
make  &> /dev/null && make install  &> /dev/null
echo "安装php扩展模块 OK"

echo 'extension_dir = "/usr/lib64/php/modules/"'  >> /etc/php.ini
echo 'extension = "redis.so"'  >> /etc/php.ini
sed -ri '/session.save_handler/s/(.*)(=)(.*)/\1\2 redis/'  /etc/php-fpm.d/www.conf 
sed -ri '225c php_value[session.save_path] = "tcp://192.168.1.31:6379"'  /etc/php-fpm.d/www.conf
systemctl restart   php-fpm

echo  "更改php-fpm配置文件  OK"

netstat -antpu | grep php-fpm
netstat -antpu | grep nginx
