---
title: "Kubernetes API 扩展"
subtitle: "使用聚合层扩展 Kubernetes API"
date: 2018-06-19T06:15:06Z
draft: false
toc: true
categories: "kubernetes"
tags: ["kubernetes"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->

`Aggregated（聚合的）API server` 是为了将原来的 API server 这个巨石（monolithic）应用给拆分开，为了方便用户开发自己的 API server 集成进来，而不用直接修改 Kubernetes 官方仓库的代码，这样一来也能将 API server 解耦，方便用户使用实验特性。这些 API server 可以跟 `core API server` 无缝衔接，使用 kubectl 也可以管理它们。

在 `1.7+` 版本中，聚合层和 kube-apiserver 一起运行。在扩展资源被注册前，聚合层不执行任何操，要注册其 API,用户必需添加一个 `APIService` 对象，该对象需在 Kubernetes API 中声明 URL 路径，聚合层将发送到该 API 路径(e.g. /apis/myextension.mycompany.io/v1/…)的所有对象代理到注册的 APIService。

通常，通过在集群中的一个 Pod 中运行一个 `extension-apiserver` 来实现 APIService。如果已添加的资源需要主动管理，这个 extension-apiserver 通常需要和一个或多个控制器配对。

## 1. 创建聚合层 API 证书

----

如果想开启聚合层 API，需要创建几个与聚合层 API 相关的证书。

### 安装 cfssl

**方式一：直接使用二进制源码包安装**

```bash
$ wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
$ chmod +x cfssl_linux-amd64
$ mv cfssl_linux-amd64 /usr/local/bin/cfssl

$ wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
$ chmod +x cfssljson_linux-amd64
$ mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

$ wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
$ chmod +x cfssl-certinfo_linux-amd64
$ mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo

$ export PATH=/usr/local/bin:$PATH
```

**方式二：使用go命令安装**

```bash
$ go get -u github.com/cloudflare/cfssl/cmd/...
$ls $GOPATH/bin/cfssl*
cfssl cfssl-bundle cfssl-certinfo cfssljson cfssl-newkey cfssl-scan
```

在 `$GOPATH/bin` 目录下得到以 cfssl 开头的几个命令。

注意：以下文章中出现的 cat 的文件名如果不存在需要手工创建。

### 创建 CA (Certificate Authority)

**创建 CA 配置文件**

```bash
$ mkdir /root/ssl
$ cd /root/ssl
$ cfssl print-defaults config > config.json
$ cfssl print-defaults csr > csr.json
# 根据config.json文件的格式创建如下的ca-config.json文件
# 过期时间设置成了 87600h
$ cat > aggregator-ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "aggregator": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
```

字段说明：

+ `profiles` : 可以定义多个 profiles，分别指定不同的过期时间、使用场景等参数；后续在签名证书时使用某个 profile。
+ `signing` ：表示该证书可用于签名其它证书；生成的 aggregator-ca.pem 证书中 `CA=TRUE`。
+ `server auth` ：表示 Client 可以用该 CA 对 Server 提供的证书进行验证。
+ `client auth` ：表示 Server 可以用该 CA 对 Client 提供的证书进行验证。

**创建 CA 证书签名请求**

创建 `aggregator-ca-csr.json` 文件，内容如下：

```json
{
  "CN": "aggregator",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Shanghai",
      "L": "Shanghai",
      "O": "k8s",
      "OU": "System"
    }
  ],
    "ca": {
       "expiry": "87600h"
    }
}
```

字段说明：

+ <span id="inline-blue">"CN"</span> ：`Common Name`，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)；浏览器使用该字段验证网站是否合法。
+ <span id="inline-blue">"O"</span> ：`Organization`，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)；

**生成 CA 证书和私钥**

```bash
$ cfssl gencert -initca aggregator-ca-csr.json | cfssljson -bare aggregator-ca
$ ls aggregator-ca*
aggregator-ca-config.json  aggregator-ca.csr  aggregator-ca-csr.json  aggregator-ca-key.pem  aggregator-ca.pem
```

### 创建 kubernetes 证书

创建 aggregator 证书签名请求文件 `aggregator-csr.json` ：

```json
{
    "CN": "aggregator",
    "hosts": [
      "127.0.0.1",
      "192.168.123.250",
      "192.168.123.248",
      "192.168.123.249",
      "10.254.0.1",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Shanghai",
            "L": "Shanghai",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
```

+ 如果 hosts 字段不为空则需要指定授权使用该证书的 IP 或域名列表，由于该证书后续被 etcd 集群和 kubernetes master 集群使用，所以上面分别指定了 `etcd` 集群、`kubernetes master` 集群的主机 IP 和 kubernetes 服务的服务 IP（一般是 kube-apiserver 指定的 `service-cluster-ip-range` 网段的第一个 IP，如 10.254.0.1）。
+ 以上物理节点的 IP 也可以更换为主机名。

**生成 aggregator 证书和私钥**

```bash
$ cfssl gencert -ca=aggregator-ca.pem -ca-key=aggregator-ca-key.pem -config=aggregator-ca-config.json -profile=aggregator aggregator-csr.json | cfssljson -bare aggregator
$ ls aggregator*
aggregator.csr  aggregator-csr.json  aggregator-key.pem  aggregator.pem
```

### 分发证书

将生成的证书和秘钥文件（后缀名为.pem）拷贝到 Master 节点的 `/etc/kubernetes/ssl` 目录下备用。

```bash
$ cp *.pem /etc/kubernetes/ssl
```

## 2. 开启聚合层 API

----

`kube-apiserver` 增加以下配置：

```bash
--requestheader-client-ca-file=/etc/kubernetes/ssl/aggregator-ca.pem
--requestheader-allowed-names=aggregator
--requestheader-extra-headers-prefix=X-Remote-Extra-
--requestheader-group-headers=X-Remote-Group
--requestheader-username-headers=X-Remote-User
--proxy-client-cert-file=/etc/kubernetes/ssl/aggregator.pem
--proxy-client-key-file=/etc/kubernetes/ssl/aggregator-key.pem
```

<div id="note">
<p id="note-title">Note</p>
<br />
<p>前面创建的证书的 <code>CN</code> 字段的值必须和参数 <code>--requestheader-allowed-names</code> 指定的值 <code>aggregator</code> 相同。</p>
</div>

重启 kube-apiserver：

```bash
$ systemctl daemon-reload
$ systemctl restart kube-apiserver
```

如果 `kube-proxy` 没有在 Master 上面运行，`kube-proxy` 还需要添加配置：

```bash
--enable-aggregator-routing=true
```

## 3. 参考

----

+ [Extending the Kubernetes API with the aggregation layer](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/apiserver-aggregation/)
+ [Configure the aggregation layer](https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/)
+ [创建TLS证书和秘钥](https://jimmysong.io/kubernetes-handbook/practice/create-tls-and-secret-key.html)

<style>
a:hover{cursor:url(http://hugo-picture.oss-cn-beijing.aliyuncs.com/cursor_5.png), pointer;}
body {
    cursor: url(http://hugo-picture.oss-cn-beijing.aliyuncs.com/cursor_1.png), default;
}
h1,h2,h3,h4,h5,h6 {
    font-family: 'Open Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
    font-weight: 800;
    margin-top: 35px;
}
h2 {
    display: block;
    font-size: 1.5em;
    margin-block-start: 0.83em;
    margin-block-end: 0.83em;
    margin-inline-start: 0px;
    margin-inline-end: 0px;
    font-weight: bold;
}
h2::before {
    content: "#";
    margin-right: 5px;
    color: #2d96bd;
}
h3 {
    color: #0099CC;
}
h4 {
    color: #F77A0B;
}
li {
    line-height: 2;
    font-size: 0.9em;
}
blockquote {
    padding: 10px 20px;
    margin: 0 0 20px;
    font-size: 16px;
    border-left: 5px solid #986dbd;
}
#h2{
    margin-bottom:2em;
    margin-right: 5px;
    padding: 8px 15px;
    letter-spacing: 2px;
    background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181));
    background-color: rgb(63, 81, 181);
    color: rgb(255, 255, 255);
    border-left: 10px solid rgb(51, 51, 51);
    border-radius:5px;
    text-shadow: rgb(102, 102, 102) 1px 1px 1px;
    box-shadow: rgb(102, 102, 102) 1px 1px 2px;
}
#note {
    font-size: 1.5rem;
    font-style: italic;
    padding: 0 1rem;
    margin: 2.5rem 0;
    position: relative;
    background-color: #fafeff;
    border-top: 1px dotted #9954bb;
    border-bottom: 1px dotted #9954bb;
}
#note-title {
    padding: 0.2rem 0.5rem;
    background: #9954bb;
    color: #FFF;
    position: absolute;
    left: 0;
    top: 0.25rem;
    box-shadow: 0 2px 4px rgba(0,0,0,0.2);
    border-radius: 4px;
    -webkit-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    -moz-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    -ms-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    -o-transform: rotate(-5deg) translateX(-10px) translateY(-25px);
    transform: rotate(-5deg) translateX(-10px) translateY(-25px);
}
#inline-yellow {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #f0ad4e;
}
#inline-green {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #5cb85c;
}
#inline-blue {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #2780e3;
}
#inline-purple {
display:inline;
padding:.2em .6em .3em;
font-size:80%;
font-weight:bold;
line-height:1;
color:#fff;
text-align:center;
white-space:nowrap;
vertical-align:baseline;
border-radius:0;
background-color: #9954bb;
}
#div-border-left-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #df3e3e;
}
#div-border-left-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #f0ad4e;
}
#div-border-left-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #5cb85c;
}
#div-border-left-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #2780e3;
}
#div-border-left-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-left-width: 5px;
border-radius: 3px;
border-left-color: #9954bb;
}
#div-border-right-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #df3e3e;
}
#div-border-right-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #f0ad4e;
}
#div-border-right-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #5cb85c;
}
#div-border-right-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #2780e3;
}
#div-border-right-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-right-width: 5px;
border-radius: 3px;
border-right-color: #9954bb;
}
#div-border-top-red {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #df3e3e;
}
#div-border-top-yellow {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #f0ad4e;
}
#div-border-top-green {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #5cb85c;
}
#div-border-top-blue {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #2780e3;
}
#div-border-top-purple {
display: block;
padding: 10px;
margin: 10px 0;
border: 1px solid #ccc;
border-top-width: 5px;
border-radius: 3px;
border-top-color: #9954bb;
}
</style>
