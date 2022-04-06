#!/bin/bash
netstat -nultp | grep nginx &> /dev/null
x=$?
case $1 in
start)
[ $x -eq 0 ] && echo "服务器正在运行..." && exit
/usr/local/nginx/sbin/ngin;;
stop)
[ $x -ne 0 ] && echo "服务器已经关闭..." && exit
/usr/local/nginx/sbin/nginx -s stop;;
restart)
[ $x -ne 0 ] && /usr/local/nginx/sbin/nginx && exit
/usr/local/nginx/sbin/nginx -s stop 
/usr/local/nginx/sbin/nginx;;
status)
  [ $x -eq 0 ] && echo "服务已经开启" || echo "服务未开启";;
*)
echo "start | stop | restart | status"
esac 
