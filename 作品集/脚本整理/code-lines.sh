#!/bin/bash
#code lines statistics
#EXAMPLE: ./code-lines.sh ./py01/day02
DIR_PATH=$1
echo '每日代码统计（有效代码）'
while [ ! $DIR_PATH ]
do
	echo '请输入要检测的项目目录位置：'
	read DIR_PATH
done
#检查目录
if [ ! -d $DIR_PATH ];then
	echo '指定位置不为目录'
	exit
fi
#检查目录下是否有.py后缀文件
if [ $(find $DIR_PATH -type f -regex  ".*\.py" | wc -l) -eq 0 ];then
	echo '当前目录下未找到python文件'
	exit
fi


echo '有效代码行数：'
find $DIR_PATH -type f -regex  ".*\.py" -exec grep -v "^$" {} \; | wc -l
