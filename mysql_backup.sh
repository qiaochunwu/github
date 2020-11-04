#!/bin/bash
#导入数据库备份配置文件
source /usr/local/etc/zabbix_agentd.conf.d/zabbix_diy/script/conf_script/all_info.sh
conf_path='/usr/local/etc/zabbix_agentd.conf.d/zabbix_diy/localhost.conf/mysql_db_backup.conf'
#当前日期
Now=`date +%Y-%m-%d`
#当前时间日期
Now_time=$(date +"%Y-%m-%d_%H-%M-%S")
#confi info
#enabled backup status
backup_dir=`allconf_info Status $conf_path`
today_bag_path=`allconf_info today_bag_path $conf_path`
tmp_bag=`allconf_info tmp_bag $conf_path`
incremental_path=`allconf_info incremental_path $conf_path`
A_zone=`allconf_info A_zone $conf_path`
B_zone=`allconf_info B_zone $conf_path`
FtpAccount=`allconf_info FtpAccount $conf_path`
FtpPass=`allconf_info FtpPass $conf_path`
PName=`allconf_info PName $conf_path`
User=`allconf_info User $conf_path`
Pass=`allconf_info Pass $conf_path`
all_back=`allconf_info all_back $conf_path`
gpg_pub=`allconf_info gpg_pub_url $conf_path`
[ $backup_dir -eq 0 ] && echo '当前没有启用数据库备份' && exit
#all backup true is false
now_today_date=`cat /tmp/now_today_date.txt`

if [ -f /etc/my.cnf ];then
	my_cnf='/etc/my.cnf'
else
	my_cnf='/usr/my.cnf'
fi

if [ $Now == $now_today_date ];then
	echo 'today'
else
	rm -rf /backup
fi
#clear ftp logs
rm -f /tmp/ftp.log
#install tools
[ -f /usr/bin/innobackupex ] || yum -y install percona-xtrabackup
#yum setup
if [ $? -ne 0 ];then
        #key
#        wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7 http://120.79.77.12/tools/RPM-GPG-KEY-EPEL-7 --no-check-certificate
        #repo
#        wget -O /etc/yum.repos.d/innobackupex.repo http://120.79.77.12/tools/innobackupex.repo --no-check-certificate
	#install tools
        wget -O /tmp/percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.4/binary/redhat/7/x86_64/percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm
	[ -f /usr/bin/innobackupex ] || yum -y install /tmp/percona-xtrabackup-24-2.4.4-1.el7.x86_64.rpm
	if [ $? -ne 0 ];then
		echo 'xtrabackup安装失败'
                bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[["平台","'${PName}'"],["问题","mysql 备份 A and B 区备份失败"],["详情","xtrabackup安装失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
		exit
	fi
fi
#install lftp
rpm -q lftp   ||  yum install -y  lftp
#import gpg pub
[ -f /tmp/backup.pub ] || (wget -O /tmp/backup.pub ${gpg_pub} && gpg --import /tmp/backup.pub)
if [ $? -ne 0 ];then
                echo 'gpg 公钥部署失败'
                bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[["平台","'${PName}'"],["问题","mysql 备份 A and B 区备份失败"],["详情","gpg公钥部署失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
                exit
fi
#create drectory
[ -d $tmp_bag ] || mkdir $tmp_bag
#clear all gz bag
rm -rf ${tmp_bag}/*
#sock file
[ -S /var/lib/mysql/mysql.sock ] || (echo 'mysql sock 文件不存在';exit)
#sock file
[ -f /tmp/mysql.sock ] || ln -s /var/lib/mysql/mysql.sock  /tmp/mysql.sock

################################################################################################################

#add backup
if [ -d $today_bag_path ];then
        drectory=`ls -d $today_bag_path/*`
        all_back_filename=`echo $drectory | awk -F'/' '{print $3}'`
        #incremental file
        incremental_drectory=`ls -d $today_bag_path/$all_back_filename/*`
        if [ ! -d $incremental_path ];then
                innobackupex --defaults-file=${my_cnf} --user $User --password $Pass --incremental $incremental_path --incremental-basedir=${today_bag_path}/${all_back_filename}/
		if [ $? != 0  ];then
                        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[["平台","'${PName}'"],["问题","mysql 备份 A and B 区备份失败"],["详情","第一次增量备份innobackupex失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
                        exit
                fi
                last_filename=`ls -tr $incremental_path |tail -1`
                tar zcf ${tmp_bag}/${Now_time}.tar.gz -C $incremental_path  ${last_filename}
		if [ $? != 0  ];then
                        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[["平台","'${PName}'"],["问题","mysql 备份 A and B 区备份失败"],["详情","第一次增量备份tar包生成失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
			exit
		fi
                PUTFILE=${Now_time}'.tar.gz'
			#A zone
#########################################################
		#ftp uload
                lftp $A_zone -e"cd A_zone;cd $PName;cd $Now;mkdir incremental;cd incremental;lcd $tmp_bag;put $PUTFILE;bye" > /tmp/ftp.log
if ssh $A_zone test -e /var/ftp/A_zone/$PName/$Now/incremental/$PUTFILE;
    then  qixing=0
    else  qixing=1
fi
if [ $qixing -eq 0  ];then
	echo "${last_filename}A区节点第一次增量备份-上传成功"
else
	echo "${last_filename}A区节点第一次增量备份-上传失败"
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","A区节点第一次增量备份-上传失败"],["详情","ftpA区节点上传异常"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
	#exit
fi
rm -f /tmp/ftp.log
########################################################
			#B zone
#########################################################
		#ftp uload
                lftp $A_zone -e"cd B_zone;cd $PName;cd $Now;mkdir incremental;cd incremental;lcd $tmp_bag;put $PUTFILE;bye" > /tmp/ftp.log
if ssh $A_zone test -e /var/ftp/B_zone/$PName/$Now/incremental/$PUTFILE;
    then  qixing=0
    else  qixing=1
fi
if [ $qixing -eq 0  ];then
	echo "${last_filename}B区节点第一次增量备份-上传成功"
	exit
else
	echo "${last_filename}B区节点第一次增量备份-上传失败"
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","B区节点第一次增量备份-上传失败"],["详情","ftpB区上传异常"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
	exit
fi
########################################################
fi

############################################################################################################

#other
last_filename=`ls -tr $incremental_path/ |tail -1`
innobackupex --defaults-file=${my_cnf} --user $User --password $Pass --incremental $incremental_path --incremental-basedir=$incremental_path/${last_filename}/
if [ $? != 0  ];then
      bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","mysql备份失败"],["详情","增量备份innobackupex失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
      exit
fi
        tar zcf $tmp_bag/${Now_time}.tar.gz -C $incremental_path  ${last_filename}
	if [ $? != 0  ];then
              bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","mysql备份失败"],["详情","增量备份tar包生成失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
	      exit
        fi
        PUTFILE=${Now_time}'.tar.gz'
			# A zone 
#####################################################
lftp $A_zone -e"cd A_zone;cd $PName;cd $Now;mkdir incremental;cd incremental;lcd $tmp_bag;put $PUTFILE;bye" > /tmp/ftp.log
if ssh $A_zone test -e /var/ftp/A_zone/$PName/$Now/incremental/$PUTFILE;
    then  qixing=0
    else  qixing=1
fi
if [ $qixing -eq 0  ];then
        echo "${last_filename}A区节点增量备份-上传成功"

else
        echo "${last_filename}A区节点增量备份-上传失败"
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","A区节点增量备份-上传失败"],["详情","ftpA区节点上传异常"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
        #exit
fi
rm -f /tmp/ftp.log
####################################################
			# B zone
#####################################################
lftp $B_zone -e"cd B_zone;cd $PName;cd $Now;mkdir incremental;cd incremental;lcd $tmp_bag;put $PUTFILE;bye" > /tmp/ftp.log
if ssh $A_zone test -e /var/ftp/B_zone/$PName/$Now/incremental/$PUTFILE;
    then  qixing=0
    else  qixing=1
fi
if [ $qixing -eq 0  ];then
        echo "${last_filename}B区节点增量备份-上传成功"
	exit

else
        echo "${last_filename}B区节点增量备份-上传失败"
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","B区节点增量备份-上传失败"],["详情","ftpB区节点上传异常"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
        exit
fi
####################################################


fi
##########################################################################################################

#start all backup run only one
innobackupex --defaults-file=${my_cnf} --user $User  --password $Pass  $today_bag_path
echo '成功'
if [ $? != 0  ];then
     echo 'innobackupex全备执行失败！！！'
     bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","mysql备份失败"],["详情","全量备份innobackupex失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
     exit
fi
#tar bag
#all back filename
drectory=`ls -d $today_bag_path/*`
all_back_filename=`echo $drectory | awk -F'/' '{print $3}'`
echo $all_back_filename
tar zcf ${tmp_bag}/${all_back} -C $today_bag_path  ${all_back_filename}
if [ $? != 0 ];then
	echo 'tar 包生成失败！！！' 
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","mysql备份失败"],["详情","全量备份tar包生成失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
	exit
fi
#gpg pub tar
gpg -er mysql_backup --trust-model always ${tmp_bag}/${all_back}
if [ $? != 0 ];then
    bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","mysql备份失败"],["详情","全量备份tar包非对称加密失败"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
   exit
fi
gpg_all_back=${all_back}.gpg
#ftp upload A zone
split -b 50m  ${tmp_bag}/${gpg_all_back} ${tmp_bag}/${gpg_all_back}.
gpgfilename=${gpg_all_back}.
		#  A zone
##################################################
#upload
lftp $A_zone -e"cd A_zone;mkdir $PName;cd $PName;mkdir $Now;cd $Now;lcd $tmp_bag;mput ${gpgfilename}*;bye" > /tmp/ftp.log
if ssh $A_zone test -e /var/ftp/A_zone/$PName/$Now/all_backup.tar.gz.gpg.aa;
    then  qixing=0
    else  qixing=1
fi
if [ $qixing -eq 0  ];then
        echo "${all_back_filename}A区节点全量备份-上传成功"
	echo $Now >/tmp/now_today_date.txt
else
        echo "${all_back_filename}A区节点全量备份-上传失败"
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","A区节点全量备份-上传失败"],["详情","ftpA区上传异常"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
        #exit
fi
rm -f /tmp/ftp.log
#################################################
		#  B zone
##################################################
#upload
lftp $B_zone -e"cd B_zone;mkdir $PName;cd $PName;mkdir $Now;cd $Now;lcd $tmp_bag;mput ${gpgfilename}*;bye" > /tmp/ftp.log
if ssh $A_zone test -e /var/ftp/B_zone/$PName/$Now/all_backup.tar.gz.gpg.aa;
    then  qixing=0
    else  qixing=1
fi
if [ $qixing -eq 0  ];then
        echo "${all_back_filename}B区节点全量备份-上传成功"
	exit
else
        echo "${all_back_filename}B区节点全量备份-上传失败"
        bot_info='{"info":{"title": "mysql告警通知","token": "bot619423079:AAFPQuGFbCwH8O3jSefntGa8rd0Tr_Wq_zs","chatid": "-342008533"},"data":[
["平台","'${PName}'"],["问题","B区节点全量备份-上传失败"],["详情","ftpB区上传异常"]]}'
                curl https://telegram.uugl.pw/xiaotang/xiaotang -X POST -H "Content-Type:application/json" -d "$bot_info"
        exit
fi
#################################################
