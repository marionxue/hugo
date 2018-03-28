---
title: "Iptables基础原理之tcp/ip协议"
subtitle: "TCP 协议通信流程"
date: 2016-12-26T09:17:42Z
draft: true
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->
<iframe width="0" height="0" frameborder="no" border="0" marginwidth="0" marginheight="0" src="http://yangchuansheng-netease.daoapp.io/player?type=2&amp;id=405597568&amp;auto=1&amp;height=66"></iframe>

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">1. **IP 首部**</p>
------

<center>![](http://o7z41ciog.bkt.clouddn.com/ipv4header.png)</center>

- `IP Version`：协议版本号，这里指ipv4
- `Header Length`：IP 首部长度
首部长度共设置了4 bit，4 bit的取值范围0-15，由于每一个字段的长度是32位，也就是4个字节，所以首部最长为15 * 4 = 60个字节。
而常见的ip首部长度为20字节，所以在首部长度中更多的是5，4*5=20。

- `Type Of Service`（TOS）：服务类型。
包括 3 bits 的优先权子字段（现在已被忽略），4 bits 的 TOS 子字段和 1 bit 未用但必须设置为0。
4 bits 的 TOS 分别代表：最小时延、最大吞吐量、最高可靠性和和最小费用。
4 bits 中只能有 1 bit 设置为 1。如果所有 4 bits 均为 0，就意味着是一般服务。

图1列出了对不同应用建议的`TOS`值。最后一列给出的是十六进制值，因为这就是后面将要看到的`tcpdump`命令输出。

<center>![服务类型字段推荐值](http://o7z41ciog.bkt.clouddn.com/%E6%9C%8D%E5%8A%A1%E7%B1%BB%E5%9E%8B%E5%AD%97%E6%AE%B5%E6%8E%A8%E8%8D%90%E5%80%BCjpg)</center>
<center><font size=2>图1 服务类型字段推荐值</font></center>

- `Total Length`：整个IP数据报的长度，以字节为单位。
`Total Length` - `Header Length` = data 长度
- `Identification`（`Fragment ID`）：标识字段（段ID）。
当一个IP报文在网上传输的时候，如果两个物理设备所支持的报文大小不相同，那么必须要对报文进行分片。当所有的分片都到达目标主机后，必须要将这些分片合并为一个IP报文，否则没有意义。段ID可以告诉我们哪些分片属于同一个IP报文。
- `DF`：Don't Fragment
- `MF`：More Fragment
- `Fragment Offset`：段偏移。
表示分段的数据报在整个数据流中的位置，即相当于分片数据报的顺序号。
发送主机对第一个数据报的段偏移量置为0，而后续的分片数据报的段偏移量则以网络的`MTU`大小赋值。
段偏移量对于接收方进行数据重组的时候，这是一个关键的字段。
- `Time To Live`（`TTL`）：设置了数据报可以经过的最多`路由器`数。它指定了数据报的生存时间。
- `Protocol`：协议。指定`data`中包含的协议，如TCP、UDP、ICMP。根据它可以识别是哪个协议向`IP`发送数据
- `Header Checksum`：校验和。
报文首部在发送过程中可能会发生差错，所以需要通过校验和来进行验证，一旦验证出现错误，便进行重传。
- `options`：可变长度的可选数据。很少使用。

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">2. **TCP 首部**</p>
------

&emsp;&emsp;要想真正承载应用协议从一个主机到另一个主机，那我们就应该知道两台主机上的哪些`进程`之间在进行通信。所以众多的上层应用协议都是基于`tcp`或者`udp`来完成数据报文的再次封装以标记通信的两个进程。

`tcp`和`udp`都是通过端口号来进行标识，每打开一个端口，就称为打开一个`套接字文件`。
端口号的取值范围一般是 0-65535。在linux主机中，0-1023端口范围只有管理员才有权使用。

<center>![](http://o7z41ciog.bkt.clouddn.com/TCP-header.png)</center>
<center><font size=2>图2 TCP 首部</font></center>

- `Sequence Number`：序列号。
发送方告诉接收方我所发送的这个报文的编号，它表示在这个报文段中的第一个数据字节。
第一次的编号可能是随机，以后每次+1。
序列号是 32 bits 的无符号数，到达$2^{32}-1$后又从0开始。
- `Acknowledgement Number`：确认号。
把对方的序列号+1，并会送给对方，告诉它我收到了。
只有`ACK`标志为1时确认号才有效。
- `Reserved`：保留字段。不常用。
- `URG`：紧急指针（Urgent Pointer）有效。
URG = 1，表示紧急指针有效
URG = 0，表示紧急指针无效
- `PSH`：推送。一旦发生了推送，就意味着这个报文一定不能在缓存中停留，应该立即递给内核，所以这是一个需要内核优先处理的报文。
- `RST`：重置。当连接发生抖动、发生故障的时候，有可能需要进行重置。
- `SYN`：同步请求。我们建立联系的第一个请求报文必须要发送`SYN`。
- `FIN`：断开连接请求。
- `Window Size`：滑动窗口大小。
一次发送一个报文速度很慢，为了提高速度，可以一次发送多个报文，滑动窗口大小决定了一次可以发送多少个报文。
- `TCP Checksum`：校验和。
- `Urgent Pointer`：紧急指针。

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">3. **建立连接**</p>
------

<center>![](http://o7z41ciog.bkt.clouddn.com/tcp%E5%BB%BA%E7%AB%8B%E8%BF%9E%E6%8E%A5.gif)</center>

两台主机，谁也没有跟其他主机通信的时候，大家默认都是`closed`，要让一方能够接收其他主机的请求，它要从`closed`转为`listen`状态。

  1、客户端通过向服务器端发送一个`SYN`来建立一个主动打开，作为三路握手的一部分。客户端把这段连接的序号设定为随机数A。
  
  2、服务器端应当为一个合法的`SYN`回送一个`SYN/ACK`。`ACK`的确认码应为A+1，`SYN/ACK`包本身又有一个随机序号B。
  
  3、最后，客户端再发送一个`ACK`。当服务端受到这个`ACK`的时候，就完成了三路握手，并进入了连接建立状态。此时包序号被设定为收到的确认号A+1，而响应则为B+1。

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">4. **断开连接**</p>
------

那如何断开连接呢？简单的过程如下：

<center>![](http://o7z41ciog.bkt.clouddn.com/tcp%E6%96%AD%E5%BC%80%E8%BF%9E%E6%8E%A5.gif)</center>

**【注意】中断连接端可以是Client端，也可以是Server端。**

假设`Client`端发起中断连接请求，也就是发送`FIN`报文。`Server`端接到`FIN`报文后，意思是说"<font color=red>我Client端没有数据要发给你了</font>"，但是如果你还有数据没有发送完成，则不必急着关闭`Socket`，可以继续发送数据。所以你先发送`ACK`，"<font color=red>告诉`Client`端，你的请求我收到了，但是我还没准备好，请继续你等我的消息</font>"。这个时候`Client`端就进入`FIN_WAIT`状态，继续等待`Server`端的`FIN`报文。当`Server`端确定数据已发送完成，则向`Client`端发送`FIN`报文，"<font color=red>告诉`Client`端，好了，我这边数据发完了，准备好关闭连接了</font>"。`Client`端收到`FIN`报文后，“<font color=red>就知道可以关闭连接了，但是他还是不相信网络，怕`Server`端不知道要关闭，所以发送`ACK`后进入`TIME_WAIT`状态，如果`Server`端没有收到`ACK`则可以重传</font>”。`Server`端收到`ACK`后，"<font color=red>就知道可以断开连接了</font>"。`Client`端等待了2 `MSL` 后依然没有收到回复，则证明`Server`端已正常关闭，那好，我`Client`端也可以关闭连接了。Ok，`TCP`连接就这样关闭了！

整个过程`Client`端所经历的状态如下：

<center>![](http://o7z41ciog.bkt.clouddn.com/0_1312719804oSkK.gif)</center>

而`Server`端所经历的过程如下：

<center>![](http://o7z41ciog.bkt.clouddn.com/0_1312719833030b.gif)</center>

**【注意】** 在`TIME_WAIT`状态中，如果`TCP client`端最后一次发送的ACK丢失了，它将重新发送。`TIME_WAIT`状态中所需要的时间是依赖于实现方法的。典型的值为30秒、1分钟和2分钟。等待之后连接正式关闭，并且所有的资源(包括端口号)都被释放。

**【问题1】**为什么连接的时候是三次握手，关闭的时候却是四次握手？
答：因为当Server端收到Client端的SYN连接请求报文后，可以直接发送SYN+ACK报文。其中ACK报文是用来应答的，SYN报文是用来同步的。但是关闭连接时，当Server端收到FIN报文时，很可能并不会立即关闭SOCKET，所以只能先回复一个ACK报文，告诉Client端，"你发的FIN报文我收到了"。只有等到我Server端所有的报文都发送完了，我才能发送FIN报文，因此不能一起发送。故需要四步握手。

**【问题2】**为什么`TIME_WAIT`状态需要经过2`MSL`(最大报文段生存时间)才能返回到CLOSE状态？
答：虽然按道理，四个报文都发送完毕，我们可以直接进入CLOSE状态了，但是我们必须假象网络是不可靠的，有可以最后一个ACK丢失。所以`TIME_WAIT`状态就是用来重发可能丢失的ACK报文。

整个TCP状态机过程如下：
<center>![](http://o7z41ciog.bkt.clouddn.com/TCP%E7%8A%B6%E6%80%81%E6%9C%BA.jpg)</center>


> (1) 突然有一台主机想成为服务器，被动打开，转化为`listen`状态，等待客户端发起请求<br />
(2) 客户端发起`SYN`请求<br />
(3) 服务端收到`SYN`<br />
(4) 客户端与服务端转化为`connection established`<br />
(5) 双方可以发送数据了<br />
(6) 客户端发送分手请求，自己转化为`FIN WAIT 1`状态，等待对方告诉我<font color=red>可以分手了</font><br />
(7) 服务端收到`SYN`，然后发送给对方`ACK`进行确认，<font color=red>分手就分手</font><br />
(8) 当服务端响应客户端后，服务端状态变为`CLOSE WAIT`<br />
(9) 客户端一旦收到了`ACK`，就要等待对方的`FIN`（整个过程叫`FIN WAIT 2`）<br />
(10) 客户端收到对方的`FIN`后，给对方以`ACK`，等待一段时间（大约2MSL）后，然后转化为`CLOSED`状态<br />
