---
title: "将服务发现与 Envoy 集成"
subtitle: "为 Envoy 配置 CDS 和 EDS"
date: 2018-07-04T10:12:43Z
draft: false
categories: "service mesh"
tags: ["envoy", "service mesh"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

在微服务中使用 Envoy，需要明确两个核心概念：**数据平面**和**控制平面**。

+ <span id="inline-blue">数据平面</span> 由一组 Envoy 实例组成，用来调解和控制微服务之间的所有网络通信。
+ <span id="inline-blue">控制平面</span> 从 Envoy 代理和其他服务收集和验证配置，并在运行时执行访问控制和使用策略。

你可以使用静态类型的配置文件来实现控制平面，但为了能做出更加智能的负载均衡决策，最好的方法是通过 API 接口来实现。通过 API 接口来集中发现服务可以充分利用 Envoy 动态更新配置文件的能力。设置控制平面的第一步就是将 Envoy 连接到服务发现服务（SDS），通常分为三步：

1. 实现一个控制平面
2. 将控制平面中定义的服务发布到 Envoy 的 `clusters` 中
3. 将 主机/容器/实例 发布到 Envoy 的 `endpoints` 中

## <p id="h2">1. 实现一个控制平面</p>

----

控制平面必须要满足 [Envoy v2 xDS APIs](https://www.envoyproxy.io/docs/envoy/latest/api-v2/api)，同时为了更好地使用服务发现能力，你的控制平面最好能够实现集群发现服务（CDS）和端点发现服务（EDS）。为了避免重复造轮子，你可以选择社区已经实现好的控制平面：

+ <span id="inline-blue">Rotor</span> : [Rotor](https://github.com/turbinelabs/rotor) 是一种快速、轻量级的 xDS 实现，它可以和 `Kubernetes`、`Consul` 和 `AWS` 等服务集成，并且提供了一组默认的路由发现服务（RDS）和监听器发现服务（LDS）。它也是 Turbine Labs 的商业解决方案 [Houston](https://www.turbinelabs.io/) 的组件之一，Houston 在 Rotor 的基础上增加了更多的路由、指标和弹性方面的配置。

+ <span id="inline-blue">go-control-plane</span> : Envoy 官方仓库提供了一个开源版本的控制平面：[go-control-plane](https://github.com/envoyproxy/go-control-plane)。如果你想弄清楚如何从服务发现服务中获取所有内容，可以好好研究一下这个项目。

+ <span id="inline-blue">Pilot</span> :  如果想将 Envoy 和 Kubernetes 集成，你可以选择 [Istio](https://istio.io/) 项目。Istio 中的控制平面是由 [Pilot](https://istio.io/docs/concepts/traffic-management/pilot.html) 组件来实现的，它会将 `YAMl` 文件的内容转换为相应的 xDS 响应。如果你不想使用 Istio，也不用担心，因为 Pilot 完全可以脱离 Istio 的其他组件（如 `Mixer`）来单独和 Envoy 集成。

## <p id="h2">2. 将服务发布到 CDS</p>

----

集群是 Envoy 连接到的一组逻辑上相似的上游主机，通过它可以对流量进行负载均衡。你可以通过调用集群发现服务（CDS）的 API 来动态获取集群管理成员，Envoy 会定期轮询 `CDS` 端点以进行集群配置，配置文件形式如下：

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.api.v2.Cluster
  name: some_service
  connect_timeout: 1.0s
  lb_policy: ROUND_ROBIN
  type: EDS
  eds_cluster_config:
    eds_config:
      api_config_source:
        api_type: GRPC
        cluster_names: [xds_cluster]
```

服务发现收集的每个服务都会映射到 `resources` 下面的一个配置项，除此之外你还需要为负载均衡设置一些额外的配置参数：

+ `lb_policy` : 集群的负载均衡类型，有以下几种方式：
  + `round_robin` : 轮询主机
  + `weighted_least_request` : 最近获得最少请求的主机
  + `random` : 随机
+ `connect_timeout` : 设置连接超时。越小越好，从 1 秒开始慢慢往上增加，直到网络没有明显的抖动为止。
+ `api_type` : 设置服务的协议。Envoy 通过该协议和服务发现服务进行通信。

通常情况下，你可以对端点（Endpoint）列表进行硬编码，但如果基础架构是动态的，则需要将 `type` 设置为 `EDS`，这将告诉 Envoy 轮询 `EDS API` 以获取可用的 IP/Port 列表。完整示例可以参考 [Envoy 的官方文档](https://www.envoyproxy.io/docs/envoy/latest/api-v1/cluster_manager/cluster.html)。

设置好 CDS 之后，就可以为此集群设置端点发现服务（EDS）了。

## <p id="h2">3. 将实例发布到 EDS</p>

----

Envoy 将端点（`Endpoint`）定义为集群中可用的 IP 和端口。为了能够对服务之间的流量进行负载均衡，Envoy 希望 `EDS API` 能够提供每个服务的端点列表。Envoy 会定期轮询 EDS 端点，然后生成响应：

```yaml
version_info: "0"
resources:
- "@type": type.googleapis.com/envoy.api.v2.ClusterLoadAssignment
  cluster_name: some_service
  endpoints:
  - lb_endpoints:
    - endpoint:
       address:
         socket_address:
           address: 127.0.0.2
           port_value: 1234
```

通过这种配置方式，Envoy 唯一需要知道的就是该端点属于哪个集群，这比直接定义集群更简单。

Envoy 将 CDS 和 EDS 视为一份份的报告并保持服务发现的最终一致性。如果到该端点的请求经常失败，就会从负载均衡中删除该端点，直到再次恢复正常访问。

## <p id="h2">4. 最佳实践：对配置进行分区</p>

----

当集群中有很多服务时，Envoy 与 CDS 和 EDS 的交互量将会非常庞大，一旦出现问题，从几千个 API 响应中排查问题是很不现实的。标准的做法是以两种方式对配置进行分区：

+ `根据数据中心/区域划分` : 通常情况下，一个数据中心的服务不需要知道其他数据中心可用的服务端点。要想在不同区域之间建立通信，需要将远程数据中心的前端代理添加到本地的负载均衡器中。
+ `根据服务需求划分` : 通过为不同的服务配置 Envoy 边车代理（服务 envoy 与每个 serivce 实例一起运行），设置白名单来限制不同服务之间的相互通信，可以降低 1000 个级别的微服务之间相互通信的复杂度。同时边车（Sidecars）代理还可以通过阻止对服务的意外调用来加强安全保护。

对配置进行分区可以降低对不同服务的运营和管理的难度，但它的代价是使控制平面变得更加复杂，但客户往往是不关心控制平面的，所以牺牲控制平面的复杂度还是很值得的。

## <p id="h2">5. 下一步</p>

----

一旦控制平面发现了所有可用服务，就可以在这些服务上配置路由了。下一节将会介绍如何配置路由发现服务（RDS）。

![](http://o7z41ciog.bkt.clouddn.com/qrcode_for_wechat_big.jpg)

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
