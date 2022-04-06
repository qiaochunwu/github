#!/bin/bash
read -p "请输入用户名:" u
useradd $u
if [ $? -eq 0 ];then
stty -echo
read -p "请输入密码:" p
stty echo
echo $p | passwd --stdin $u 
fi
