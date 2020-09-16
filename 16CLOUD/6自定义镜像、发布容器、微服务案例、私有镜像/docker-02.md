# 容器技术 -- 2

## 镜像管理

#### commit 打包镜像

docker  commit  容器id  新镜像名称:标签

```shell
[root@node-0001 ~]# docker run -it centos:latest
[root@02fd1719c038 ~]# rm -f /etc/yum.repos.d/*.repo
[root@02fd1719c038 ~]# curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.myhuaweicloud.com/repo/CentOS-Base-7.repo
[root@02fd1719c038 ~]# yum install -y net-tools vim-enhanced tree bash-completion iproute psmisc && yum clean all
[root@02fd1719c038 ~]# exit
[root@node-0001 ~]# docker commit 02fd1719c038 myos:latest
```

#### Dockerfile打包镜像

###### Dockerfile语法

| 语法指令 | 语法说明                              |
| -------- | ------------------------------------- |
| FROM     | 基础镜像                              |
| RUN      | 制作镜像时执行的命令，可以有多个      |
| ADD      | 复制文件到镜像，自动解压              |
| COPY     | 复制文件到镜像，不解压                |
| EXPOSE   | 声明开放的端口                        |
| ENV      | 设置容器启动后的环境变量              |
| WORKDIR  | 定义容器默认工作目录（等于cd）        |
| CMD      | 容器启动时执行的命令，仅可以有一条CMD |

###### 使用Dockerfile创建镜像

**docker  build  -t  镜像名称:标签  Dockerfile所在目录**

###### 制作 myos:python 镜像

```dockerfile
[root@node-0001 ~]# mkdir mybuild
[root@node-0001 ~]# cd mybuild
[root@node-0001 mybuild]# vim Dockerfile
FROM centos:latest
RUN  rm -f /etc/yum.repos.d/*.repo
COPY CentOS-Base.repo local.repo /etc/yum.repos.d/
RUN  yum install -y net-tools vim-enhanced tree bash-completion iproute psmisc && yum clean all
CMD  ["/usr/bin/python"]
[root@node-0001 mybuild]# cp /etc/yum.repos.d/CentOS-Base.repo.repo ./
[root@node-0001 mybuild]# docker build -t myos:python .
```

###### 制作apache镜像

CMD  指令可以查看 service 文件的启动命令 ExecStart（/lib/systemd/system/httpd.service）

ENV  环境变量查询服务文件中的环境变量配置文件 EnvironmentFile 指定的文件内容

```dockerfile
[root@node-0001 ~]# mkdir web; cd web
[root@node-0001 web]# vim Dockerfile
FROM myos:latest
RUN  yum install -y httpd php
ENV  LANG=C
ADD  webhome.tar.gz  /var/www/html/
WORKDIR /var/www/html/
EXPOSE 80
CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
# 拷贝 webhome.tar.gz 到当前目录中
[root@node-0001 web]# docker build -t myos:httpd .
```

查看与验证镜像

```shell
[root@node-0001 web]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
myos                httpd               db15034569da        12 seconds ago      412MB
myos                python              1739313b5b75        About an hour ago   281MB
myos                latest              867409e412c8        2 hours ago         281MB
[root@node-0001 web]# docker rm -f $(docker ps -aq)
[root@node-0001 web]# docker run -itd myos:httpd
[root@node-0001 web]# curl http://172.17.0.2/info.php
<pre>
Array
(
    [REMOTE_ADDR] => 172.17.0.1
    [REQUEST_METHOD] => GET
    [HTTP_USER_AGENT] => curl/7.29.0
    [REQUEST_URI] => /info.php
)
php_host: 	6c9e124bee1a
1229
```

###### 对外发布服务

给他 node-0001 绑定一个公网IP

docker  run  -itd  -p 宿主机端口:容器端口  镜像名称:标签

```shell
# 把 node-0001 变成 apache 服务
[root@node-0001 ~]# docker run -itd -p 80:80 myos:httpd

# 把 node-0001 变成 nginx 服务，首先必须停止 apache
[root@node-0001 ~]# docker stop $(docker ps -q)
[root@node-0001 ~]# docker run -itd -p 80:80 nginx:latest
```

验证方式： 通过浏览器访问即可

容器共享卷

docker  run  -itd  -v 宿主机对象:容器内对象  镜像名称:标签

```shell
[root@node-0001 ~]# docker rm -f $(docker ps -aq)
# 创建 apache 容器
[root@node-0001 ~]# docker run -itd --name webtest myos:httpd
# 创建目录，并拷贝 httpd.conf 配置文件
[root@node-0001 ~]# mkdir -p /var/{webroot,webconf}
[root@node-0001 ~]# docker cp webtest:/etc/httpd/conf/httpd.conf /var/webconf/
# 设置默认首页
[root@node-0001 ~]# echo "i am apache" >>/var/webroot/index.html
# 修改配置文件的监听端口
[root@node-0001 ~]# vim /var/webconf/httpd.conf
Listen 8080
# 启动容器，映射 80端口到8080，映射配置文件 /var/webconf/httpd.conf 映射数据目录 /var/webroot
[root@node-0001 ~]# docker run -itd -p 80:8080 \
                               -v /var/webconf/httpd.conf:/etc/httpd/conf/httpd.conf \
                               -v /var/webroot:/var/www/html myos:httpd
```

验证方式： 通过浏览器访问即可

###### 制作php-fpm镜像

```dockerfile
[root@node-0001 ~]# yum install -y php-fpm
[root@node-0001 ~]# mkdir php; cd php
[root@node-0001 php]# cp /etc/php-fpm.d/www.conf ./
12:  listen = 0.0.0.0:9000
24:  ;listen.allowed_clients = 127.0.0.1
# 拷贝云盘 kubernetes/docker-images/info.php 到当前目录
[root@node-0001 php]# vim Dockerfile
FROM myos:latest
RUN  yum install -y php-fpm
COPY www.conf /etc/php-fpm.d/www.conf
EXPOSE 9000
WORKDIR /usr/local/nginx/html
COPY info.php info.php
CMD ["/usr/sbin/php-fpm", "--nodaemonize"]
[root@node-0001 php]# docker build -t myos:php-fpm .
```

###### 制作nginx镜像

```dockerfile
[root@node-0001 ~]# yum install -y gcc make pcre-devel openssl-devel
[root@node-0001 ~]# useradd nginx
[root@node-0001 ~]# tar -zxvf nginx-1.12.2.tar.gz
[root@node-0001 ~]# cd nginx-1.12.2
[root@node-0001 nginx-1.12.2]# ./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_ssl_module
[root@node-0001 nginx-1.12.2]# make && make install
[root@node-0001 nginx-1.12.2]# cd /usr/local/
# 拷贝云盘 kubernetes/docker-images/info.html和info.php 到 nginx/html 目录下
[root@node-0001 local]# tar czf nginx.tar.gz nginx
[root@node-0001 local]# mkdir /root/nginx ;cd /root/nginx
[root@node-0001 nginx]# cp /usr/local/nginx.tar.gz ./
[root@node-0001 nginx]# vim Dockerfile 
FROM myos:latest
RUN  yum install -y pcre openssl && useradd nginx
ADD  nginx.tar.gz /usr/local/
EXPOSE 80
WORKDIR /usr/local/nginx/html
CMD  ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
[root@node-0001 nginx]# docker build -t myos:nginx .
```

#### 综合实验Nginx-PHP动静分离

###### 实验架构图例

```mermaid
graph LR
  subgraph node-0001
    style node-0001 color:#00ff00,fill:#7777ff
      subgraph 容器1
      style 容器1 color:#00ff00,fill:#88aaff
        APP1(Nginx)
        NET1{{共享网络}}
      end
      subgraph 容器2
      style 容器2 color:#00ff00,fill:#88aaff
        APP2(PHP)
      end
    APP1 --> NET1
    APP2 --> NET1
  L((共享存储卷))
  APP1 -.-> L
  APP2 -.-> L
  end
U((用户)) --> APP1
```

###### 实验步骤

```shell
[root@node-0001 ~]# mkdir -p /var/{webroot,webconf}
[root@node-0001 ~]# cp info.php  /var/webroot/
[root@node-0001 ~]# cp info.html /var/webroot/
[root@node-0001 ~]# cp /usr/local/nginx/conf/nginx.conf /var/webconf/
[root@node-0001 ~]# vim /var/webconf/nginx.conf
        location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            include        fastcgi.conf;
        }
[root@node-0001 ~]# docker run -itd --name nginx -p 80:80 \
                           -v /var/webconf/nginx.conf:/usr/local/nginx/conf/nginx.conf \
                           -v /var/webroot:/usr/local/nginx/html myos:nginx 
[root@node-0001 ~]# docker run -itd --network=container:nginx \
                           -v /var/webroot:/usr/local/nginx/html myos:php-fpm
# 验证服务
[root@node-0001 ~]# curl http://node-0001/info.html
<html>
  <marquee  behavior="alternate">
      <font size="12px" color=#00ff00>Hello World</font>
  </marquee>
</html>
[root@node-0001 ~]# curl http://node-0001/info.php
<pre>
Array
(
    [REMOTE_ADDR] => 172.17.0.1
    [REQUEST_METHOD] => GET
    [HTTP_USER_AGENT] => curl/7.29.0
    [REQUEST_URI] => /info.php
)
php_host: 	f705f89b45f9
1229
```



#### docker私有仓库

###### docker私有仓库图例

```mermaid
graph TB
  H1(容器服务器<br>node-0001)
  H2(容器服务器<br>node-0002)
  I{{镜像仓库}}
  style I fill:#77ff77
  H1 --> I
  H2 --> I
```

###### 私有仓库配置

| 主机名   | ip地址        | 最低配置    |
| -------- | ------------- | ----------- |
| registry | 192.168.1.100 | 1CPU,1G内存 |

```shell
[root@registry ~]# yum install -y docker-distribution
[root@registry ~]# systemctl enable --now docker-distribution
[root@registry ~]# curl http://192.168.1.100:5000/v2/_catalog
{"repositories":[]}
```

###### docker客户端配置

所有node节点都需要配置，这里 node-0001，node-0002都要配置

native.cgroupdriver   cgroup驱动，docker默认 cgroupfs

registry-mirrors          默认下载仓库，使用国内源能快一点

insecure-registries     私有仓库地址（重点）

```shell
[root@node-0001 ~]# vim /etc/docker/daemon.json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "registry-mirrors": ["https://hub-mirror.c.163.com"],
    "insecure-registries":["192.168.1.100:5000", "registry:5000"]
}
[root@node-0001 ~]# docker rm -f $(docker ps -aq)
[root@node-0001 ~]# systemctl restart docker
```

###### 上传镜像

```shell
# 上传 myos:latest, myos:httpd, myos:nginx, myos:php-fpm
[root@node-0001 ~]# docker tag myos:latest 192.168.1.100:5000/myos:latest
[root@node-0001 ~]# docker push 192.168.1.100:5000/myos:latest
```

###### 验证测试

curl http://仓库IP:5000/v2/_catalog

curl http://仓库IP:5000/v2/镜像名称/tags/list

```shell
[root@node-0002 ~]# curl http://192.168.1.100:5000/v2/_catalog
{"repositories":["myos"]}
[root@node-0002 ~]# curl http://192.168.1.100:5000/v2/myos/tags/list
{"name":"myos","tags":["latest"]}
# 使用远程镜像启动容器
[root@node-0002 ~]# docker run -it 192.168.1.100:5000/myos:latest
Unable to find image '192.168.1.100:5000/myos:latest' locally
latest: Pulling from myos
7dc0dca2b151: Pull complete 
95c297b4d705: Pull complete 
Digest: sha256:d61ffc053895e2dc16f63b8a2988dfe5f34207b48b1e74d397bb3267650ba4ce
Status: Downloaded newer image for 192.168.1.100:5000/myos:latest
[root@674ebe359e44 /]# 
```

