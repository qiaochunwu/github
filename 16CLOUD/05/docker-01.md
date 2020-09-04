# 容器技术 -- 1

## docker安装

#### 安装前准备：

​    1、禁用 selinux  [SELINUX=disabled]

​    2、卸载防火墙    [yum -y remove firewalld-*]

​    3、docker软件安装包在  云盘\kubernetes\docker 目录下，将 docker 目录上传到跳板机

​    4、准备 2 台 2cpu，2G内存的云主机

| 主机名    | IP地址       | 最低配置    |
| --------- | ------------ | ----------- |
| node-0001 | 192.168.1.31 | 2CPU,2G内存 |
| node-0002 | 192.168.1.32 | 2CPU,2G内存 |

#### 跳板机yum源添加docker软件

```shell
[root@ecs-proxy ~]# cp -a docker /var/ftp/localrepo/ 
[root@ecs-proxy ~]# cd /var/ftp/localrepo/
[root@ecs-proxy localrepo]# createrepo --update .
```

#### 在 node 节点验证软件包

```shell
[root@node-0001 ~]# yum makecache
[root@node-0001 ~]# yum list docker-ce*
```

以下操作所有 node 节点都需要执行

#### 开启路由转发

```shell
[root@node-0001 ~]# vim /etc/sysctl.conf
net.ipv4.ip_forward = 1
[root@node-0001 ~]# sysctl -p
```

```shell
[root@node-0001 ~]# yum install -y docker-ce
[root@node-0001 ~]# systemctl enable --now docker
[root@node-0001 ~]# ifconfig # 验证，能看见 docker0
[root@node-0001 ~]# docker version # 验证，没有报错
```

#### 开放 FORWARD 默认规则

```shell
[root@node-0001 ~]# vim /lib/systemd/system/docker.service
# 在 ExecStart 下面添加
ExecStartPost=/sbin/iptables -P FORWARD ACCEPT
[root@node-0001 ~]# systemctl daemon-reload
[root@node-0001 ~]# systemctl restart docker
[root@node-0001 ~]# iptables -nL FORWARD
```

## 镜像管理&容器管理

#### docker镜像管理命令

| 镜像管理命令 | 说明 |
| :------------ | :----------------- |
| docker images | 查看本机镜像 |
| docker  search  镜像名称 | 从官方仓库查找镜像 |
| docker  pull  镜像名称:标签 | 下载镜像 |
| docker  push  镜像名称:标签 | 上传镜像 |
| docker  save 镜像名称:标签  -o 备份镜像名称.tar | 备份镜像为tar包 |
| docker  load -i  备份镜像名称 | 导入备份的镜像文件 |
| docker  rmi  镜像名称:标签 | 删除镜像（必须先删除该镜像启动的所有容器） |
| docker  history  镜像名称:标签 | 查看镜像的制作历史 |
| docker  inspect  镜像名称:标签 | 查看镜像的详细信息 |
| docker  tag  镜像名称:标签  新的镜像名称:新的标签 | 创建新的镜像名称和标签 |

导入 centos  nginx  redis  ubuntu 四个镜像到 node 节点(使用 lftp 或 scp 均可)

镜像素材在云盘的 kubernetes/docker-images/ 目录下

```shell
# 依照上面方法依次导入 nginx.tar.gz redis.tar.gz ubuntu.tar.gz
[root@node-0001 ~]# docker load -i centos.tar.gz

# 查看镜像
[root@node-0001 ~]# docker images

# 备份镜像 centos 到 tar 包
[root@node-0001 ~]# docker save centos:latest -o centos.tar

# 删除镜像，不能删除已经创建容器的镜像
[root@node-0001 ~]# docker rmi ubuntu:latest

# 查看镜像的详细信息
[root@node-0001 ~]# docker inspect centos:latest

# 查看镜像的历史信息
[root@node-0001 ~]# docker history nginx:latest

# 给镜像添加新的名词和标签
[root@node-0001 ~]# docker tag ubuntu:latest newname:newtag

# ----------------------以下操作必须在一台可以访问互联网的机器上执行---------------------------
# 搜索镜像
[root@node-0001 ~]# docker search busybox

# 下载镜像
[root@node-0001 ~]# docker pull busybox
```

#### docker容器管理命令

| 容器管理命令                                | 说明                                            |
| ------------------------------------------- | ----------------------------------------------- |
| docker  run  -it(d) 镜像名称:标签  启动命令 | 创建启动并进入一个容器，后台容器使用参数 d      |
| docker  ps                                  | 查看容器 -a 所有容器，包含未启动的，-q 只显示id |
| docker  rm  容器ID                          | -f 强制删除，支持命令重入                       |
| docker  start\|stop\|restart  容器id        | 启动、停止、重启容器                            |
| docker  cp  本机文件路径  容器id:容器内路径 | 把本机文件拷贝到容器内（上传）                  |
| docker  cp  容器id:容器内路径  本机文件路径 | 把容器内文件拷贝到本机（下载）                  |
| docker  inspect  容器ID                     | 查看容器的详细信息                              |
| docker  attach  容器id                      | 进入容器的默认进程，退出后容器会关闭            |
| docker  attach  容器id  [ctrl+p, ctrl+q]    | 进入容器以后，退出容器而不关闭容器的方法        |
| docker  exec  -it  容器id  启动命令         | 进入容器新的进程，退出后容器不会关闭            |

**docker run** 启动一个新的容器

​         -i 交互式，-t 终端， -d 在后台启动

```shell
# 在后台启动容器
[root@node-0001 ~]# docker run -itd nginx:latest 
9cae0af944d81770c90fdeacf7a632aaa749b0c9fbc0f4cb104e1d1257579e5e
# 在前台启动容器
[root@node-0001 ~]# docker run -it --name myos centos:latest /bin/bash
[root@de46e6254efd /]# ctrl+p, ctrl+q # 使用快捷键退出，保证容器不关闭

# 查看容器
[root@node-0001 ~]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED
de46e6254efd        centos:latest       "/bin/bash"              2 minutes ago  
9cae0af944d8        nginx:latest        "nginx -g 'daemon of…"   7 minutes ago  
# 只查看id
[root@node-0001 ~]# docker ps -q
# 查看所有容器，包含未启动的
[root@node-0001 ~]# docker ps -a

# 进入容器的默认进程
[root@node-0001 ~]# docker attach de46e6254efd
[root@de46e6254efd /]# exit # 退出后容器会关闭

# 启动、停止、重启容器
[root@node-0001 ~]# docker start   de46e6254efd
[root@node-0001 ~]# docker stop    9cae0af944d8
[root@node-0001 ~]# docker restart 9cae0af944d8

# 查看容器详细信息
[root@node-0001 ~]# docker inspect 9cae0af944d8
... ...
      "IPAddress": "172.17.0.2",
... ...
[root@node-0001 ~]# curl http://172.17.0.2/

# 进入容器，查看路径
[root@node-0001 ~]# docker exec -it 9cae0af944d8 /bin/bash
root@9cae0af944d8:/# cat /etc/nginx/conf.d/default.conf
... ...
      root   /usr/share/nginx/html;
... ...

# 从容器内拷贝首页文件到宿主机，修改后拷贝回容器内
[root@node-0001 ~]# docker cp 9cae0af944d8:/usr/share/nginx/html/index.html ./index.html
[root@node-0001 ~]# vim index.html
Hello Tedu
Hello Tedu
Hello Tedu
[root@node-0001 ~]# docker cp ./index.html 9cae0af944d8:/usr/share/nginx/html/index.html
[root@node-0001 ~]# curl http://172.17.0.2/

# 删除容器
[root@node-0001 ~]# docker rm -f de46e6254efd
# 删除所有容器
[root@node-0001 ~]# docker rm -f $(docker ps -aq)
```

总结：

​    管理镜像使用   **名称:标签**

​    管理容器使用   **容器ID**