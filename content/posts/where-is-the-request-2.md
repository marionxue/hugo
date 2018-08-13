---
title: "请求都去哪了？（续）"
subtitle: "服务网格内部的 VirtualService 和 DestinationRule 配置深度解析"
date: 2018-08-13T16:30:30+08:00
draft: false
categories: "service mesh"
tags: ["istio", "service mesh", "kubernetes"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

书接前文，上文我们通过跟踪**集群外通过 ingressgateway 发起的请求**来探寻流量在 Istio 服务网格之间的流动方向，先部署 bookinfo 示例应用，然后创建一个监听在 `ingressgateway` 上的  GateWay 和 VirtualService，通过分析我们追踪到请求最后转交给了 `productpage`。

在继续追踪请求之前，先对之前的内容做一个补充说明。

### <p id="h2">1. Pod 在服务网格之间如何通信？</p>

----

大家都知道，在 Istio 尚未出现之前，Kubernetes 集群内部 Pod 之间是通过 `ClusterIP` 来进行通信的，那么通过 Istio 在 Pod 内部插入了 `Sidecar` 之后，微服务应用之间是否仍然还是通过 ClusterIP 来通信呢？我们来一探究竟！

继续拿上文的步骤举例子，来看一下 ingressgateway 和 productpage 之间如何通信，请求通过 ingressgateway 到达了 `endpoint` ，那么这个 endpoint 到底是 `ClusterIP` + Port 还是 `PodIP` + Port 呢？由于 istioctl 没有提供 eds 的查看参数，可以通过 pilot 的 xds debug 接口来查看：

```bash
# 获取 istio-pilot 的 ClusterIP
$ export PILOT_SVC_IP=$(kubectl -n istio-system get svc -l app=istio-pilot -o go-template='{{range .items}}{{.spec.clusterIP}}{{end}}')

# 查看 eds
$ curl http://$PILOT_SVC_IP:8080/debug/edsz|grep "outbound|9080||productpage.default.svc.cluster.local" -A 27 -B 1
```
```json
{
  "clusterName": "outbound|9080||productpage.default.svc.cluster.local",
  "endpoints": [
    {
      "lbEndpoints": [
        {
          "endpoint": {
            "address": {
              "socketAddress": {
                "address": "172.30.135.40",
                "portValue": 9080
              }
            }
          },
          "metadata": {
            "filterMetadata": {
              "istio": {
                  "uid": "kubernetes://productpage-v1-76474f6fb7-pmglr.default"
                }
            }
          }
        }
      ]
    }
  ]
},
```

从这里可以看出，各个微服务之间是直接通过 `PodIP + Port` 来通信的，Service 只是做一个逻辑关联用来定位 Pod，实际通信的时候并没有通过 Service。

### <p id="h2">2. 部署 bookinfo 应用的时候发生了什么？</p>

----

通过 Istio 来部署 bookinfo 示例应用时，Istio 会向应用程序的所有 Pod 中注入 Envoy 容器。但是我们仍然还不清楚注入的 Envoy 容器的配置文件里都有哪些东西，这时候就是 istioctl 命令行工具发挥强大功效的时候了，可以通过 `proxy-config` 参数来深度解析 Envoy 的配置文件（上一节我们已经使用过了）。

我们先把目光锁定在某一个固定的 Pod 上，以 `productpage` 为例。先查看 productpage 的 Pod Name：

```bash
$ kubectl get pod -l app=productpage

NAME                              READY     STATUS    RESTARTS   AGE
productpage-v1-76474f6fb7-pmglr   2/2       Running   0          7h
```

#### 1. 查看 productpage 的监听器的基本基本摘要

```bash
$ istioctl proxy-config listeners productpage-v1-76474f6fb7-pmglr

ADDRESS            PORT      TYPE
172.30.135.40      9080      HTTP    // ③ Receives all inbound traffic on 9080 from listener `0.0.0.0_15001`
10.254.223.255     15011     TCP <---+
10.254.85.22       20001     TCP     |
10.254.149.167     443       TCP     |
10.254.14.157      42422     TCP     |
10.254.238.17      9090      TCP     |  ② Receives outbound non-HTTP traffic for relevant IP:PORT pair from listener `0.0.0.0_15001`
10.254.184.32      5556      TCP     |
10.254.0.1         443       TCP     |
10.254.52.199      8080      TCP     |
10.254.118.224     443       TCP <---+  
0.0.0.0            15031     HTTP <--+
0.0.0.0            15004     HTTP    |
0.0.0.0            9093      HTTP    |
0.0.0.0            15030     HTTP    |
0.0.0.0            8080      HTTP    |  ④ Receives outbound HTTP traffic for relevant port from listener `0.0.0.0_15001`
0.0.0.0            8086      HTTP    |
0.0.0.0            9080      HTTP    |
0.0.0.0            15010     HTTP <--+
0.0.0.0            15001     TCP     // ① Receives all inbound and outbound traffic to the pod from IP tables and hands over to virtual listener
```

Istio 会生成以下的监听器：

+ ① `0.0.0.0:15001` 上的监听器接收进出 Pod 的所有流量，然后将请求移交给虚拟监听器。
+ ② 每个 Service IP 配置一个虚拟监听器，每个出站 TCP/HTTPS 流量一个非 HTTP 监听器。
+ ③ 每个 Pod 入站流量暴露的端口配置一个虚拟监听器。
+ ④ 每个出站 HTTP 流量的 HTTP `0.0.0.0` 端口配置一个虚拟监听器。

上一节提到服务网格之间的应用是直接通过 PodIP 来进行通信的，但还不知道服务网格内的应用于服务网格外的应用是如何通信的。大家应该可以猜到，这个秘密就隐藏在 Service IP 的虚拟监听器中，以 `kube-dns` 为例，查看 productpage 如何与 kube-dns 进行通信：

```bash
$ istioctl proxy-config listeners productpage-v1-76474f6fb7-pmglr --address 10.254.0.2 --port 53 -o json
```
```json
[
    {
        "name": "10.254.0.2_53",
        "address": {
            "socketAddress": {
                "address": "10.254.0.2",
                "portValue": 53
            }
        },
        "filterChains": [
            {
                "filters": [
                    ...
                    {
                        "name": "envoy.tcp_proxy",
                        "config": {
                            "cluster": "outbound|53||kube-dns.kube-system.svc.cluster.local",
                            "stat_prefix": "outbound|53||kube-dns.kube-system.svc.cluster.local"
                        }
                    }
                ]
            }
        ],
        "deprecatedV1": {
            "bindToPort": false
        }
    }
]
```

```bash
# 查看 eds
$ curl http://$PILOT_SVC_IP:8080/debug/edsz|grep "outbound|53||kube-dns.kube-system.svc.cluster.local" -A 27 -B 1
```
```json
{
  "clusterName": "outbound|53||kube-dns.kube-system.svc.cluster.local",
  "endpoints": [
    {
      "lbEndpoints": [
        {
          "endpoint": {
            "address": {
              "socketAddress": {
                "address": "172.30.135.21",
                "portValue": 53
              }
            }
          },
          "metadata": {
            "filterMetadata": {
              "istio": {
                  "uid": "kubernetes://coredns-64b597b598-4rstj.kube-system"
                }
            }
          }
        }
      ]
    },
```

可以看出，服务网格内的应用仍然通过 ClusterIP 与网格外的应用通信，但有一点需要注意：**这里并没有 `kube-proxy` 的参与！**Envoy 自己实现了一套流量转发机制，当你访问 ClusterIP 时，Envoy 就把流量转发到具体的 Pod 上去，**不需要借助 kube-proxy 的 `iptables` 或 `ipvs` 规则**。

#### 2. 从上面的摘要中可以看出，每个 Sidecar 都有一个绑定到 `0.0.0.0:15001` 的监听器，IP tables 将 pod 的所有入站和出站流量路由到这里。此监听器把 `useOriginalDst` 设置为 true，这意味着它将请求交给最符合请求原始目标的监听器。如果找不到任何匹配的虚拟监听器，它会将请求发送给返回 404 的 `BlackHoleCluster`。

```bash
$ istioctl proxy-config listeners productpage-v1-76474f6fb7-pmglr --port 15001 -o json
```
```json
[
    {
        "name": "virtual",
        "address": {
            "socketAddress": {
                "address": "0.0.0.0",
                "portValue": 15001
            }
        },
        "filterChains": [
            {
                "filters": [
                    {
                        "name": "envoy.tcp_proxy",
                        "config": {
                            "cluster": "BlackHoleCluster",
                            "stat_prefix": "BlackHoleCluster"
                        }
                    }
                ]
            }
        ],
        "useOriginalDst": true
    }
]
```

#### 3. 我们的请求是到 `9080` 端口的 HTTP 出站请求，这意味着它被切换到 `0.0.0.0:9080` 虚拟监听器。然后，此监听器在其配置的 RDS 中查找路由配置。在这种情况下，它将查找由 Pilot 配置的 RDS 中的路由 `9080`（通过 ADS）。

```bash
$ istioctl proxy-config listeners productpage-v1-76474f6fb7-pmglr --address 0.0.0.0 --port 9080 -o json
```
```json
...
"rds": {
    "config_source": {
        "ads": {}
    },
    "route_config_name": "9080"
}
...
```

#### 4. `9080` 路由配置仅为每个服务提供虚拟主机。我们的请求正在前往 reviews 服务，因此 Envoy 将选择我们的请求与域匹配的虚拟主机。一旦在域上匹配，Envoy 会查找与请求匹配的第一条路径。在这种情况下，我们没有任何高级路由，因此只有一条路由匹配所有内容。这条路由告诉 Envoy 将请求发送到 `outbound|9080||reviews.default.svc.cluster.local` 集群。

```bash
$ istioctl proxy-config routes productpage-v1-76474f6fb7-pmglr --name 9080 -o json
```
```json
[
    {
        "name": "9080",
        "virtualHosts": [
            {
                "name": "reviews.default.svc.cluster.local:9080",
                "domains": [
                    "reviews.default.svc.cluster.local",
                    "reviews.default.svc.cluster.local:9080",
                    "reviews",
                    "reviews:9080",
                    "reviews.default.svc.cluster",
                    "reviews.default.svc.cluster:9080",
                    "reviews.default.svc",
                    "reviews.default.svc:9080",
                    "reviews.default",
                    "reviews.default:9080",
                    "172.21.152.34",
                    "172.21.152.34:9080"
                ],
                "routes": [
                    {
                        "match": {
                            "prefix": "/"
                        },
                        "route": {
                            "cluster": "outbound|9080||reviews.default.svc.cluster.local",
                            "timeout": "0.000s"
                        },
...
```

#### 5. 此集群配置为从 Pilot（通过 ADS）检索关联的端点。因此，Envoy 将使用 `serviceName` 字段作为密钥来查找端点列表并将请求代理到其中一个端点。

```bash
$ istioctl proxy-config clusters productpage-v1-76474f6fb7-pmglr --fqdn reviews.default.svc.cluster.local -o json

[
    {
        "name": "outbound|9080||reviews.default.svc.cluster.local",
        "type": "EDS",
        "edsClusterConfig": {
            "edsConfig": {
                "ads": {}
            },
            "serviceName": "outbound|9080||reviews.default.svc.cluster.local"
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

上面的整个过程就是在不创建任何规则的情况下请求从 `productpage` 到 `reviews` 的过程，从 reviews 到网格内其他应用的流量与上面类似，就不展开讨论了。接下来分析创建规则之后的请求转发过程。

### <p id="h2">3. VirtualService 和 DestinationRule 配置解析</p>

----

#### VirtualService

首先创建一个 `VirtualService`。

```yaml
$ cat <<EOF | istioctl create -f -
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
    - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: v1
EOF
```

上一篇文章已经介绍过，`VirtualService` 映射的就是 Envoy 中的 `Http Route Table`，还是将目标锁定在 productpage 上，我们来查看一下路由配置：

```bash
$ istioctl proxy-config routes productpage-v1-76474f6fb7-pmglr --name 9080 -o json
```
```json
[
    {
        "name": "9080",
        "virtualHosts": [
            {
                "name": "reviews.default.svc.cluster.local:9080",
                "domains": [
                    "reviews.default.svc.cluster.local",
                    "reviews.default.svc.cluster.local:9080",
                    "reviews",
                    "reviews:9080",
                    "reviews.default.svc.cluster",
                    "reviews.default.svc.cluster:9080",
                    "reviews.default.svc",
                    "reviews.default.svc:9080",
                    "reviews.default",
                    "reviews.default:9080",
                    "172.21.152.34",
                    "172.21.152.34:9080"
                ],
                "routes": [
                    {
                        "match": {
                            "prefix": "/"
                        },
                        "route": {
                            "cluster": "outbound|9080|v1|reviews.default.svc.cluster.local",
                            "timeout": "0.000s"
                        },
...
```

注意对比一下没创建 VirtualService 之前的路由，现在路由的 `cluster` 字段的值已经从之前的 `outbound|9080|reviews.default.svc.cluster.local` 变为 `outbound|9080|v1|reviews.default.svc.cluster.local`。

**请注意：**我们现在还没有创建 DestinationRule！

你可以尝试搜索一下有没有 `outbound|9080|v1|reviews.default.svc.cluster.local` 这个集群，如果不出意外，你将找不到 `SUBSET=v1` 的集群。

<center>![](http://o7z41ciog.bkt.clouddn.com/Jietu20180813-160027.jpg)</center>

由于找不到这个集群，所以该路由不可达，这就是为什么你打开 productpage 的页面会出现如下的报错：

<center>![](http://o7z41ciog.bkt.clouddn.com/Jietu20180813-160823.jpg)</center>

#### DestinationRule

为了使上面创建的路由可达，我们需要创建一个 `DestinationRule`：

```yaml
$ cat <<EOF | istioctl create -f -
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: reviews
spec:
  host: reviews
  subsets:
  - name: v1
    labels:
      version: v1
EOF
```

其实 `DestinationRule` 映射到 Envoy 的配置文件中就是 `Cluster`。现在你应该能看到 `SUBSET=v1` 的 Cluster 了：

```bash
$ istioctl proxy-config clusters productpage-v1-76474f6fb7-pmglr --fqdn reviews.default.svc.cluster.local --subset=v1 -o json

[
    {
        "name": "outbound|9080|v1|reviews.default.svc.cluster.local",
        "type": "EDS",
        "edsClusterConfig": {
            "edsConfig": {
                "ads": {}
            },
            "serviceName": "outbound|9080|v1|reviews.default.svc.cluster.local"
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

到了这一步，一切皆明了，后面的事情就跟之前的套路一样了，具体的 Endpoint 对应打了标签 `version=v1` 的 Pod：

```bash
$ kubectl get pod -l app=reviews,version=v1 -o wide

NAME                          READY     STATUS    RESTARTS   AGE       IP              NODE
reviews-v1-5b487cc689-njx5t   2/2       Running   0          11h       172.30.104.38   192.168.123.248
```
```bash
$ curl http://$PILOT_SVC_IP:8080/debug/edsz|grep "outbound|9080|v1|reviews.default.svc.cluster.local" -A 27 -B 2

{
  "clusterName": "outbound|9080|v1|reviews.default.svc.cluster.local",
  "endpoints": [
    {
      "locality": {
        "zone": "yangpu/shanghai"
      },
      "lbEndpoints": [
        {
          "endpoint": {
            "address": {
              "socketAddress": {
                "address": "172.30.104.38",
                "portValue": 9080
              }
            }
          },
          "metadata": {
            "filterMetadata": {
              "istio": {
                  "uid": "kubernetes://reviews-v1-5b487cc689-njx5t.default"
                }
            }
          }
        }
      ]
    }
  ]
},
```

现在再次用浏览器访问 productpage，你会发现报错已经消失了。

<center>![](http://o7z41ciog.bkt.clouddn.com/Jietu20180813-162629.jpg)</center>

### <p id="h2">4. 参考</p>

----

+ [调试 Envoy 和 Pilot](https://istio.io/zh/help/ops/traffic-management/proxy-cmd/)

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
