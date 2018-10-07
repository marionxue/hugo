---
title: "通过消除对特权容器的需求来提高 Istio Deployment 的安全性"
subtitle: "istio-pod-network-controller 介绍"
date: 2018-09-21T13:10:18+08:00
draft: false
categories: "service mesh"
tags: ["istio", "service mesh"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

<p id="div-border-left-red">原文链接：<a href="https://blog.openshift.com/increasing-security-of-istio-deployments-by-removing-the-need-for-privileged-containers/" target="_blank">Increasing Security of Istio Deployments by Removing the Need for Privileged Containers</a></p>

随着 1.0 版本的发布，`Istio` 正在为开发云原生应用并希望采用服务网格解决方案的公司准备黄金时间。但是，有一个潜在的问题可能会降低这些公司的采用率：服务网格内的 `Pod` 需要提升权限才能正常运行。

为了从一定程度上缓解这个问题，本文将介绍一个新的工具：[istio-pod-network-controller](https://github.com/sabre1041/istio-pod-network-controller).

### <p id="h2">1. 问题</p>

----

作为服务网格正常操作的一部分，Istio 需要操作 Pod 的 `iptables` 规则，以拦截所有的进出 Pod 的流量，并注入使 Istio 能够发挥作用的 `Sidecar`。由于 iptables 规则是针对网络命名空间操作的，所以在某个 Pod 中修改 iptables 规则不会影响到其他 Pod 或运行该 Pod 的节点。

`init` 容器是 Istio Pod 的一部分，负责在应用程序容器启动之前添加这些 iptables 规则。如果想在容器中操作 iptables 规则，必须通过开启 [NET_ADMIN capability](http://man7.org/linux/man-pages/man7/capabilities.7.html) 来提升操作权限。`NET_ADMIN` 是一种允许你重新配置网络的 [`Linux Capability`](http://man7.org/linux/man-pages/man7/capabilities.7.html)，这意味着具有该特权的 Pod 不仅可以将自身添加到 Istio 网格，还可以干扰其他 Pod 的网络配置以及节点本身的网络配置。但是在通常情况下，我们是不建议在共享租户的集群中运行具有此特权权限的应用程序 Pod 的。

`OpenShift` 提供了一种通过称为 [Security Context Context (SCC)](https://docs.openshift.com/container-platform/3.10/admin_guide/manage_scc.html) 的机制来控制 Pod 可以拥有的权限的方法（在本例中指的是 Linux Capabilities）。Openshift 中提供了一些开箱即用的 `SCC` 配置文件，集群管理员还可以添加更多自定义配置文件。允许正常运行 Istio 的唯一开箱即用的 `SCC` 配置文件是 `privileged` 配置文件。为了将某个命名空间中的 Pod 添加到 Istio 服务网格，必须执行以下命令才能访问 `privileged SCC`：

```bash
$ oc adm policy add-scc-to-user privileged -z default -n <target-namespace>
```

但是这样做本质上就为此命名空间中的所有 Pod 提供了 `root` 权限。而运行普通应用程序时，由于潜在的安全隐患，通常又不建议使用 root 权限。

虽然这个问题一直困扰着 Istio 社区，但迄今为止 Kubernetes 还没有提供一种机制来控制给予 Pod 的权限。从 [Kubernetes 1.11](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.11.md) 开始，[Pod 安全策略（PSP）](https://kubernetes.io/docs/concepts/policy/pod-security-policy/)功能已经作为 `beta feature` 引入，PSP 与 SCC 的功能类似。一旦其他 Kubernetes 发行版开始支持开箱即用的 PSP，Istio 网格中的 Pod 就需要提升权限才能正常运行。

### <p id="h2">2. 解决方案</p>

----

解决这个问题的一种方法是将配置 Pod 的 iptables 规则的逻辑移出 Pod 本身。该方案通过一个名叫 `istio-pod-network-controller` 的 DaemonSet 控制器，来监视新 Pod 的创建，并在创建后立即在这些新 Pod 中配置相应的 iptables 规则。下图描绘了该解决方案的整体架构：

<center>![](http://o7z41ciog.bkt.clouddn.com/istiograph.png)</center>

流程如下：

1. 创建一个新 Pod
2. 创建该 Pod 的节点上运行的 `istio-pod-network-controller` 检测新创建的 Pod 是否属于 Istio 网格，如果属于则对其进行初始化。
3. Pod 中的 init 容器等待初始化 `annotation` 出现，确保应用程序容器和 [Sidecar](https://istio.io/zh/docs/setup/kubernetes/sidecar-injection/) Envoy 代理仅在 iptables 初始化完成后再启动。
4. 启动 Sidecar 容器和应用程序容器。

有了这个解决方案，由于 Envoy Sidecar 需要以特定的非 root 用户 ID 运行，在 Istio 网格中运行的 Pod 只需要 `nonroot` SCC 就行了。

理想情况下，我们希望 Istio 中的应用程序通过 `restricted` SCC 运行，这是 Openshift 中的默认值。虽然 `nonroot` SCC 比 `restricted` SCC 的权限稍微宽泛一些，但这种折衷方案是可以接受的，这与使用 `privileged` SCC 运行每个 Istio 应用程序 Pod 相比，是一个巨大的进步。

现在，我们通过给 `istio-pod-network-controller` 提供 privileged 配置文件和 `NET_ADMIN` capability 来允许它修改其他 Pod 的 iptables 规则，这通常是可以接受的方案，因为该组件将由集群管理员以与 Istio 控制平面类似的方式安装和管理。

### <p id="h2">3. 安装指南</p>

----

根据安装指南假设 Istio 已成功安装在 `istio-system` 命名空间中，并且已经开启了[自动注入功能](https://istio.io/zh/docs/setup/kubernetes/sidecar-injection/#automatic-sidecar-injection)。克隆 istio-pod-network-controller [仓库](https://github.com/sabre1041/istio-pod-network-controller)，然后执行以下命令以使用 `Helm` 安装 `istio-pod-network-controller`：

```bash
$ helm template -n istio-pod-network-controller ./chart/istio-pod-network-controller | kubectl apply -f -
```

<br />

#### 测试自动注入功能

执行以下命令测试自动注入功能：

```bash
$ kubectl create namespace bookinfo
$ kubectl label namespace bookinfo istio-injection=enabled
$ kubectl annotate namespace bookinfo istio-pod-network-controller/initialize=true
$ kubectl apply -f examples/bookinfo.yaml -n bookinfo
```

其他部署方案请参考[官方仓库的文档](https://github.com/sabre1041/istio-pod-network-controller)。

### <p id="h2">4. 总结</p>

----

`istio-pod-network-controller` 是一个用来提高 Istio Deployment 安全性的可选工具，它通过消除在 Istio 网格中运行使用 privileged SCC 的 Pod 的需求，并让这些 Pod 只通过 nonroot SCC 运行，以此来提高安全性。如果您决定采用此解决方案，请注意这并不是 `Red Hat` 正式支持的项目。

----

<center>![](http://o7z41ciog.bkt.clouddn.com/qrcode_for_wechat_big.jpg)</center>
<center>扫一扫关注微信公众号</center>

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
#blue {
color: #2780e3;
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