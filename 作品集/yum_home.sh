#!/bin/bash
file_path=/var/ftp/localrepo/
yum install -y net-tools lftp rsync psmisc vim-enhanced tree vsftpd  bash-completion createrepo lrzsz iproute
mkdir /var/ftp/localrepo
cd /var/ftp/localrepo/
[ $file_path = $PWD ] && echo "在当前的路径"
createrepo .
createrepo --update .


