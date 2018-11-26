---
title: "深入理解 Kubernetes API Server（一）"
subtitle: "Kubernetes API Server 的架构和行为规范"
date: 2018-11-19T13:42:03+08:00
draft: false
toc: true
categories: "kubernetes"
tags: ["kubernetes"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->

<code data-gist-id="efdf2c6988dc6787108787c01154b2da"></code>

<p id="div-border-left-red">
<strong>原文地址：</strong><a href="https://medium.com/@dominik.tornow/kubernetes-api-server-part-i-3fbaf2138a31" target="_blank">Kubernetes API Server, Part I</a>
<br />
<strong>作者：</strong></strong><a href="https://medium.com/@chenopis" target="_blank">Andrew Chen</a>，<a href="https://medium.com/@dominik.tornow" target="_blank">Dominik Tornow</a>
<br />
<strong>译者：</strong>杨传胜
</p>

![](https://ws3.sinaimg.cn/large/006tNbRwgy1fxdbyu51xbj31fp0j6ad0.jpg)

<center><p id=small>概念架构</p></center>

`Kubernetes` 是一个用于在一组节点（通常称之为集群）上托管容器化应用程序的容器编排引擎。本系列教程旨在通过系统建模的方法帮助大家更好地理解 `Kubernetes` 及其基本概念。

本文使用的语言是 [Alloy](http://alloytools.org/)，这是一种基于一阶逻辑表达结构和行为的[规范语言](https://www.wikiwand.com/zh-hans/%E8%A7%84%E7%BA%A6%E8%AF%AD%E8%A8%80)。文中我对每一段 Alloy 规范语言表达的意思都作了简明的描述。

> **规约语言**（英语：Specification language），或称**规范语言**，是在计算机科学领域的使用的一种形式语言。编程语言是用于系统实现的、可以直接运行的形式语言。与之不同，规约语言主要用于系统分析和设计的过程中。

本系列文章总共分为三个部分：

+ 第一部分描述了 `API Server` 的架构和行为
+ 第二部分描述了 `Kubernetes API`
+ 第三部分描述了 Kubernetes 的对象存储

本文主要讲述第一部分的内容。

## <span id="inline-toc">1.</span> 前言——什么是 API Server {#the-term-apiserver}

----

“API Server” 这个术语很宽泛，涉及了太多的概念，本文将尝试使用 `API Server`，`Kubernetes API` 和 `Kubernetes 对象存储` 这三个不同的术语来明确表示各个概念。

<div class="gallery">
    <a href="https://ws2.sinaimg.cn/large/006tNbRwgy1fxc8pwh73mj30tu0fr3zn.jpg" title="图 1：API Server，Kubernetes API 和 Kubernetes 对象存储">
    <img src="https://ws2.sinaimg.cn/large/006tNbRwgy1fxc8pwh73mj30tu0fr3zn.jpg">
    </a>
</div>

<center><p id=small>图 1：API Server，Kubernetes API 和 Kubernetes 对象存储</p></center>

+ <span id=inline-purple>Kubernetes API</span> 表示处理读取和写入请求以及相应地查询或修改 Kubernetes 对象存储的组件。
+ <span id=inline-purple>Kubernetes 对象存储</span> 表示持久化的 Kubernetes 对象集合。
+ <span id=inline-purple>API Server</span> 表示 Kubernetes API 和 Kubernetes 对象存储的并集。

## <span id="inline-toc">2.</span> API Server 详解 {#the-apiserver}

----

**Kubernetes API Server** 是 Kubernetes 的核心组件。从概念上来看，Kubernetes API Server 就是 Kubernetes 的数据库，它将集群的状态表示为一组 **Kubernetes 对象**，例如 `Pod`、`ReplicaSet` 和 `Deployment` 都属于 Kubernetes 对象。

<div class="gallery">
    <a href="https://ws3.sinaimg.cn/large/006tNbRwgy1fxchxltk62j30hp03jaa8.jpg" title="图 2：Kubernetes API Server & Kubernetes 对象">
    <img src="https://ws3.sinaimg.cn/large/006tNbRwgy1fxchxltk62j30hp03jaa8.jpg">
    </a>
</div>

<center><p id=small>图 2：Kubernetes API Server & Kubernetes 对象</p></center>

Kubernetes API Server 存在多个版本，每一个版本都是它在不同时间段的快照，类似于 git 仓库：

+ Kubernetes API Server 具有属性 `rev`，是 Kubernetes API Server 版本的缩写。该属性表示的是 Kubernetes API Server 在每个时间戳的快照。
+ Kubernetes 对象具有属性 `mod`，是 Kubernetes 对象版本的缩写。该属性表示的是该对象最后一次被修改的快照。

但实际上 Kubernetes API Server 在实现上会限制快照的时间长度，并且默认情况下会在 5 分钟后丢弃快照。

<div class="gallery">
    <a href="https://ws1.sinaimg.cn/large/006tNbRwgy1fxciw5ywkkj30um044gm9.jpg" title="图 3：Kubernetes API Server & 版本">
    <img src="https://ws1.sinaimg.cn/large/006tNbRwgy1fxciw5ywkkj30um044gm9.jpg">
    </a>
</div>

<center><p id=small>图 3：Kubernetes API Server & 版本</p></center>

Kubernetes API Server 暴露了一个不支持事务性语义的 CRUD （`Create/Read/Update/Delete`）接口：

+ 保证**写入请求**是针对最新版本执行的，并相应地增加版本号。
+ 但不保证**读取请求**是针对最新版本执行的，这主要取决于 API Server 的安装与配置方式。

缺乏事务性语义会导致经典的[竞争危害](https://www.wikiwand.com/zh-hans/%E7%AB%B6%E7%88%AD%E5%8D%B1%E5%AE%B3)现象，如非确定性写入。

缺乏 `read-last-write` 语义会导致两个截然不同的后果，即过期读取和无序读取：

+ <span id=inline-purple>过期读取（Stale reads）</span> 指的是读取请求针对的不是最新版本的现象，因此会产生“过期”响应。
+ <span id=inline-purple>无序读取（Out-of-order reads）</span> 指的是在两个连续的读取请求中，第一个请求读取的是较高版本，而第二个请求读取的是较低版本，因此会产生无序响应。

<div class="gallery">
    <a href="https://ws3.sinaimg.cn/large/006tNbRwgy1fxcjti2wl0j31jk0aoac9.jpg" title="图 4：读取">
    <img src="https://ws3.sinaimg.cn/large/006tNbRwgy1fxcjti2wl0j31jk0aoac9.jpg">
    </a>
</div>

<center><p id=small>图 4：读取</p></center>

### 防护 token 和新鲜度 token {#fencing-and-freshness-tokens}

客户端可以使用属性 `rev` 作为用于写入操作的防护 token（`fencing tokens`），以此来抵消丢失的事务性语义。或者作为用于读取操作的新鲜度 token（`freshness tokens`），以此来抵消丢失的 `read-last-write` 语义。

<div class="gallery">
    <a href="https://ws3.sinaimg.cn/large/006tNbRwgy1fxckathpzcj31f40azdhw.jpg" title="图 5：防护 token">
    <img src="https://ws3.sinaimg.cn/large/006tNbRwgy1fxckathpzcj31f40azdhw.jpg">
    </a>
</div>

<center><p id=small>图 5：防护 token</p></center>

在执行写入操作时，客户端使用 `rev` 或 `mod` 作为防护 token。客户端指定期望的 `rev` 或 `mod` 值，但只有当前 `rev` 或 `mod` 值等于期望值时，API Server 才会处理该请求。这一过程被称为乐观锁定（optimistic locking）。

> 图 5 中客户端期望的 `rev` 值为 n，而当前的 `rev` 值为 n+1，与期望不符，因此 API Server 不处理该请求，`rev` 值仍然保持为 n+1。

<div class="gallery">
    <a href="https://ws1.sinaimg.cn/large/006tNbRwgy1fxckvkwm1ij31jk0ao40u.jpg" title="图 6：新鲜度 token">
    <img src="https://ws1.sinaimg.cn/large/006tNbRwgy1fxckvkwm1ij31jk0ao40u.jpg">
    </a>
</div>

<center><p id=small>图 6：新鲜度 token</p></center>


在执行读取操作时，客户端使用 `rev` 或 `mod` 作为新鲜度 token，该 token 用来确保读取请求返回的结果不早于新鲜度 token 的值指定的结果。

## <span id="inline-toc">3.</span> 架构规范 {#structural-specification}

----

{{% gist "dtornow/efdf2c6988dc6787108787c01154b2da" %}}

+ Kubernetes API Server 有一组 Kubernetes 对象和一个 `rev` 属性。
+ Kubernetes 对象具有 [kind](https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#types-kinds)，[name](https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata)，[namespace](https://github.com/kubernetes/community/blob/master/contributors/devel/api-conventions.md#metadata) 和 mod 这几个属性。
+ 对象由其 kind，name 和 namespace 三元组来标识。
+ API Server 中任何两个不同的 Kubernetes 对象都不可能具有相同的 kind，name 和 namespace 三元组。

## <span id="inline-toc">4.</span> 行为规范 {#behavioral-specification}

----

从概念上来看，Kubernetes API Server 提供了写入接口和读取接口。
其中写入接口将所有更改状态的命令组合在一起，读取接口将所有查询状态的命令组合在一起。

<div class="gallery">
    <a href="https://ws3.sinaimg.cn/large/006tNbRwgy1fxcli4vrpsj31bc0dajsu.jpg" title="图 7：写入和读取接口">
    <img src="https://ws3.sinaimg.cn/large/006tNbRwgy1fxcli4vrpsj31bc0dajsu.jpg">
    </a>
</div>

<center><p id=small>图 7：写入和读取接口</p></center>

### 写入接口 {#the-write-interface}

写入接口提供创建、更新和删除对象的命令。

{{% gist "dtornow/31e1be0478931422d5a687b24679a42e" %}}

每一个 **Command** 表示一个状态转换：将 API Server 从当前状态转换到下一个状态。每个命令都会增加 API Server 的版本。

{{% gist "dtornow/f4b3d70341bc4425d51c0a64ebb864b0" %}}

此外，每个命令都会生成一个事件。**Event** 表示命令执行的持久化可查询记录。

<div class="gallery">
    <a href="https://ws4.sinaimg.cn/large/006tNbRwgy1fxcltkebzkj30yu0e4abl.jpg" title="图 8：API Server，命令和事件">
    <img src="https://ws4.sinaimg.cn/large/006tNbRwgy1fxcltkebzkj30yu0e4abl.jpg">
    </a>
</div>

<center><p id=small>图 8：API Server，命令和事件</p></center>

**图 8** 描述了 API Server 的一系列命令和结果状态转换。总共分为三层结构，从下往上依次表示为 API Server，命令和事件。

Kubernetes API Server 的设计和实现方式保证了 API Server 在任何时间点的当前状态等于事件流到该时间点的聚合状况，这种模式也被称为 [事件溯源（event sourcing）](https://docs.microsoft.com/en-us/azure/architecture/patterns/event-sourcing)。

```bash
state = reduce(apply, events, {})
```

#### 创建命令 {#create-command}

{{% gist "dtornow/0bcbaad099158b2d6fc3296b1764c819" %}}

+ 创建命令将 Kubernetes 对象添加到 API Server，并将对象的 `mod` 值设置为 API Server 的 `rev` 值。
+ 如果想要创建的对象违反了 API Server 的唯一性约束，则会拒绝创建命令。

{{% gist "dtornow/256345b0f4bc31ff240b80a720f7f7cd" %}}

+ 每个创建命令都会生成一个持久且可查询的 `Created Event`，event 的 `object` 字段引用创建的 Kubernetes 对象。

#### 更新命令 {#update-command}

{{% gist "dtornow/7ea44fa165324d23c8722134ff7ec4f4" %}}

+ 更新命令将更新 API Server 中的 Kubernetes 对象，并将对象的 `mod` 值设置为 API Server 的 `rev` 值。
+ 如果命令的 `mod` 值与对象的 `rev` 值不匹配，则拒绝更新命令。这里的 `mod` 用作防护 token。

{{% gist "dtornow/10e49aac7e90739300bc35f6e3240638" %}}

+ 每个更新命令都会生成一个持久且可查询的 Updated Event，event 的 object 字段引用新的 Kubernetes 对象。

#### 删除命令 {#delete-command}

{{% gist "dtornow/99be5e54b2d7af17d9bca420321dd86c" %}}

+ 删除命令从 API Server 中删除 Kubernetes 对象。
+ 如果命令的 `mod` 值与对象的 `mod` 值不匹配，则拒绝删除命令。这里的 `mod` 用作防护 token。

{{% gist "dtornow/70bdf6b117e35a7f084fb28d6c0b7a58" %}}

+ 每个删除命令都会生成一个持久且可查询的 Deleted Event，event 的 object 字段引用已删除的 Kubernetes 对象。

### 读取接口 {#the-read-interface}

Kubernetes API 读取接口提供两个字接口，一个接口与对象相关，另一个与事件相关。

#### 对象相关的子接口 {#object-related-interface}

对象相关的子接口提供读取对象和对象列表的命令。

{{% gist "dtornow/ca656ee97a26889332a578b2d26c6205" %}}

+ 读取对象的请求接收 kind、name 和 namespace 三元组，同时也会接收用作新鲜度 token 的 `min` 参数。
+ API Server 至少在由 `min` 指定的 API Server 的版本处返回匹配的 Kubernetes 对象。

#### 事件相关的子接口 {#event-related-interface}

事件相关的子接口提供命令以读取关于对象和对象列表的事件。

{{% gist "dtornow/8787bfaca9813192e118fd01ba0a53db" %}}

+ Watch 对象的请求接收 kind、name 和 namespace 三元组，同时也会接收用作新鲜度 token 的 `min` 参数。
+ API Server 从指定的 API Server 版本开始返回所有匹配的事件。

{{% gist "dtornow/359321900d058554bb80a6001306e9b2" %}}

+ Watch List 对象的请求接收 kind、name 和 namespace 三元组，同时也会接收用作新鲜度 token 的 min 参数。
+ API Server 从指定的 API Server 版本开始返回所有匹配的事件。

#### 例子 {#example}

对象相关的子接口与事件相关的子接口一起组成了 Kubernetes 中广泛使用的有效查询机制，例如在 Kubernetes 控制器中就用到了这种机制。

通过这种机制，客户端可以先请求一次当前状态，然后订阅后续事件流，而不是重复轮询对象或对象列表的当前状态。

```bash
pods, rev := request-object-list(kind="pods", namespace="default")
for e in request-watch-list(kind="pods", namespace="default", rev)
  pods := apply(pods, e)
```

通过将读取请求最初返回的 Kubernetes API Server 版本线程化到 watch 请求，可以保证客户端能够接收到读取和写入请求之间以及之后发生的任何事件。

这种实现机制可以确保客户端的状态与 API Server 的状态保持最终一致性。

## <span id="inline-toc">5.</span> 总结 {#conclusion}

----

本文描述了 Kubernetes API Server 的架构和行为。设计和实现一个适当的客户端的关键部分是正确使用  Kubernetes API Server 的版本和 Kubernetes 对象的版本作为防护 token 和新鲜度 token。

下一篇文章将会为大家介绍 Kubernetes API 和 Kubernetes 对象存储。

## <span id="inline-toc">6.</span> 后记 {#about-this-post}

----

本系列文章是 CNCF，Google 和 SAP 之间合作努力的结果，旨在促进大家对 Kubernetes 及其基本概念的理解。
