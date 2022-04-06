#!/bin/bash
#WRANDOM 为系统自带的变量值为0-32767得随机数
#使用取余算法将随机数变为1-100的随机数
num=$[RANDOM%100+1]
#使用read提示用户猜测数字
#使用if语句判断大小关系 -eq（等于），-ne（不等于），-gt（大于），-ge（大于等于），-lt（小于），-le（小于等于）
#使用while循环进行判断：
while :
do
  read -p "请输入1-100随机的数字：" cai
  if [ $cai -eq $num ];then
        echo "恭喜，猜对了"
  elif [ $cai -gt $num ];then
        echo "很遗憾，猜大了"
  else
        echo "很遗憾，猜小了"
  fi
done
