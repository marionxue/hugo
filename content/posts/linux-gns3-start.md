---
title: "Linux 下 gns3 网络模拟器配置"
subtitle: "配置使用思科网络模拟器"
date: 2017-01-23T11:42:11Z
draft: true
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=0 height=0 src="//music.163.com/outchain/player?type=2&id=32507038&auto=1&height=66"></iframe>

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">1. **GNS3 简介**</p>
------

<p markdown="1" style="display: block;padding: 10px;margin: 10px 0;border: 1px solid #ccc;border-top-width: 5px;border-radius: 3px;border-top-color: #2780e3;">
<code>GNS3</code> 是一款具有图形化界面可以运行在多平台（包括 Windows, Linux, and MacOS 等）的网络虚拟软件。Cisco 网络设备管理员或是想要通过 <code>CCNA</code>,<code>CCNP</code>,<code>CCIE</code> 等 Cisco 认证考试的相关人士可以通过它来完成相关的实验模拟操作。同时它也可以用于虚拟体验 Cisco 网际操作系统 IOS 或者是检验将要在真实的路由器上部署实施的相关配置。
</p>

<center>![](http://o7z41ciog.bkt.clouddn.com/gns3.png)</center>

`Windows` 平台下的安装配置非常简单，下载一体化的安装包安装就可以了。但是考虑系统的资源和兼容性，`linux` 平台是最好的选择，以下的安装配置基于 `Archlinux` 的 64 位系统和`GNS1.5.2`版本。

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">2. **GNS3 安装**</p>
------

### 安装Python3
新版本的 `GNS3` 使用的是 `python3`（最好是 `python3.3` 以上版本）

```bash
$ sudo pacman -S python
```

### 安装 sip 包

`sip` 包是 `python` 用于调用的扩展库，详情参考：
[http://www.riverbankcomputing.com/software/sip/intro](http://www.riverbankcomputing.com/software/sip/intro)。

如果SIP没有安装或GNS3无法正确调用，它在启动的时候会提示找不到 SIP 或是调用 SIP 失败。

```bash
$ sudo pacman -S sip
```

### 安装 pyqt4 包

```bash
$ sudo pacman -S python-pyqt4
```

### 安装 `pip` 支持包
`pip` 是 `python` 下安装扩展包的工具，`GNS3` 需要调用很多的 `python` 扩展组件，可以通过以下指令安装。`pip` 要和 `python` 的版本对应。

```bash
$ sudo pacman -S python-pip
```

### 安装 `GNS3`

可以通过 `yaourt` 安装，也可以通过 `pip` 指令方式安装，以下内容以 `yaourt` 方式安装。

注意：`gns3-server` 与 `gns3-gui` 的默认配置文件在 home 目录下，比如我的配置文件在 `/home/yang/.config/GNS3/` 目录下

```bash
$ yaourt -S gns3-server
```

- 编写 gns3-server 服务脚本

```bash
$ vim /usr/lib/systemd/system/gns3-server.service
[Unit]
Description=GNS3 server
Wants=network-online.target
After=network.target network-online.target

[Service]
Type=forking
User=yang
Group=users
ExecStart=/usr/sbin/gns3server --config /home/yang/.config/GNS3/gns3_server.conf --local --log /home/yang/.config/GNS3/gns3.log \
 --pid /home/yang/.config/GNS3/gns3.pid --daemon
Restart=on-abort
PIDFile=/home/yang/.config/GNS3/gns3.pid

[Install]
WantedBy=multi-user.target
```

```bash
$ yaourt -S gns3-gui
```

报错：AttributeError: module 'aiohttp.web' has no attribute 'RequestHandler'

解决方案：强制安装指定版本的 `pyton` 模块 `aiohttp`

```bash
$ pip install aiohttp==1.1.6
```

### 安装 `dynamips`

`Dynamips` 的原始名称为 `Cisco 7200 Simulator`，源于 `Christophe Fillot` 在2005年8月开始的一个项目，其目的是在传统的 PC 机上模拟（emulate）Cisco 的 7200 路由器。发展到现在，该模拟器已经能够支持 Cisco 的 3600 系列（包括3620，3640，3660），3700 系列（包括3725，3745）和 2600 系列（包括2610到2650XM，2691）路由器平台。

```bash
$ yaourt -S dynamips
```

### 启动GNS3

- 修改gns3-server的配置文件，将 `host` 的值改为 `127.0.0.1`。

```bash
$ vim /home/yang/.config/GNS3/gns3_server.conf
[Server]
host = 127.0.0.1
port = 3080
--snip--
```

- 启动gns3-server服务。

```bash
$ systemctl start gns3-server
```

- 如果所有的组件都已正常安装，接下来在图形界面下的终端输入 `gns3` 就可以启动应用了。

<center>![](http://o7z41ciog.bkt.clouddn.com/%E5%B7%A5%E4%BD%9C%E5%8C%BA%201_432.png)</center>

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">2. **GNS3 配置**</p>
------

### GNS3 基本配置

点击“`edit`”-“`preferences`”找到“`general`”检查相关设置是否正确，可以根据实际系统的配置和自己的喜好设置，例如“`console application`”中我把 `telnet` 的指令设成 `Gnome terminal`,设置好后如图所示。

<center>![](http://o7z41ciog.bkt.clouddn.com/gns3-console%E8%AE%BE%E7%BD%AE.png)</center>

点击“`edit`”-“`preferences`”找到“`server`”主要用于设置系统和 `console` 绑定的端口。通过设定相应的端口，远程用户可以 `telnet` 主机的指定端口进行配置。

<center>![](http://o7z41ciog.bkt.clouddn.com/gns3-server.png)</center>

### 配置IOS路由

`gns3` 通过图形界面调用 `dynamips` 来实现对 `cisco` 路由器的模拟操作，它可以模拟的设备可以参考 `dynamips` 的指令说明。

cisco 路由器的映像可以通过各种不同的方式获取，网上有很多这样的下载地址。这里给出一个 ios 镜像比较全的地址：[http://www.networkvn.net/2014/06/cisco-ios-image-for-gns3.html](http://www.networkvn.net/2014/06/cisco-ios-image-for-gns3.html)

这是我看到过最全的ios 站点，俄国人FTP站点收集的：[http://sobek.su/Cisco/](http://sobek.su/Cisco/)

经常用到的镜像可以从我的 dropbox 里下载：[ios](https://www.dropbox.com/sh/0g6wjuq0kw4x9by/AAAAegYzrhB4uayzm9d0F2oba?dl=0)

- 点击“`edit`”-“`preferences`”找到“`dynamips`”检查相关设置是否正确，然后选取“`IOS routers`”找到已解压好的IOS映像，设置好后如图所示。

<center>![](http://o7z41ciog.bkt.clouddn.com/Preferences_435.png)</center>

这里需要指定3个地方： 【镜像文件】、【平台】、【型号】，然后 Apply。

很多人对于型号可能有疑问？ 3620, 3640 有什么差异呢？  不同之处在于支持多少板卡。3620（2个插槽），3640（4个插槽），3660（6个插槽）。

注意，记得点击"保存"，然后回到刚才的界面，我们可以看到，Router `c3640` 可选了。

- 添加模块

我们知道cisco路由器采用模块化的结构，路由器上面有额外的插槽，这些插槽可以安装各种模块，以提供更多的端口或其他东西，悲催的事儿就是当你需要添加更多的模块时，你必须为每个模块支付相应的费用，也就是按模块收费。
<center>![](http://o7z41ciog.bkt.clouddn.com/wKioL1QFRSDytnjOAAHgwQqfNBg933.jpg)</center>

我们可以拖拽左侧相应的设备（路由器或交换机）至工作区，然后对其 `右键` - `配置`， 在 `solt` 中选择合适的模块。
<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project-%20-%20GNS3_447.png)</center>

可以按照实验需求自行添加所需模块，T 结尾的为 `Serial 接口`，E 为 `Ethernet 接口`，FE 为 `fast-Ethernet 接口`。
那么各个模块都是什么含义呢？

`光口`：SX(传输距离550m)、LX（10km）、ZX(70km)

`电口`：TX

`网络模块`： NM(network module)

> `常用模块`：

> - NM-1FE-TX ----> 快速以太网
- NM-16ESW ----> 16口以太网交换机模块
- NM-4T ----> 2M线端口，同轴电缆

<br \>
需要注意的是 `Idle-PC` 值的选取，只有配置了合适的 `idle-pc` 值，`dynamips` 的运行才正常（CPU的值在 `20%` 以内），如果 CPU 占用过高可以重新获取 `idle-pc` 值。

<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project-%20-%20GNS3_436.png)</center>

<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project-%20-%20GNS3_437.png)</center>

![](http://o7z41ciog.bkt.clouddn.com/top.png)

回到 `gns3` 界面选择刚配置好的路由器（例如 `C3640`）拖至中间空白区域，然后选中它右击“`start`”启动，启动后可以选择“`console`”进入配置模式。

<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project-%20-%20GNS3_440.png)</center>

### 配置vpcs

`vpcs` 主要用来模拟 `PC` 的网络操作，它的功能最简单，只有基本的网络指令，没有 `qemu` 下的 `tinycore` 的功能多。但是 `vpcs` 占用的资源更少，启动速度更快。需要注意的是 `vpcs` 没法单独启动，一定要将网线连接后才可以进入 `console` 界面。[http://sourceforge.net/projects/vpcs/](http://sourceforge.net/projects/vpcs/)

安装也很简单，如下所示：

```bash
$ yaourt -S vpcs
```

安装成功后，在gns3的设置界面选取 `VPCS` 的选项，找到已经编译好的 `vpcs` 执行文件，如下图所示。
<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project%20-%20GNS3_441.png)</center>

注意：启动 `vpcs` 之前，必须要把 `VPCS` 和其他设备用网线连接起来，不然会报错 Server error from http://127.0.0.1:3080: PC1: This VPCS instance must be connected in order to start

<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project-%20-%20GNS3_446.png)</center>

- `vpcs` 必须连接路由的 `Fast-Ethernet` 接口

### Docker 支持

`GNS3 1.5` 中增加了对 `Docker` 的支持。它的目标不是模拟生产中容器的部署，而是为了替代笨重的 `qemu` 和 `vpcs` 用来模拟 pc。
<br \>

- 在使用 Docker 之前，需要先安装ubridge

```bash
$ yaourt -S ubridge
```
- 添加一个 Docker 模板

点击 `Preferences` - `Docker containers` - `New`，新建一个Docker 容器模板。

<center>![](http://o7z41ciog.bkt.clouddn.com/79452a76c6a569b251929440a96b3c31.jpg)</center>
<br \>

选择一个镜像。你可以选择 "`Existing image`"，用的是本机已经存在的镜像，也可以选择 "`New image`"，它会自动去官方仓库拉取你需要的镜像。

<center>![](http://o7z41ciog.bkt.clouddn.com/d895f4c984286d4169008eb95af66617.jpg)</center>
<br \>

选择一个启动命令，通常我们只想要一个 `shell`。

<center>![](http://o7z41ciog.bkt.clouddn.com/655343e3e4d84b1d54764c4bec8ca397.jpg)</center>
<br \>

设置环境变量。容器启动后你会在容器里看到你设置的这些环境变量。

<center>![](http://o7z41ciog.bkt.clouddn.com/711e7a83854868f97f4987fac0e0fea8.jpg)</center>
<br \>

设置好了之后，你可以将容器模板拖到中间区域，如果这个镜像在本地不存在，就会自动从官方仓库拉取这个镜像。

<center>![](http://o7z41ciog.bkt.clouddn.com/Unsaved%20project-%20-%20GNS3_448.png)</center>
<br \>

现在你可以启动这个容器并打开 `console`。

<center>![](http://o7z41ciog.bkt.clouddn.com/alpine-1_449.png)</center>

需要注意的是：一般情况下，容器会启动一个后台守护进程并开放一些端口，但在 GNS3 中并不是这样，因为我们需要到容器中去手动设置 ip。

### 网络抓包配置

抓包主要作用是查找、定位网络通讯中存在的问题，一般情况下可以是额头 `tcpdump` 或是 `wireshark`。`tcpdump` 主要的操作方式通过命令行，`wireshark` 提供图形界面，操作及查看方式更加直观，这里以 `wireshark` 为例。

```bash
$ pacman -S wireshark-gtk
```

安装成功后，`GNS3` 的配置如下图所示。

<center>![](http://o7z41ciog.bkt.clouddn.com/Preferences_450.png)</center>

在需要抓包的设备上右键选择“`Capture`”进行抓包操作，如果设备有多块网卡会提示选择那块。
