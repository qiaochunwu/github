#!/bin/bash
#提取根的剩余空间
disk_size=$(df /|awk '/\//{print $4}')
#提取内存剩余空间
mem_size=$(free|awk '/Mem/{print $4}')
#使用循环判断空间大小,前提提前安装了mailx,开启邮件功能安装包,效果是运行禁止不动,另开窗口查看邮件。
while :
do
if [ $disk_size -le 16472044 -a $mem_size -le 494948  ];then
    mail -s "free warring" root <<EOF
    thise is a warring disk will poor,资源将不足
EOF

fi
done  
