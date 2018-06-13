---
title: "Kubernetes 的奇技淫巧"
subtitle: "打造高效的命令行终端"
date: 2018-06-11T04:35:48Z
draft: false
categories: "kubernetes"
tags: ["kubernetes"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/kubernetes4.png"}]
---

<!--more-->

Kubernetes 作为云原生时代的“操作系统”，熟悉和是用它是每名用户（User）的必备技能。如果你正在 Kubernetes 上工作，你需要正确的工具和技巧来确保 Kubernetes 集群的高可用以及工作负载的稳定运行。

随着 Kubernetes 的发展和演变，人们可以从内部来驯服它的无节制行为。但有些人并不情愿干等 Kubernetes 变得易于使用，并且为已投入生产的 Kubernetes 中遇到的很多常见问题制定了自己的解决方案。

这里我们将介绍一些提高操作效率的技巧，同时列举几个比较有用的开源 Kubernetes 工具，这些工具以各种方式简化 Kubernetes，包括简化命令行交互，简化应用程序部署语法等。

## kubectl 自动补全 

`kubectl` 这个命令行工具非常重要，与之相关的命令也很多，我们也记不住那么多的命令，而且也会经常写错，所以命令自动补全是很有必要的，kubectl 工具本身就支持自动补全，只需简单设置一下即可。

### bash 用户
大多数用户的 shell 使用的是 `bash`，Linux 系统可以通过下面的命令来设置：

```bash
$ echo "source <(kubectl completion bash)" >> ~/.bashrc
$ source ~/.bashrc
```

如果发现不能自动补全，可以尝试安装 `bash-completion` 然后刷新即可！

### zsh 用户

如果你使用的 shell 是 `zsh`，可以通过下面的命令来设置：

```bash
$ echo "source <(kubectl completion zsh)" >> ~/.zshrc
$ source ~/.zshrc
```

<br />

## 自定义 kubectl get 输出

`kubectl get` 相关资源，默认输出为 kubectl 内置，一般我们也可以使用 `-o json` 或者 `-o yaml` 查看其完整的资源信息。但是很多时候，我们需要关心的信息并不全面，因此我们需要自定义输出的列，那么可以使用 `go-template` 来进行实现。

`go-template` 是 golang 的一种模板，可以参考 [template的相关说明](https://golang.org/pkg/text/template/)。

比如仅仅想要查看获取的 pods 中的各个 pod 的 `uid`，则可以使用以下命令：

```bash
$ kubectl get pods --all-namespaces -o go-template='{{range .items}}{{.metadata.uid}}
{{end}}'

2ea418d4-533e-11e8-b722-005056a1bc83
7178b8bf-4e93-11e8-8175-005056a1bc83
a0341475-5338-11e8-b722-005056a1bc83
...
```

```yaml
$ kubectl get pods -o yaml

apiVersion: v1
items:
- apiVersion: v1
  kind: Pod
  metadata:
    name: nginx-deployment-1751389443-26gbm
    namespace: default
    uid: a911e34b-f445-11e7-9cda-40f2e9b98448
  ...
- apiVersion: v1
  kind: Pod
  metadata:
    name: nginx-deployment-1751389443-rsbkc
    namespace: default
    uid: a911d2d2-f445-11e7-9cda-40f2e9b98448
  ...
- apiVersion: v1
  kind: Pod
  metadata:
    name: nginx-deployment-1751389443-sdbkx
    namespace: default
    uid: a911da1a-f445-11e7-9cda-40f2e9b98448
    ...
kind: List
metadata: {}
resourceVersion: ""
```

因为 get pods 的返回结果是 `List` 类型，获取的 pods 都在 `items` 这个的 value 中，因此需要遍历 items，也就有了 `{{range .items}}`。而后通过模板选定需要展示的内容，就是 items 中的每个 `{{.metadata.uid}}`。

这里特别注意，要做一个特别的处理，就是要把 `{{end}}` 前进行换行，以便在模板中插入换行符。

当然，如果觉得这样处理不优雅的话，也可以使用 `printf` 函数，在其中使用 `\n` 即可实现换行符的插入。

```bash
$ kubectl get pods --all-namespaces -o go-template --template='{{range .items}}{{printf "%s\n" .metadata.uid}}{{end}}'
```

或者可以这样：

```bash
$ kubectl get pods --all-namespaces -o go-template --template='{{range .items}}{{.metadata.uid}}{{"\n"}}{{end}}'
```

其实有了 `printf`，就可以很容易的实现对应字段的输出，且样式可以进行自己控制。比如可以这样

```bash
$ kubectl get pods --all-namespaces -o go-template --template='{{range .items}}{{printf "|%-20s|%-50s|%-30s|\n" .metadata.namespace .metadata.name .metadata.uid}}{{end}}'

|default             |details-v1-64b86cd49-85vks                        |2e7a2a66-533e-11e8-b722-005056a1bc83|
|default             |productpage-v1-84f77f8747-7tkwb                   |2eb4e840-533e-11e8-b722-005056a1bc83|
|default             |ratings-v1-5f46655b57-qlrxp                       |2e89f981-533e-11e8-b722-005056a1bc83|
...
```

下面举两个 go-template 高级用法的例子：

+ range 嵌套

```bash
# 列出所有容器使用的镜像名
$ kubectl get pods --all-namespaces -o go-template --template='{{range .items}}{{range .spec.containers}}{{printf "%s\n" .image}}{{end}}{{end}}'

istio/examples-bookinfo-details-v1:1.5.0
istio/examples-bookinfo-productpage-v1:1.5.0
istio/examples-bookinfo-ratings-v1:1.5.0
...
```

+ 条件判断

```bash
# 列出所有不可调度节点的节点名与 IP
$ kubectl get no -o go-template='{{range .items}}{{if .spec.unschedulable}}{{.metadata.name}} {{.spec.externalID}}{{"\n"}}{{end}}{{end}}'
```

除了使用 `go-template` 之外，还可以使用逗号分隔的自定义列列表打印表格：

```bash
$ kubectl -n kube-system get pods coredns-64b597b598-7547d -o custom-columns=NAME:.metadata.name,hostip:.status.hostIP

NAME                       hostip
coredns-64b597b598-7547d   192.168.123.250
```

也可以使用 `go-template-file` 自定义模板列表，模板不用通过参数传进去，而是写成一个文件，然后需要指定 `template` 指向该文件即可。

```bash
$ cat > test.tmpl << EOF 
NAME                      HOSTIP
metadata.name       status.hostIP
EOF

$ kubectl -n kube-system get pods coredns-64b597b598-7547d -o custom-columns-file=test.tmpl

NAME                       HOSTIP
coredns-64b597b598-7547d   192.168.123.250
```

<br />

## [Kube-prompt](https://github.com/c-bata/kube-prompt)：交互式 Kubernetes 客户端

`Kube-prompt` 可以让你在 Kubernetes 客户端输入相当于交互式命令会话的东西，并为每个命令提供自动填充的背景信息，你不必键入 kubectl 来为每个命令添加前缀。

![](http://o7z41ciog.bkt.clouddn.com/kube-prompt.gif)

<br />

## [Kubectl Aliases](https://github.com/ahmetb/kubectl-aliases)：生成 kubectl 别名

如果你需要频繁地使用 kubectl 和 kubernetes api 进行交互，使用别名将会为你节省大量的时间，开源项目 [kubectl-aliases](https://github.com/ahmetb/kubectl-aliases) 可以通过编程的方式生成 kubectl 别名，别名生成规则如下：

![](http://o7z41ciog.bkt.clouddn.com/kubectl-alias.jpeg)

+ 简单别名示例

> <font color=red>kd</font> → <font color=red>k</font>ubectl <font color=red>d</font>escribe

+ 高级别名示例

> <font color=red>kgdepallw</font> → <font color=red>k</font>ubectl <font color=red>g</font>et <font color=red>dep</font>loyment --<font color=red>all</font>-namespaces --<font color=red>w</font>atch

<br />

## [Kubeval](https://github.com/garethr/kubeval)：校验配置文件

如果你手动写 Kubernetes manifest 文件，检查 manifest 文件的语法是很困难的，特别是当你有多个不同版本的 Kubernetes 集群时，确认配置文件语法是否正确更是难上加难。

[Kubeval](https://github.com/garethr/kubeval) 是一个用于校验Kubernetes YAML或JSON配置文件的工具，支持多个Kubernetes版本，可以帮助我们解决不少的麻烦。

+ 使用示例

```bash
$ kubeval nginx.yaml

The document nginx.yaml contains an invalid Deployment
---> spec.replicas: Invalid type. Expected: integer, given: string
```

<br />

## [Kedge](http://kedgeproject.org/)：简化 Kubernetes 部署定义

很多人都抱怨 Kubernetes manifest 文件的定义太复杂和冗长。它们很难写，而且很难维护，如果能够简化部署定义就会极大地降低维护难度。

[Kedge](http://kedgeproject.org/) 提供更简单、更简洁的语法，然后 kedge 将其转换为 Kubernetes manifest 文件。

+ 使用示例

```yaml
# Web server Kedge example
name: httpd
deployments:
- containers:
  - image: centos/httpd
services:
- name: httpd
  type: LoadBalancer
  portMappings: 
    - 8080:80
```

```yaml
# Converted Kubernetes artifact file(s)
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: httpd
  name: httpd
spec:
  ports:
  - name: httpd-8080
    port: 8080
    protocol: TCP
    targetPort: 80
  selector:
    app: httpd
  type: LoadBalancer
status:
  loadBalancer: {}
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: httpd
  name: httpd
spec:
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: httpd
      name: httpd
    spec:
      containers:
      - image: centos/httpd
        name: httpd
        resources: {}
status: {}
```

<br />

## 参考

----

+ [为高效 Ops 和 SRE 团队准备的 10 个开源 k8s 工具](https://segmentfault.com/a/1190000014526263?utm_source=tag-newest)
+ [打造高效的Kubernetes命令行终端](https://jimmysong.io/posts/configuring-efficient-kubernetes-cli-terminal/)

<br />

<style>
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