---
title: "HTTP 路由解析"
subtitle: "通过 HTTP 路由规则来切换流量"
date: 2018-06-29T09:57:33Z
draft: false
toc: true
categories: "servicemesh"
tags: ["envoy"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->

本文将更详细地讨论 Envoy 的 HTTP 路由，如果你已经看过了我的上篇文章：[在你的笔记本上运行 Envoy](https://www.yangcs.net/posts/run-envoy-on-your-laptop/)，现在就可以更深入地了解如何在静态文件中配置路由（Route）、集群（Cluster）和监听器（Listener）了。

## 1. 相关组件

----

### 路由

<span id="inline-blue">路由</span> 是一组将虚拟主机与集群相匹配的规则，通过路由你可以很轻松地创建流量切换规则。路由的定义方式有两种：通过静态配置文件定义或通过路由发现服务（`RDS`）进行配置。

### 集群

<span id="inline-blue">集群</span> 是一组逻辑上相似的上游主机，它接收来自 Envoy 的流量。集群可以通过负载均衡策略来提高基础架构的弹性。集群可以通过静态文件进行配置，也可以通过集群发现服务（`CDS`）API 动态获取。

### 监听器

<span id="inline-blue">监听器</span> 是可以接受来自下游客户端的连接的命名网络位置（例如，端口，unix域套接字等）。Envoy 公开一个或多个下游主机连接的侦听器。同样，监听器可以通过静态定义，也可以通过监听器发现服务（LDS）动态获取。

## 2. 配置路由

----

Envoy 的路由定义将 `域 + URL` 映射到集群。在上一篇文章中，我们定义了两个集群（service1 和 service2），每一个集群都匹配一个单独的 URL（`/service1` 和 `/service2`）。

```yaml
virtual_hosts:
  - name: backend
    domains:
    - "*"
    routes:
    - match:
        prefix: "/service/1"
      route:
        cluster: service1
    - match:
        prefix: "/service/2"
      route:
        cluster: service2
```

集群从 DNS 中获取集群成员数据，并对集群中的所有主机使用**轮询**的方式进行负载均衡。

```yaml
clusters:
  - name: service1
      connect_timeout: 0.25s
      type: strict_dns
      lb_policy: round_robin
      http2_protocol_options: {}
      hosts:
      - socket_address:
          address: service1
          port_value: 80
  - name: service2
      connect_timeout: 0.25s
      type: strict_dns
      lb_policy: round_robin
      http2_protocol_options: {}
      hosts:
      - socket_address:
          address: service2
          port_value: 80
```

## 3. 配置监听器

----

路由的配置包含在监听器的配置中，现在我们再回过头来看一下监听器的配置。监听器通过**监听器过滤器**（Listener filter）来操作路由配置中定义的两个服务。监听器的 API 非常简单，它的作用是在不更改 Envoy 的核心功能的情况下添加更多的集成功能。

```yaml
listeners:
  - address:
      socket_address:
        address: 0.0.0.0
        port_value: 80
    filter_chains:
    - filters:
      - name: envoy.http_connection_manager
        config:
          codec_type: auto
          stat_prefix: ingress_http
          route_config:
            name: local_route
            virtual_hosts:
            - name: backend
              domains:
              - "*"
              routes:
              - match:
                  prefix: "/service/1"
                route:
                  cluster: service1
              - match:
                  prefix: "/service/2"
                route:
                  cluster: service2
          http_filters:
          - name: envoy.router
            config: {}
```

## 4. 动态发现路由、集群和监听器

----

到目前为止我们都是通过静态配置文件来配置路由和集群，但你也可以通过 `RDS` 和 `CDS` 来动态更新路由和集群。特别是当你的基础架构规模非常大时，你可以通过配置动态服务发现的规则来简化你的重复配置成本，并且可以将同一套动态服务发现规则应用于多个 Envoy 集群。

现在你已经了解了如何配置基本的路由、集群和监听器，下一节我们将学习如何在增量部署中设置更复杂的流量切换和过滤规则。

## 5. 参考

----

+ [Envoy 官方文档中文版](https://servicemesher.github.io/envoy/)


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
