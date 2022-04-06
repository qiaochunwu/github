#!/bin/bash
#查看$1(为指定的组)组是否存在不存在就创建
egrep "^$1" /etc/group &> /dev/null
if [ $? -ne 0 ];then 
groupadd $1
fi

 
#查看创建的用户$2是否存在不存在就创建
id $2  &> /dev/null
if [ $? -ne 0 ];then
useradd -G $1 $2
echo $3 | passwd --stdin $2 
fi
[ $? -eq 0 ] && echo '用户创建成功'



