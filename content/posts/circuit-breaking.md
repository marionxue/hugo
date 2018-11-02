---
title: "Envoy 熔断器的原理和使用"
subtitle: "使用熔断器来预防服务出现雪崩效应"
date: 2018-07-13T09:22:49Z
draft: false
toc: true
categories: "service mesh"
tags: ["envoy", "service mesh"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->

在微服务领域，各个服务之间经常会相互调用。如果某个服务繁忙或者无法响应请求，将有可能引发集群的大规模级联故障，从而造成整个系统不可用，通常把这种现象称为 <span id="inline-purple">服务雪崩效应</span>。为了应对这种情况，可以使用熔断器（circuit breaking）。

<span id="inline-purple">熔断器</span> 是分布式系统的关键组件，默认情况下处于关闭状态，这时请求被允许通过熔断器。它调用失败次数积累，如果当前健康状况低于设定阈值则启动熔断机制，这时请求被禁止通过。这样做可以实现更优雅的故障处理，并在问题被放大之前做出及时的响应。你可以选择在基础架构层面实现熔断机制，但熔断器本身会很容易受到故障的影响。为了更好地实现熔断机制，可以在 Envoy 的网络层面配置熔断器，这样做的好处是 `Envoy` 在网络级别强制实现断路，而不必为每个应用程序单独配置或编程。

## 1. 熔断器配置

----

Envoy 支持各种类型的完全分布式（非协调的）熔断，设置熔断时，需要考虑系统的具体情况，可以通过向 Envoy 的 `clusters` 配置项中添加 `circuit_breakers` 来为 Envoy 配置熔断器。下面是一个简单的示例：

```yaml
circuit_breakers:
  thresholds:
    - priority: DEFAULT
      max_connections: 1000
      max_requests: 1000
    - priority: HIGH
      max_connections: 2000
      max_requests: 2000
```

+ <span id="inline-blue">thresholds</span> : 阈值允许我们定义服务响应的流量类型的优先级和限制。
+ <span id="inline-blue">priority</span> : 优先级是指熔断器如何处理定义为 `DEFAULT` 或 `HIGH` 的路由。示例中的设置表示将任何不应该在长连接队列中等待的请求设置为 HIGH（例如，用户在购物网站上提交购买请求或保存当前状态的 POST 请求）。
+ <span id="inline-blue">max_connections</span> : Envoy 将为上游集群中的所有主机建立的最大连接数，默认值是 `1024`。实际上，这仅适用于 HTTP/1.1集群，因为 HTTP/2 使用到每个主机的单个连接。
+ <span id="inline-blue">max_requests</span> : 在任何给定时间内，集群中所有主机可以处理的最大请求数，默认值也是 1024。实际上，这适用于仅 HTTP/2 集群，因为 HTTP/1.1 集群由最大连接断路器控制。

## 2. 基本的熔断策略

----

由于 `HTTP/1.1` 协议和 `HTTP/2` 协议具有不同的连接行为（HTTP/1.1 : 同一个连接只能处理一个请求；HTTP/2 : 同一个连接能并发处理多个请求，而且并发请求的数量比HTTP1.1大了好几个数量级），使用不同协议的集群将各自使用不同的配置项：

+ **HTTP/1.1 协议** : 使用 max_connections。
+ **HTTP/2 协议** ： 使用 max_requests。

这两个配置项都可以很好地实现熔断机制，主要取决于两个指标：服务的请求/连接数量和请求延时。例如，具有 1000个请求/second 和平均延迟 2 秒的 HTTP/1 服务通常会在任何给定时间内打开 `2000` 个连接。由于当存在大量非正常连接时熔断器会启动熔断机制，因此建议将参数 max_connections 的值最少设置为 `10 x 2000`，这样当最后 10 秒内的大多数请求未能返回正确的响应时就会打开熔断器。当然，具体的熔断器配置还得取决于系统的负载以及相关服务的具体配置。

## 3. 高级熔断策略

----

上面讨论了一些基本的熔断策略，下面将介绍更高级的熔断策略，这些高级熔断策略可以为你的网络基础架构增加更多的弹性。

### 基于延迟设置熔断

如上所述，熔断器最常见的用例之一就是预防服务响应过慢但未完全瘫痪时引发的故障。虽然 Envoy 没有直接提供熔断器的延迟配置项，但可以通过自动重试配置项来模拟延迟。自动重试配置项通过 `max_retries` 字段定义，表示在任何给定时间内，集群中所有主机可以执行的最大重试次数。

### 基于长连接重试队列设置熔断

由于重试有可能将请求流量增加到两倍以上甚至更多，因此通过 `max_retries` 参数可以防止服务因为过多的重试而过载。建议将此参数的值设置为服务通常在 10 秒窗口中处理的请求总数的一小部分，最好不要将重试次数设置为与服务在 10 秒窗口中处理的请求总数差不多。

----

<center>![](http://o7z41ciog.bkt.clouddn.com/qrcode_for_wechat_big.jpg)</center>
<center>扫一扫关注微信公众号</center>

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
