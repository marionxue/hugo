---
title: "请求都去哪了？"
subtitle: "Istio 网关中的 Gateway 和 VirtualService 配置深度解析"
date: 2018-08-08T16:56:31+08:00
draft: false
toc: true
categories: "service mesh"
tags: ["istio", "service mesh", "kubernetes"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->

通过前几篇文章的学习与实践，我们对 Gateway、VirtualService 和 Destinationrule 的概念和原理有了初步的认知，本篇将对这几个对象资源的配置文件进行深度地解析，具体细节将会深入到每一个配置项与 Envoy 配置项的映射关系。

在开始之前，需要先搞清楚我们创建的这些对象资源最后都交给谁来处理了，负责处理这些资源的就是 pilot。

## 1. pilot总体架构

----

![](https://ws1.sinaimg.cn/large/006tKfTcgy1ftppxdcmwvj31kw0vvtdl.jpg)

首先我们回顾一下 pilot 总体架构，上面是[官方关于pilot的架构图](https://github.com/istio/old_pilot_repo/blob/master/doc/design.md)，因为是 old_pilot_repo 目录下，可能与最新架构有出入，仅供参考。所谓的 pilot 包含两个组件：`pilot-agent` 和 `pilot-discovery`。图里的 `agent` 对应 pilot-agent 二进制，`proxy` 对应 Envoy 二进制，它们两个在同一个容器中，`discovery service` 对应 pilot-discovery 二进制，在另外一个跟应用分开部署的单独的 Deployment 中。

+ <span id="inline-blue">discovery service</span> : 从 Kubernetes apiserver list/watch `service`、`endpoint`、`pod`、`node` 等资源信息，监听 istio 控制平面配置信息（如VirtualService、DestinationRule等）， 翻译为 Envoy 可以直接理解的配置格式。
+ <span id="inline-blue">proxy</span> : 也就是 Envoy，直接连接 discovery service，间接地从 Kubernetes 等服务注册中心获取集群中微服务的注册情况。
+ <span id="inline-blue">agent</span> : 生成 Envoy 配置文件，管理 Envoy 生命周期。
+ <span id="inline-blue">service A/B</span> : 使用了 Istio 的应用，如 Service A/B，的进出网络流量会被 proxy 接管。

简单来说 Istio 做为管理面，集合了配置中心和服务中心两个功能，并把配置发现和服务发现以一组统一的 `xDS` 接口提供出来，数据面的 Envoy 通过 xDS 获取需要的信息来做服务间通信和服务治理。

## 2. pilot-discovery 为 Envoy 提供的 xds 服务

----

### 所谓 xds

pilot-discovery 为数据面（运行在 sidecar 中的 Envoy 等 proxy 组件）提供控制信息服务，也就是所谓的 discovery service 或者 xds 服务。这里的 `x` 是一个代词，类似云计算里的 XaaS 可以指代 IaaS、PaaS、SaaS 等。在 Istio 中，xds 包括 `cds`(cluster discovery service)、`lds`(listener discovery service)、`rds`(route discovery service)、`eds`(endpoint discovery service)，而 `ads`(aggregated discovery service) 是对这些服务的一个统一封装。

以上 cluster、endpoint、route 等概念的详细介绍和实现细节可以参考 Envoy 在社区推广的 data plane api（[github.com/envoyproxy/data-plane-api](https://github.com/envoyproxy/data-plane-api)），这里只做简单介绍：

+ <span id="inline-blue">endpoint</span> : 一个具体的“应用实例”，对应 ip 和端口号，类似 Kubernetes 中的一个 Pod。
+ <span id="inline-blue">cluster</span> : 一个 `cluster` 是一个“应用集群”，它对应提供相同服务的一个或多个 `endpoint`。cluster 类似 Kubernetes 中 `Service` 的概念，即一个 Kubernetes Service 对应一个或多个用同一镜像启动，提供相同服务的 Pod。
+ <span id="inline-blue">route</span> : 当我们做灰度发布、金丝雀发布时，同一个服务会同时运行多个版本，每个版本对应一个 cluster。这时需要通过 `route` 规则规定请求如何路由到其中的某个版本的 cluster 上。

以上这些内容实际上都是对 Envoy 等 proxy 的配置信息，而所谓的 cluster discovery service、route discovery service 等 xxx discovery service 就是 Envoy 等从 `pilot-discovery` 动态获取 endpoint、cluster 等配置信息的协议和实现。为什么要做动态配置加载，自然是为了使用 `istioctl` 等工具统一、灵活地配置 service mesh。至于如何通过 istioctl 来查看 xds 信息，下文将会详细介绍。

而为什么要用 `ads` 来“聚合”一系列 `xds`，并非仅为了在同一个 gRPC 连接上实现多种 xds 来省下几个网络连接，ads 还有一个非常重要的作用是解决 `cds`、`rds` 信息更新顺序依赖的问题，从而保证以一定的顺序同步各类配置信息，这方面的讨论可以详见 [Envoy官网](https://www.envoyproxy.io/docs/envoy/latest/configuration/overview/v2_overview#aggregated-discovery-service)。

### 如何查看 xds

`pilot-discovery` 在初始化阶段依次 init 了各种模块，其中 `discovery service` 就是 xDS 相关实现。[envoy API reference](https://www.envoyproxy.io/docs/envoy/latest/) 可以查到 v1 和 v2 两个版本的 API 文档。[envoy control plane](https://github.com/envoyproxy/go-control-plane) 给了 v2 grpc 接口相关的数据结构和接口。

那么如何查看 xds 的信息呢？虽然 v2 是 `grpc` 的接口，但是 pilot 提供了 `InitDebug`，可以通过 debug 接口查询服务和 routes 等服务和配置信息。

**查看 eds**

首先找到 Service istio-pilot 的 `Cluster IP`：
```bash
$ export PILOT_SVC_IP=$(kubectl -n istio-system get svc istio-pilot -o go-template='{{.spec.clusterIP}}')
```

然后查看 eds：

```bash
$ curl http://$PILOT_SVC_IP:8080/debug/edsz
```
```json
[{
    "clusterName": "outbound|9080||reviews.nino.svc.cluster.local",
    "endpoints": [{
        "lbEndpoints": [{
            "endpoint": {
                "address": {
                    "socketAddress": {
                        "address": "10.244.0.56",
                        "portValue": 9080
                    }
                }
            }
        }, {
            "endpoint": {
                "address": {
                    "socketAddress": {
                        "address": "10.244.0.58",
                        "portValue": 9080
                    }
                }
            }
        }, {
            "endpoint": {
                "address": {
                    "socketAddress": {
                        "address": "10.244.2.25",
                        "portValue": 9080
                    }
                }
            }
        }]
    }]
}, {
    "clusterName": "outbound|9080|v3|reviews.nino.svc.cluster.local",
    "endpoints": [{
        "lbEndpoints": [{
            "endpoint": {
                "address": {
                    "socketAddress": {
                        "address": "10.244.0.58",
                        "portValue": 9080
                    }
                }
            }
        }]
    }]
}]
```

**查看 cds**

```bash
$ curl http://$PILOT_SVC_IP:8080/debug/cdsz
```
```json
[{"node": "sidecar~172.30.104.45~fortio-deploy-56dcc85457-b2pkc.default~default.svc.cluster.local-10", "addr": "172.30.104.45:43876", "connect": "2018-08-07 06:31:08.161483005 +0000 UTC m=+54.337448884","Clusters":[{
  "name": "outbound|9080||details.default.svc.cluster.local",
  "type": "EDS",
  "edsClusterConfig": {
    "edsConfig": {
      "ads": {

      }
    },
    "serviceName": "outbound|9080||details.default.svc.cluster.local"
  },
  "connectTimeout": "1.000s",
  "circuitBreakers": {
    "thresholds": [
      {

      }
    ]
  }
},
...
{
  "name": "outbound|9090||prometheus-k8s.monitoring.svc.cluster.local",
  "type": "EDS",
  "edsClusterConfig": {
    "edsConfig": {
      "ads": {

      }
    },
    "serviceName": "outbound|9090||prometheus-k8s.monitoring.svc.cluster.local"
  },
  "connectTimeout": "1.000s",
  "circuitBreakers": {
    "thresholds": [
      {

      }
    ]
  }
},
{
  "name": "BlackHoleCluster",
  "connectTimeout": "5.000s"
}]}
]
```

**查看 ads**

```bash
$ curl http://$PILOT_SVC_IP:8080/debug/adsz
```

## 3. Envoy 基本术语回顾

----

为了让大家更容易理解后面所讲的内容，先来回顾一下 Envoy 的基本术语。

+ <span id="inline-blue">Listener</span> : 监听器（listener）是服务(程序)监听者，就是真正干活的。 它是可以由下游客户端连接的命名网络位置（例如，端口、unix域套接字等）。Envoy 公开一个或多个下游主机连接的侦听器。一般是每台主机运行一个 Envoy，使用单进程运行，但是每个进程中可以启动任意数量的 Listener（监听器），目前只监听 TCP，每个监听器都独立配置一定数量的（L3/L4）网络过滤器。Listenter 也可以通过 Listener Discovery Service（LDS）动态获取。
+ <span id="inline-blue">Listener filter</span> : Listener 使用 listener filter（监听器过滤器）来操作链接的元数据。它的作用是在不更改 Envoy 的核心功能的情况下添加更多的集成功能。Listener filter 的 API 相对简单，因为这些过滤器最终是在新接受的套接字上运行。在链中可以互相衔接以支持更复杂的场景，例如调用速率限制。Envoy 已经包含了多个监听器过滤器。
+ <span id="inline-blue">Http Route Table</span> : HTTP 的路由规则，例如请求的域名，Path 符合什么规则，转发给哪个 Cluster。
+ <span id="inline-blue">Cluster</span> : 集群（cluster）是 Envoy 连接到的一组逻辑上相似的上游主机。Envoy 通过服务发现发现集群中的成员。Envoy 可以通过主动运行状况检查来确定集群成员的健康状况。Envoy 如何将请求路由到集群成员由负载均衡策略确定。

更多详细信息可以参考 [Envoy 的架构与基本术语](https://jimmysong.io/posts/envoy-archiecture-and-terminology/)，本文重点突出 `Listener`、`Route` 和 `Cluster` 这三个基本术语，同时需要注意流量经过这些术语的先后顺序，请求首先到达 `Listener`，然后通过 `Http Route Table` 转到具体的 `Cluster`，最后由具体的 Cluster 对请求做出响应。

## 4. Gateway 和 VirtualService 配置解析

----

还是拿之前 [Istio 流量管理](https://www.yangcs.net/posts/istio-traffic-management/) 这篇文章中的例子来解析吧，首先创建了一个 `Gateway`，配置文件如下：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: bookinfo-gateway
spec:
  selector:
    istio: ingressgateway # use istio default controller
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"
```

然后又创建了一个 `VirtualService`：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: bookinfo
spec:
  hosts:
  - "*"
  gateways:
  - bookinfo-gateway
  http:
  - match:
    - uri:
        exact: /productpage
    - uri:
        exact: /login
    - uri:
        exact: /logout
    - uri:
        prefix: /api/v1/products
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```

`VirtualService` 映射的就是 Envoy 中的 `Http Route Table`，大家可以注意到上面的 VirtualService 配置文件中有一个 `gateways` 字段，如果有这个字段，就表示这个 Http Route Table 是绑在 `ingressgateway` 的 `Listener` 中的；如果没有这个字段，就表示这个 Http Route Table 是绑在 Istio 所管理的所有微服务应用的 Pod 上的。

<div id="note">
<p id="note-title">Note</p>
<br />
<p>为了分清主次，我决定将本文拆分成两篇文章来讲解，本篇主要围绕 ingressgateway 来解析 Gateway 和 VirtualService，而微服务应用本身的 VirtualService 和 DestinationRule 解析放到下一篇文章再说。</p>
</div>

显而易见，上面这个 VirtualService 映射的 Http Route Table 是被绑在 ingressgateway 中的，可以通过 `istioctl` 来查看，istioctl 的具体用法请参考：[调试 Envoy 和 Pilot](https://istio.io/zh/help/ops/traffic-management/debugging-pilot-envoy/)。

首先查看 `Listener` 的配置项：

```bash
$ istioctl -n istio-system pc listeners istio-ingressgateway-b6db8c46f-qcfks --port 80 -o json
```
```json
[
    {
        "name": "0.0.0.0_80",
        "address": {
            "socketAddress": {
                "address": "0.0.0.0",
                "portValue": 80
            }
        },
        "filterChains": [
            {
                "filters": [
                    {
                        "name": "envoy.http_connection_manager",
                        "config": {
                            ...
                            "rds": {
                                "config_source": {
                                    "ads": {}
                                },
                                "route_config_name": "http.80"
                            },
                            ...
                        }
                    }
                ]
            }
        ]
    }
]
```

通过 `rds` 配置项的 `route_config_name` 字段可以知道该 Listener 使用的 Http Route Table 的名字是 `http.80`。

查看 `Http Route Table` 配置项：

```bash
$ istioctl -n istio-system pc routes istio-ingressgateway-b6db8c46f-qcfks --name http.80 -o json
```
```json
[
    {
        "name": "http.80",
        "virtualHosts": [
            {
                "name": "bookinfo:80",
                "domains": [
                    "*"
                ],
                "routes": [
                    {
                        "match": {
                            "path": "/productpage"
                        },
                        "route": {
                            "cluster": "outbound|9080||productpage.default.svc.cluster.local",
                            "timeout": "0.000s",
                            "maxGrpcTimeout": "0.000s"
                        },
                        ...
                    },
                    ...
                    {
                        "match": {
                            "prefix": "/api/v1/products"
                        },
                        "route": {
                            "cluster": "outbound|9080||productpage.default.svc.cluster.local",
                            "timeout": "0.000s",
                            "maxGrpcTimeout": "0.000s"
                        },
                        ...
                    },
                    ...
                ]
            }
        ],
        "validateClusters": false
    }
]
```

+ VirtualService 中的 `hosts` 字段对应 Http Route Table 中 `virtualHosts` 配置项的 `domains` 字段。这里表示可以使用任何域名来通过 ingressgateway 访问服务（也可以直接通过 IP 来访问）。
+ VirtualService 中的 `exact` 字段对应 Http Route Table 中 `routes.match` 配置项的 `path` 字段。 
+ VirtualService 中的 `prefix` 字段对应 Http Route Table 中 `routes.match` 配置项的 `prefix` 字段。
+ VirtualService 中的 `route.destination` 配置项对应 Http Route Table 中 `routes.route` 配置项的 `cluster` 字段。

关于 Envoy 中的 HTTP 路由解析可以参考我之前的文章：[HTTP 路由解析](https://www.yangcs.net/posts/routing-basics/)。

查看 `Cluster` 配置项：

```bash
$ istioctl -n istio-system pc clusters istio-ingressgateway-b6db8c46f-qcfks --fqdn productpage.default.svc.cluster.local --port 9080 -o json
```
```json
[
    {
        "name": "outbound|9080||productpage.default.svc.cluster.local",
        "type": "EDS",
        "edsClusterConfig": {
            "edsConfig": {
                "ads": {}
            },
            "serviceName": "outbound|9080||productpage.default.svc.cluster.local"
        },
        "connectTimeout": "1.000s",
        "circuitBreakers": {
            "thresholds": [
                {}
            ]
        }
    }
]
```

可以看到，`Cluster` 最终将集群外通过 ingressgateway 发起的请求转发给实际的 `endpoint`，也就是 Kubernetes 集群中的 Service `productpage` 下面的 Pod（由 serviceName 字段指定）。

<div id="note">
<p id="note-title">Note</p>
<br />
<p>实际上 istioctl 正是通过 pilot 的 xds 接口来查看 Listener 、Route 和 Cluster 等信息的。</p>
</div>

好了，现在请求已经转交给 productpage 了，那么接下来这个请求将会如何走完整个旅程呢？请听下回分解！

## 5. 参考

----

+ [Service Mesh深度学习系列（三）| istio源码分析之pilot-discovery模块分析（中）](https://www.kubernetes.org.cn/4379.html)
+ [调试 Envoy 和 Pilot](https://istio.io/zh/help/ops/traffic-management/debugging-pilot-envoy/)
+ [Envoy 的架构与基本术语](https://jimmysong.io/posts/envoy-archiecture-and-terminology/)

----

<center>![](http://o7z41ciog.bkt.clouddn.com/qrcode_for_wechat_big.jpg)</center>

<style>
a:hover{cursor:url(http://oqk3alhse.bkt.clouddn.com/cursor_5.png), pointer;}
body {
    cursor: url(http://oqk3alhse.bkt.clouddn.com/cursor_1.png), default;
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
#blockquote {
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
