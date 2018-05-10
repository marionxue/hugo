---
title: "Kubernetes 中的容器运行时"
subtitle: "容器运行时接口解析"
date: 2018-04-03T06:50:43Z
draft: false
categories: "kubernetes"
tags: ["kubernetes", "docker"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

容器运行时（Container Runtime）是 Kubernetes 最重要的组件之一，负责真正管理镜像和容器的生命周期。Kubelet 通过 `Container Runtime Interface (CRI)` 与容器运行时交互，以管理镜像和容器。

容器运行时接口(`Container Runtime Interface (CRI)`) 是 Kubelet 1.5 和 kubelet 1.6 中主要负责的一块项目，它重新定义了 Kubelet Container Runtime API，将原来完全面向 Pod 级别的 API 拆分成面向 `Sandbox` 和 `Container` 的 API，并分离镜像管理和容器引擎到不同的服务。

![](https://kubernetes.feisky.xyz/zh/plugins/images/cri.png)

CRI 最早从从 1.4 版就开始设计讨论和开发，在 v1.5 中发布第一个测试版。在 v1.6 时已经有了很多外部容器运行时，如 frakti、cri-o 的 alpha 支持。v1.7 版本新增了 `cri-containerd` 的 alpha 支持，而 `frakti` 和 `cri-o` 则升级到 beta 支持。

## <p id="h2">1. CRI 接口</p>

----

CRI 基于 `gRPC` 定义了 `RuntimeService` 和 `ImageService`，分别用于容器运行时和镜像的管理。其定义在

+ **v1.10+:** [pkg/kubelet/apis/cri/v1alpha2/runtime](https://github.com/kubernetes/kubernetes/blob/release-1.10/pkg/kubelet/apis/cri/runtime/v1alpha2)
+ **v1.7~v1.9:** [pkg/kubelet/apis/cri/v1alpha1/runtime](https://github.com/kubernetes/kubernetes/tree/release-1.9/pkg/kubelet/apis/cri/v1alpha1/runtime)
+ **v1.6:** [pkg/kubelet/api/v1alpha1/runtime](https://github.com/kubernetes/kubernetes/tree/release-1.6/pkg/kubelet/api/v1alpha1/runtime)

Kubelet 作为 CRI 的客户端，而 Runtime 维护者则需要实现 CRI 服务端，并在启动 kubelet 时将其传入：

```bash
$ kubelet --container-runtime=remote --container-runtime-endpoint=unix:///var/run/crio/crio.sock ..
```

## <p id="h2">2. 如何开发新的 Container Runtime</p>

----

开发新的 Container Runtime 只需要实现 `CRI gRPC Server`，包括 `RuntimeService` 和 `ImageService`。该 gRPC Server 需要监听在本地的 `unix socket`（Linux 支持 unix socket 格式，Windows 支持 tcp 格式）。

具体的实现方法可以参考下面已经支持的 Container Runtime 列表。

## <p id="h2">3. 目前支持的 Container Runtime</p>

----

目前，有多家厂商都在基于 CRI 集成自己的容器引擎，其中包括:

+ **Docker:** 核心代码依然保留在 kubelet 内部（`pkg/kubelet/dockershim`），依然是最稳定和特性支持最好的 Runtime

+ **[HyperContainer](https://github.com/kubernetes/frakti):** 支持 Kubernetes v1.6+，提供基于 `hypervisor` 和 docker 的混合运行时，适用于运行非可信应用，如多租户和 `NFV` 等场景

+ **Runc** 有两个实现，cri-o 和 cri-containerd
    + [cri-containerd](https://github.com/kubernetes-incubator/cri-containerd): 支持 kubernetes v1.7+
    + [cri-o](https://github.com/kubernetes-incubator/cri-o): 支持 Kubernetes v1.6+，底层运行时支持 runc 和 intel clear container

+ **[Rkt](https://github.com/kubernetes-incubator/rktlet):** 开发中

+ **[Mirantis](https://github.com/Mirantis/virtlet):** 直接管理 `libvirt` 虚拟机，镜像须是 `qcow2` 格式

+ **[Infranetes](https://github.com/apporbit/infranetes):** 直接管理 IaaS 平台虚拟机，如 GCE、AWS 等

### cri-containerd

以 containerd 为例，它将 `dockershim` 和 `docker daemon` 替换为 `cri-containerd` 服务。

![](https://kubernetes.feisky.xyz/zh/plugins/images/cri-containerd.png)

而 cri-containerd 则实现了 Kubelet CRI 接口，对 Kubelet 暴露 Image Service 和 Runtime Service。在内部，它通过 containerd 的 gRPC 接口管理容器和镜像，并通过 CNI 插件给 Pod 配置网络。
![](https://kubernetes.feisky.xyz/zh/plugins/images/containerd.png)

## <p id="h2">4. CRI Tools</p>

----

为了方便开发、调试和验证新的 Container Runtime，社区还维护了一个 [cri-tools](https://github.com/kubernetes-incubator/cri-tools) 工具，它提供两个组件

+ `crictl:` 类似于 docker 的命令行工具，不需要通过 Kubelet 就可以跟 Container Runtime 通信，可用来调试或排查问题
+ `critest:` CRI 的验证测试工具，用来验证新的 Container Runtime 是否实现了 CRI 需要的功能

另外一个工具是 [libpod](https://github.com/projectatomic/libpod)，它也提供了一个组件：[podman](https://github.com/projectatomic/libpod/blob/master/cmd/podman)，功能和 `crictl` 类似。

如果想构建 oci 格式的镜像，可以使用工具：[buildah](https://github.com/projectatomic/buildah)

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
