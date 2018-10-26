---
title: "通过 Envoy 实现增量部署"
subtitle: "基于请求头的路由和加权负载均衡"
date: 2018-07-02T05:37:37Z
draft: false
toc: true
categories: "service mesh"
tags: ["envoy", "service mesh"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->

微服务最常见的工作流程之一就是版本更新。不同于基础架构更新，通过流量管理可以优雅地实现微服务的版本更新。当新发布的版本有缺陷时，这种方法就可以避免版本缺陷对用户造成的不良影响。

本文将继续沿用前文使用的示例，在原有配置文件的基础上新增了个别服务的新版本来演示流量是如何切换的（包括基于请求头的路由和加权负载均衡）。

## 1. 基于请求头的路由

----

为了说明基于请求头的路由对微服务产生的影响，首先创建一个新版本的 `service1` 。这里仍然使用 Envoy 仓库中的 [front-proxy](https://github.com/envoyproxy/envoy/tree/master/examples/front-proxy) 示例，修改 [docker-compose.yml](https://github.com/envoyproxy/envoy/blob/master/examples/front-proxy/docker-compose.yml) 文件，添加一个名为 `service1a` 的新服务。

```yaml
  service1a:
    build:
      context: .
      dockerfile: Dockerfile-service
    volumes:
      - ./service-envoy.yaml:/etc/service-envoy.yaml
    networks:
      envoymesh:
        aliases:
          - service1a
    environment:
      - SERVICE_NAME=1a
    expose:
      - "80"
```

为了确保 Envoy 可以发现该服务，需要将该服务添加到 `clusters` 配置项中。

```yaml
  - name: service1a
    connect_timeout: 0.25s
    type: strict_dns
    lb_policy: round_robin
    http2_protocol_options: {}
    hosts:
    - socket_address:
        address: service1a
        port_value: 80
```

为了使新加的服务路由可达，需要在 `match` 配置项中添加一个带有 `headers` 字段的新路由。因为路由规则列表是按顺序匹配的，所以我们需要将该规则添加到路由规则列表的顶部，这样与新规则匹配的包含该头文件的请求就会被转发到新服务，而不包含该头文件的请求仍然被转发到 service1。

```yaml
routes:
- match:
    prefix: "/service/1"
    headers:
      - name: "x-canary-version"
        value: "service1a"
  route:
    cluster: service1a
- match:
    prefix: "/service/1"
  route:
    cluster: service1
- match:
    prefix: "/service/2"
  route:
    cluster: service2
```

然后重启该示例服务：

```bash
$ docker-compose down --remove-orphans
$ docker-compose up --build -d
```

如果客户端发出的请求没有携带头文件，就会收到来自 `service1` 的响应：

```bash
$ curl localhost:8000/service/1

Hello from behind Envoy (service 1)! hostname: d0adee810fc4 resolvedhostname: 172.18.0.2
```

如果请求携带了头文件 `x-canary-version`，Envoy 就会将请求转发到 service 1a。

```bash
$ curl -H 'x-canary-version: service1a' localhost:8000/service/1

Hello from behind Envoy (service 1a)! hostname: 569ee89eebc8 resolvedhostname: 172.18.0.6
```

Envoy 基于头文件的路由功能解锁了[在生产环境中测试开发代码](https://opensource.com/article/17/8/testing-production)的能力。

## 2. 加权负载均衡

----

接下来进一步修改配置来实现对 service1 新版本的增量发布，使用 `clusters` 数组替代原来的 `cluster` 键值对，从而实现将 25% 的流量转发到该服务的新版本上。

```yaml
- match:
    prefix: "/service/1"
  route:
    weighted_clusters:
      clusters:
      - name: service1a
        weight: 25
      - name: service1
        weight: 75
```

然后重启该示例服务：

```bash
$ docker-compose down --remove-orphans
$ docker-compose up --build -d
```

此时如果客户端发出的请求没有携带头文件，就会有 25% 的流量转发到 service 1a。

增量部署是个非常强大的功能，它还可以和监控配合使用，以确保服务的版本差异（或者后端服务的架构差异）不会对该服务的版本更新产生不良影响。如果想模拟新版本的成功发布，可以将 service1a 的权重设置为 `100`，然后所有的流量都会被转发到 service 1a。同样，如果新发布的版本有缺陷，你可以通过将 service1a 的权重设置为 `0` 来回滚到之前的版本。

## 3. 最佳实践

----

学会了如何配置基于请求头的路由和加权负载均衡之后，就可以在生产或测试环境中进行实践了。首先需要将**部署**和**发布**这两个流程分离，部署了新版本之后，你就可以通过配置基于请求头的路由来让你的团队在内部进行测试，同时又不影响用户的使用。一旦测试通过，就可以通过滚动发布模式（逐步增加权重，如 1%，5%，10%，50% ...）来优雅地发布新版本。

通过将**部署**和**发布**这两个流程分离，使用基于请求头的路由在新版本发布之前进行测试，然后通过滚动部署模式来增量发布，你的团队将会从中受益匪浅。


<style>
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
