---
title: "初试 Kubernetes 集群中使用 Contour 反向代理"
date: 2018-09-28T16:38:15+08:00
subtitle: "一种全新的 Ingress 实现方式——Envoy"
draft: false
toc: true
categories: "kubernetes"
tags: ["envoy", "kubernetes"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

在 Kubernetes 中运行大规模以 Web 为中心的工作负载，最关键的需求之一就是在 `L7` 层实现高效流畅的入口流量管理。自从第一批 `Kubernetes Ingress Controller` 开发完成以来，`Envoy`（由 Matt Klein 和 Lyft 团队开发）已经成为云原生生态系统中的新生力量。Envoy 之所以受到支持，因为它是一个 CNCF 托管的项目，与整个容器圈和云原生架构有着天然的支持。

容器公司 [Heptio](https://heptio.com/) 开源的项目 [Contour](https://github.com/heptio/contour) 使用 `Envoy` 作为 Kubernetes 的 Ingress Controller 实现，为大家提供了一条新的 Kubernetes 外部负载均衡实现思路。

据[官方博客](https://blog.heptio.com/making-it-easy-to-use-envoy-as-a-kubernetes-load-balancer-dde82959f171)介绍，`Heptio Contour` 可以为用户提供以下好处：

+ 一种简单的安装机制来快速部署和集成 Envoy。
+ 与 Kubernetes 对象模型的集成。
+ `Ingress` 配置的动态更新，而无需重启底层负载均衡器。
+ 项目成熟后，将允许使用 Envoy 一些强大的功能，如熔断器、插件式的处理器链，以及可观测性和可调试性。

下面我们就来试用一下。

## 1. 安装步骤

----

首先克隆官方仓库，进入 manifest 清单目录：

```bash
$ git clone https://github.com/heptio/contour
$ cd contour/deployment/deployment-grpc-v2
```

修改 `Deployment` YAML 文件：

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app: contour
  name: contour
  namespace: heptio-contour
spec:
  selector:
    matchLabels:
      app: contour
  replicas: 1
  template:
    metadata:
      labels:
        app: contour
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9001"
        prometheus.io/path: "/stats"
        prometheus.io/format: "prometheus"
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/hostname
                operator: In
                values:
                - "192.168.123.249"
      hostNetwork: true
      containers:
      - image: gcr.io/heptio-images/contour:master
        imagePullPolicy: Always
        name: contour
        command: ["contour"]
        args:
        - serve
        - --incluster
        - --envoy-http-port=80
        - --envoy-https-port=443
      - image: docker.io/envoyproxy/envoy-alpine:v1.7.0
        name: envoy
        ports:
        - containerPort: 80
          name: http
        - containerPort: 443
          name: https
        command: ["envoy"]
        args:
        - --config-path /config/contour.yaml
        - --service-cluster cluster0
        - --service-node node0
        - --log-level info
        - --v2-config-only
        volumeMounts:
        - name: contour-config
          mountPath: /config
      initContainers:
      - image: gcr.io/heptio-images/contour:master
        imagePullPolicy: Always
        name: envoy-initconfig
        command: ["contour"]
        args: ["bootstrap", "/config/contour.yaml"]
        volumeMounts:
        - name: contour-config
          mountPath: /config
      volumes:
      - name: contour-config
        emptyDir: {}
      dnsPolicy: ClusterFirst
      serviceAccountName: contour
      terminationGracePeriodSeconds: 30
```

总共修改以下几处：

1. 将实例数修改为 1。
2. 将网络模式改为 `hostNetwork`。
3. 删除 Pod 反亲和性配置，添加 Node 亲和性配置，调度到指定的节点。
4. 修改 contour 启动参数，将 `Listener` 端口改为 80 和 443。
5. 将 Envoy 容器的暴露端口改为 80 和 443。

部署：

```bash
$ kubectl apply -f ./

namespace "heptio-contour" created
serviceaccount "contour" created
customresourcedefinition.apiextensions.k8s.io "ingressroutes.contour.heptio.com" created
deployment.extensions "contour" created
clusterrolebinding.rbac.authorization.k8s.io "contour" created
clusterrole.rbac.authorization.k8s.io "contour" created
service "contour" created
```

## 2. Ingress 测试

----

安装结束后，我们就可以来测试 Ingress 了。在 `deployment` 目录下包含一个示例应用，可以直接使用：

```bash
$ kubectl apply -f ../example-workload/kuard.yaml
```

查看创建好的资源：

```bash
$ kubectl get po,svc,ing -l app=kuard

NAME                       READY     STATUS    RESTARTS   AGE
kuard-bcc7bf7df-6h55x      1/1       Running   0          4m
kuard-bcc7bf7df-9sdnr      1/1       Running   0          4m
kuard-bcc7bf7df-ws57j      1/1       Running   0          4m

NAME        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
svc/kuard   10.254.85.181   <none>        80/TCP    4m

NAME        HOSTS     ADDRESS           PORTS     AGE
ing/kuard   *         192.168.123.249   80        4m
```

现在在浏览器中输入 Contour 运行节点的 IP 地址或 DNS 域名来访问示例应用程序了。

<center>![](http://o7z41ciog.bkt.clouddn.com/kuard.jpg)</center>

## 3. Contour 工作原理

----

Contour 同时支持 `Ingress` 资源对象和 `IngressRoute` 资源对象（通过 CRD 创建），这些对象都是为进入集群的请求提供路由规则的集合。这两个对象的结构和实现方式有所不同，但它们的核心意图是相同的，都是为进入集群的请求提供路由规则。如不作特殊说明，后面当我们描述 “Ingress” 时，它将同时适用于 `Ingress` 和 `IngressRoute` 对象。

通常情况下，当 Envoy 配置了 `CDS` 端点时，它会定期轮询端点，然后将返回的 JSON 片段合并到其运行配置中。如果返回到 Envoy 的集群配置代表当前的 Ingress 对象的集合，则可以将 Contour 视为从 `Ingress` 对象到 `Envoy` 集群配置的转换器。随着 Ingress 对象的添加和删除，Envoy 会动态添加并删除相关配置，而无需不断重新加载配置。

在实践中，将 Ingress 对象转换为 Envoy 配置更加微妙，需要将 Envoy 中的 xDS 配置（包括 `CDS`，`SDS` 和 `RDS`）映射到 Kubernetes 中。Contour 至少需要观察 `Ingress`、`Service` 和 `Endpoint` 这几个资源对象以构建这些服务的响应，它通过 `client-go` 的 [cache/informer](https://www.kubernetes.org.cn/2693.html) 机制免费获得这些 `watchers`。这些机制提供添加，更新和删除对象的边缘触发通知，以及通过 `watch API` 执行查询对象的本地缓存的列表机制。

Contour 将收集到的这些对象处理为虚拟主机及其路由规则的**有向非循环图**（DAG），这表明 Contour 将有权构建路由规则的顶级视图，并将群集中的相应服务和TLS秘钥连接在一起。一旦构建了这个新的数据结构，我们就可以轻松实现 `IngressRoute` 对象的验证，授权和分发。改数据结构导出的 `png` 图片如下图所示：

<center>![](http://o7z41ciog.bkt.clouddn.com/dag.png)</center>

Envoy API 调用和 Kubernetes API 资源之间的映射关系如下：

+ <span id="inline-blue">CDS</span> : 集群发现服务。映射为 Kubernetes 中的 `Service` 以及一部分 Ingress 对象的 `TLS` 配置。

+ <span id="inline-blue">SDS</span> : 服务发现服务。映射为 Kubernetes 中的 `Endpoint`。Envoy 使用 SDS 自动获取 `Cluster` 成员，这与 Endpoint 对象中包含的信息非常匹配。Envoy 使用 Contour 在 `CDS` 响应中返回的名称查询 `SDS`。

+ <span id="inline-blue">RDS</span> : 路由发现服务。映射为 Kubernetes 中的 `Ingress`。提供了虚拟主机名和前缀路由信息的 RDS 与 Ingress 匹配得更好。

## 4. 映射关系详情

----

### CDS

`CDS` 更像是 Kubernetes 中的 `Service` 资源，因为 Service 是具体 `Endpoint`（Pods）的抽象，Envoy Cluster 是指 Envoy 连接到的一组逻辑上相似的上游主机（参考下文的 RDS）。其中 `TLS` 配置也是 CDS 的一部分，而 Kubernetes 中的 TLS 信息由 Ingress 提供，所以这部分之间的映射关系会有些复杂。

### SDS

`SDS` 更像是 Kubernetes 中的 `Endpoint` 资源，这部分映射关系的实现最简单。Contour 将 Endpoint 的响应对象转换为 SDS 的 `{ hosts: [] }` json 配置块。

### RDS

`RDS` 更像是 Kubernetes 中的 `Ingress` 资源。RDS 将前缀，路径或正则表达式之一路由到 Envoy 群集。Envoy 集群的名称可以从 Ingress 的 `IngressSpec` 的配置项中获取（比如：`namespace/serviceName_servicePort`），因为这是一个选择器，它会匹配 Service 对象被转换后返回的 CDS 对象。

## 5. Contour 架构分析

----

Contour Ingress controller 由两个组件组成：

+ `Envoy` : 提供高性能反向代理。
+ `Contour` : 充当 Envoy 的控制平面，为 Envoy 的路由配置提供统一的来源。

这些容器以 `Sidecar` 的形式部署在同一个 `Pod` 中，当然也包括了一些其他的配置。

在 Pod 初始化期间，Contour 作为 `Init` 容器运行，并将引导程序配置写入一个 temporary volume。该 `Volume` 被传递给 Envoy 容器并告诉 Envoy 将其 Sidecar Contour 容器视为控制平面。

初始化完成后，Envoy 容器启动，检索 Contour 写入的引导程序配置，并开始轮询 Contour 以热更新配置。如果控制平面无法访问，Envoy 将会进行优雅重试。

Contour 相当于 Kubernetes API 的客户端。它监视 `Ingress`，`Service` 和 `Endpoint` 对象，并通过将其对象缓存转换为相关的 `JSON` 字段来充当其 Envoy 的控制平面。

从 Kubernetes 到 Contour 的信息转换是通过 `SharedInformer` 框架 watching API 来完成的；而从 Contour 到 Envoy 的信息转换是通过 Envoy 定期轮询来实现的。

## 6. IngressRoute 介绍

----

[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) 对象从 Kubernetes 1.1 版本开始被引进，用来描述进入集群的请求的 HTTP 路由规则。但迄今为止 Ingress 对象还停留在 `beta` 阶段，不同的 Ingress Controller 插件为了添加 HTTP 路由的额外属性，只能通过添加大量的 `annotation` 来实现，而且每个插件的 annotation 都不一样，非常混乱。

`IngressRoute` CRD 的目标就是扩展 Ingress API 的功能，以便提供更丰富的用户体验以及解决原始设计中的缺点。

**目前 Contour 是唯一支持 IngressRoute CRD 的 Kubernetes Ingress Controller。**下面就来看看它与 Ingress 相比的优点：

+ 安全地支持多团队 Kubernetes 集群，能够限制哪些命名空间可以配置虚拟主机和 TLS 凭据。
+ 允许将路径或域名的路由配置分发给另一个命名空间。
+ 接受单个路由中的多个服务，并对它们之间的流量进行负载均衡。
+ 无需通过添加 `annotation` 就可以定义服务权重和负载均衡策略。
+ 在创建时验证 IngressRoute 对象，并为创建后报告验证是否有效。

### 从 Ingress 到 IngressRoute

一个基本的 `Ingress` 对象如下所示：

```yaml
# ingress.yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: basic
spec:
  rules:
  - host: foo-basic.bar.com
    http:
      paths:
      - backend:
          serviceName: s1
          servicePort: 80
```

这个 Ingress 对象名为 `basic`，它将传入的 HTTP 流量路由到头文件中 `Host:` 字段值为 `foo-basic.bar.com` 且端口为 80 的 `s1` 服务。该路由规则通过 `IngressRoute` 来实现如下：

```yaml
# ingressroute.yaml
apiVersion: contour.heptio.com/v1beta1
kind: IngressRoute
metadata:
  name: basic
spec:
  virtualhost:
    fqdn: foo-basic.bar.com
  routes:
    - match: /
      services:
        - name: s1
          port: 80
```

对应关系很简单，我就不再详细介绍了，更多功能配置可以参考官方仓库的文档：[IngressRoute](https://github.com/heptio/contour/blob/master/docs/ingressroute.md)。

### 可视化 Contour 的内部有向非循环图

Contour 使用 DAG 对其配置进行建模，可以通过以 <a href="https://en.wikipedia.org/wiki/DOT_(graph_description_language)" target="_blank">DOT</a> 格式输出 DAG 的调试端点对其进行可视化，当然需要先在系统中安装 `graphviz`：

```bash
$ yum install -y graphviz
```

下载图表并将其另存为 `PNG`：

```bash
# Port forward into the contour pod
$ CONTOUR_POD=$(kubectl -n heptio-contour get pod -l app=contour -o jsonpath='{.items[0].metadata.name}')
# Do the port forward to that pod
$ kubectl -n heptio-contour port-forward $CONTOUR_POD 6060
# Download and store the DAG in png format
$ curl localhost:6060/debug/dag | dot -T png > contour-dag.png
```

我自己保存的 PNG 图片如下所示：

<center>![](http://o7z41ciog.bkt.clouddn.com/contour-dag.png)</center>

## 7. 参考

----

+ [About Contour and Envoy](https://github.com/heptio/contour/blob/master/docs/about.md)
+ [Contour architecture](https://github.com/heptio/contour/blob/master/docs/architecture.md)
+ [Making it easy to use Envoy as a Kubernetes load balancer](https://blog.heptio.com/making-it-easy-to-use-envoy-as-a-kubernetes-load-balancer-dde82959f171)

----

<center>![](http://o7z41ciog.bkt.clouddn.com/qrcode_for_wechat_big.jpg)</center>
<center>扫一扫关注微信公众号</center>

<style>
a:hover{cursor:url(http://oqk3alhse.bkt.clouddn.com/cursor_5.png), pointer;}
body {
    cursor: url(http://oqk3alhse.bkt.clouddn.com/cursor_1.png), default;
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
#blockquote {
    padding: 10px 20px;
    margin: 0 0 20px;
    font-size: 16px;
    border-left: 5px solid #986dbd;
}
#red {
color: red;
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
