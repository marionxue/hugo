---
keywords:
- 杨传胜的博客
- istio
- service mesh
- data plane
title: "数据包在 Istio 网格中的生命周期"
subtitle: "从数据包的角度来剖析 Istio 的架构"
description: 通过跟踪一个网络包进入 Istio 网格，完成一系列的交互，然后再从网格出来的整个过程，以此来探索数据包在 Istio 网格中的生命周期。
date: 2018-12-17T16:05:24+08:00
draft: false
categories: "service mesh"
tags: ["istio", "service mesh"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->

众所周知，当我们讨论 Istio 时，性能并不是它最大的痛点，最大的痛点是有时候会出现一些莫名其妙的问题，而我们根本不知道问题出在哪里，也无从下手，在很多方面它仍然是一个谜。你可能已经看过它的官方文档，有的人可能已经尝试使用了，但你真的理解它了吗？

今天就为大家推荐一个高质量的视频，视频中的演讲内容主要通过跟踪一个网络包进入 Istio 网格，完成一系列的交互，然后再从网格出来的整个过程，以此来探索数据包在 Istio 网格中的生命周期。你将会了解到当数据包遇到每个组件时，会如何调用这些组件，这些组件为什么存在，它可以为数据包做些什么，其中还会涉及到数据包在进出网格的过程中是如何调用控制平面的，最后还会告诉你一些调试 Istio 的套路。

{{% video mp4="https://drive.yangcs.net/?/video/Life%20of%20a%20packet%20through%20Istio%20by%20Matt%20Turner.mp4" poster="https://ws4.sinaimg.cn/large/006tNbRwgy1fy9s96fobzj30pu0dcaal.jpg" %}}

视频中的 PPT 下载：<a id="download" href="https://drive.yangcs.net/?/document/Istio%2C%20the%20packet%27s-eye%20view%20-%20kubecon%20NA%202018.pdf"><i class="fa fa-download"></i><span> Download Now</span>
</a>
