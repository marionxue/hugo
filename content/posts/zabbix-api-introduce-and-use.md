---
title: "Zabbix Api 简介和使用"
subtitle: "Python 调用 Zabbix 的 Api"
date: 2017-01-05T10:19:18Z
draft: false
categories: "python"
tags: ["python"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=0 height=0 src="//music.163.com/outchain/player?type=2&id=22712173&auto=1&height=66"></iframe>

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">1. **API简介**</p>
------

`Zabbix API` 开始扮演着越来越重要的角色，尤其是在集成第三方软件和自动化日常任务时。很难想象管理数千台服务器而没有自动化是多么的困难。

`Zabbix API` 为批量操作、第三方软件集成以及其他作用提供可编程接口。

`Zabbix API` 是在1.8版本中开始引进并且已经被广泛应用。所有的Zabbix移动客户端都是基于API，甚至原生的WEB前端部分也是建立在它之上。

`Zabbix API` 中间件使得架构更加模块化也避免直接对数据库进行操作。它允许你通过 `JSON RPC` 协议来创建、更新和获取Zabbix对象并且做任何你喜欢的操作【当然前提是你拥有认证账户】。

`Zabbix API` 提供两项主要功能：

- 远程管理 `Zabbix` 配置
- 远程检索配置和历史数据

> API 采用JSON-RPC实现。这意味着调用任何函数，都需要发送POST请求，输入输出数据都是以JSON格式。

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">1. **Zabbix API的使用流程**</p>
------

### 使用 `API` 的基本步骤

<p markdown="1" style="display: block;padding: 10px;margin: 10px 0;border: 1px solid #ccc;border-top-width: 5px;border-radius: 3px;border-top-color: #2780e3;">
1. 准备JSON对象，它描述了你想要做什么（创建主机，获取图像，更新监控项等）。<br />
2. 采用POST方法向 <code>http://example.com/zabbix/api_jsonrpc.php</code> 发送此JSON对象，提供用户名和密码，<code>HTTP Header Content-Type</code> 必须为【application/jsonrequest，application/json-rpc，application/json】其中之一。
<code>http://example.com/zabbix/</code> 是Zabbix前端地址。<code>api_jsonrpc.php</code> 是调用API的PHP脚本。可在安装可视化前端的目录下找到。<br />
3. 获取 SESSIONID。<br />
4. 通过 SESSIONID 建立后续的连接。<br />
5. 提交 POST 数据，格式为 JSON，其中放对应的方法，获取需要的数据。
</p>

### 使用 `curl` 模拟 API 的使用

**获取 `SESSIONID`**

```bash
$ curl -s -X POST -H 'Content-Type:application/json' -d '
> {
>    "jsonrpc": "2.0",
>    "method": "host.get",
>    "params": {
>       "user": "Admin",
>       "password": "zabbix"
>    },
>    "id": 1
>    }' http://172.16.241.130/zabbix/api_jsonrpc.php | python -m json.tool
{
    "jsonrpc": "2.0",
    "result": "581cc92624202bddaeff3a90cca181dc",
    "id": 1
}

```

**用获取的 `SESSIONID` 去调用 API 的 `host.get` 方法请求 hostid**

```bash
$ curl -s -X POST -H 'Content-Type:application/json' -d '
> {
>    "jsonrpc": "2.0",
>    "method": "host.get",
>    "params": {
>       "output": ["hostid"]
>    },
>    "auth": "581cc92624202bddaeff3a90cca181dc",
>    "id": 1
>    }' http://172.16.241.130/zabbix/api_jsonrpc.php | python -m json.tool
{
    "jsonrpc": "2.0",
    "result": [
        {
            "hostid": "10084"
        }
    ],
    "id": 1
}
```

参数解释：

- `"jsonrpc": "2.0"`-这是标准的 JSON RPC 参数以标示协议版本。所有的请求都会保持不变。
- `"method": "method.name"`-这个参数定义了真实执行的操作。例如：host.create、item.update 等等
- `"params"`-这里通过传递JSON对象来作为特定方法的参数。如果你希望创建监控项，`"name"` 和 `"key_"` 参数是需要的，每个方法需要的参数在 Zabbix API 文档中都有描述。
- `"id": 1`-这个字段用于绑定 JSON 请求和响应。响应会跟请求有相同的 "id"。在一次性发送多个请求时很有用，这些也不需要唯一或者连续。
- `"auth": "581cc92624202bddaeff3a90cca181dc"`-这是一个认证令牌【authentication token】用以鉴别用户、访问API。这也是使用API进行相关操作的前提-获取认证ID。

### 使用 `python` 模拟 API 的使用

这里我们使用python 3。

#### 安装必要模块

要使用 zabbix 的 API 接口，需要用 pip 安装 `zabbix-api` 模块。

```bash
$ pip install zabbix-api
$ pip list
iniparse (0.3.1)
ordereddict (1.2)
pip (8.1.0)
pycurl (7.19.0)
pygpgme (0.1)
setuptools (19.6.2)
urlgrabber (3.9.1)
yum-metadata-parser (1.1.2)
zabbix-api (0.4)
```

<br />
#### 查询某主机获取hostid

写一个 `python` 脚本，内容如下：

```python
$ vim get_hostid.py
#!/usr/bin/env python
# encoding: utf-8

from zabbix_api import ZabbixAPI
server = "http://172.16.241.130/zabbix"
username = "Admin"
password = "zabbix"
zapi = ZabbixAPI(server=server, path="", log_level=0)
zapi.login(username, password)

## 通过计算机名查找hostid
hostinfo=zapi.host.get({"output":"extend","filter":{"host":"Zabbix server"}})
hostid_01=hostinfo[0]['hostid']
print(hostid_01)

## 通过主机可见名查找hostid
hostinfo=zapi.host.get({"output":"extend","filter":{"name":"Zabbix server"}})
hostid_02=hostinfo[0]['hostid']
print(hostid_02)
```

运行脚本，得到结果为

```bash
$ python get_hostid.py
'10084'
'10084'
```

<br />
#### 获取目标主机对应的监控项和监控项具体名称

写一个 `python` 脚本，内容如下：

```python
$ vim get_items.py
#!/usr/bin/env python
# encoding: utf-8

from zabbix_api import ZabbixAPI
import pprint
server = "http://172.16.241.130/zabbix"
username = "Admin"
password = "zabbix"
zapi = ZabbixAPI(server=server, path="", log_level=0)
zapi.login(username, password)

result = zapi.item.get({"output": ["itemids", "key_"], "host": "Zabbix server"})
pprint.pprint(result)
```

运行脚本，得到结果为

```bash
$ python get_items.py
[{'itemid': '23327', 'key_': 'agent.hostname'},
 {'itemid': '23287', 'key_': 'agent.ping'},
 {'itemid': '23288', 'key_': 'agent.version'},
 {'itemid': '23289', 'key_': 'kernel.maxfiles'},
 {'itemid': '23290', 'key_': 'kernel.maxproc'},
 {'itemid': '23683', 'key_': 'mysql.ping'},
 {'itemid': '23684', 'key_': 'mysql.status[Bytes_received]'},
 {'itemid': '23685', 'key_': 'mysql.status[Bytes_sent]'},
--snip--
 {'itemid': '23635', 'key_': 'zabbix[vmware,buffer,pfree]'},
 {'itemid': '23274', 'key_': 'zabbix[wcache,history,pfree]'},
 {'itemid': '23275', 'key_': 'zabbix[wcache,index,pfree]'},
 {'itemid': '23276', 'key_': 'zabbix[wcache,trend,pfree]'},
 {'itemid': '23277', 'key_': 'zabbix[wcache,values]'}]
```

<br />
#### 获取对应监控项的历史数据

写一个 `python` 脚本，内容如下：

```python
$ vim get_items.py
#!/usr/bin/env python
# encoding: utf-8

from zabbix_api import ZabbixAPI
import pprint
server = "http://172.16.241.130/zabbix"
username = "Admin"
password = "zabbix"
zapi = ZabbixAPI(server=server, path="", log_level=0)
zapi.login(username, password)

result = zapi.history.get({"output": "extend", "history": 0, "itemids": "23296", "sortfield": "clock", "sortorder": "DESC", "limit": 10})
pprint.pprint(result)
```

运行脚本，得到结果为

```bash
$ python get_items.py
[{'clock': '1483637416',
  'itemid': '23296',
  'ns': '833400783',
  'value': '0.0100'},
 {'clock': '1483637356',
  'itemid': '23296',
  'ns': '102860881',
  'value': '0.0300'},
 {'clock': '1483637296',
  'itemid': '23296',
  'ns': '609325047',
  'value': '0.0800'},
 {'clock': '1483637236',
  'itemid': '23296',
  'ns': '31887252',
  'value': '0.1300'},
--snip--
```

<br />
#### 获取对应监控项一段时间内的历史数据并格式化输出

写一个 `python` 脚本，内容如下：

```python
$ vim history_data.py
#!/usr/bin/env python
# encoding: utf-8

"""
Retrieves history data for a given numeric (either int or float) item_id
"""

from zabbix_api import ZabbixAPI
import pprint
from datetime import datetime
import time
server = "http://172.16.241.130/zabbix"
username = "Admin"
password = "zabbix"
zapi = ZabbixAPI(server=server)
zapi.login(username, password)
item_id = "23296"

# Create a time range
time_till = time.mktime(datetime.now().timetuple())
time_from = time_till - 60 * 60 * 24 * 10  # 10 days

# Query item's history (integer) data
history = zapi.history.get({"itemids": item_id, "time_from": time_from, "time_till": time_till, "output": "extend", "limit": "10"})

# If nothing was found, try getting it from history (float) data
if not len(history):
    history = zapi.history.get({"itemids": item_id, "time_from": time_from, "time_till": time_till, "output": "extend", "limit": "10", "history": 0})

for point in history:
        print("{0}: {1}".format(datetime.fromtimestamp(int(point['clock']))
                                .strftime("%x %X"), point['value']))
```

运行脚本，得到结果为

```bash
$ python history_data.py
12/29/16 09:40:16: 0.4900
12/29/16 09:41:16: 0.1800
12/29/16 09:42:16: 0.1600
12/29/16 09:43:16: 0.2000
12/29/16 09:44:16: 0.0700
12/29/16 09:45:16: 0.1000
12/29/16 09:46:16: 0.2100
12/29/16 09:47:16: 0.0700
12/29/16 09:48:16: 0.5100
12/29/16 09:49:16: 0.2200
```
