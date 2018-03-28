---
title: "Python3 系列之文件读写"
subtitle: "通过 Python3 读写文件"
date: 2017-01-03T08:51:06Z
draft: false
categories: python
tags: ["python"]
bigimg: [{src: "http://o7z41ciog.bkt.clouddn.com/picHD_12.png"}]
---

<!--more-->
<iframe frameborder="no" border="0" marginwidth="0" marginheight="0" width=0 height=0 src="http://other.web.rh01.sycdn.kuwo.cn/resource/n2/2/46/1567406567.mp3"></iframe>

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">1. **文件与文件路径**</p>
------

用到的模块：`os`

### 1.1 当前工作目录

在交互模式下输入以下代码：

```python
>>> import os
>>> os.getcwd()
'/tmp'
>>> os.chdir('/home/yang/test')
>>> os.getcwd()
'/home/yang/test'
```

如果要更改的当前目录不存在，`Pyhton`就会显示一个错误

```python
>>> os.chdir('/user/bin')
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
FileNotFoundError: [Errno 2] No such file or directory: '/user/bin'
```


### 1.2 创建新文件夹

```python
>>> os.makedirs('/tmp/test')
```

它会递归地创建文件夹，也就是说，`os.makedirs()` 将创建所有必要的中间文件夹。


### 1.3 处理绝对路径和相对路径

- `os.path.abspath(path)`：返回参数的`绝对路径`的字符串

```python
>>> os.path.abspath('.')
'/tmp'
>>> os.path.abspath('./test')
'/tmp/test'
```

- `os.path.isabs(path)`：如果参数是一个绝对路径，就返回True，如果参数是一个相对路径，就返回False

```python
>>> os.path.isabs('.')
False
>>> os.path.isabs(os.path.abspath('.'))
True
```

- `os.path.relpath(path, start)`：返回从 start 路径到 path 的相对路径的字符串。如果没有提供 start，就使用当前工作目录作为开始路径。

```python
>>> os.path.relpath('/home/yang', '/tmp')
'../home/yang'
```

- `os.path.dirname(path)`：返回一个字符串，它包含`path`参数中最后一个斜杠<span id="inline-blue">之前</span>的所有内容。
- `os.path.basename(path)`：返回一个字符串，它包含`path`参数中最后一个斜杠<span id="inline-blue">之后</span>的所有内容。

```python
>>> path = '/usr/bin/vlc'
>>> os.path.basename(path)
'vlc'
>>> os.path.dirname(path)
'/usr/bin'
```

- `os.path.split()`：获取一个路径的<span id="inline-blue">目录名称和基本名称</span>这两个字符串的元组。

```python
>>> path = '/usr/bin/vlc'
>>> os.path.split(path)
('/usr/bin', 'vlc')
```

`os.path.split()`不会接受一个文件路径并返回每个文件夹的字符串的列表。如果需要这样，请使用`split()`字符串方法。`os.path.sep`设置为正确的文件夹分割斜杠。

```python
>>> path.split(os.path.sep)
['', 'usr', 'bin', 'vlc']
```

### 1.4 查看文件大小和文件夹内容

- os.path.getsize(path)：返回path参数中文件的字节数。
- os.listdir(path)：返回文件名字符串的列表，包含path参数中的每个文件。

```python
>>> os.path.getsize('/usr/bin/vlc')
14712
>>> os.listdir('/etc')
['ld.so.conf.d', 'skel', 'profile.d', 'fstab', 'shells', 'rpc', 'nscd.conf', 'gai.conf', 'locale.gen', 'ssl', 'dbus-1', 'ethertypes', 'iptables', 
--snip--
'logrotate.conf', 'man_db.conf', 'pacman.conf', 'wgetrc', 'cpufreq-bench.conf', 'papersize', 'nanorc', 'ld.so.cache']
```

如果想知道这个目录下所有文件的总字节数，就可以同时使用 os.path.getsize() 和 os.listdir()。

```python
>>> totalSize = 0
>>> for filename in os.listdir('/etc'):
        totalSize = totalSize + os.path.getsize(os.path.join('/etc', filename))
>>> print(totalSize)
846656
```

### 1.5 检查路径有效性

- `os.path.exists(path)`：如果path参数所指的文件或文件夹存在，将返回True，否则返回False。
- `os.path.isfile(path)`：如果path参数存在，并且是一个文件，将返回True，否则返回False。
- `os.path.isdir(path)`：如果path参数存在，并且是一个文件夹，将返回True，否则返回False。

```python
>>> os.path.exists('/tmp')
True
>>> os.path.exists('/user/bin')
False
>>> os.path.isdir('/tmp')
True
>>> os.path.isfile('/tmp')
False
>>> os.path.isdir('/usr/bin/vlc')
False
>>> os.path.isfile('/usr/bin/vlc')
True
```

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">2. **文件读写过程**</p>
------

在 Python 中，读写文件有3个步骤：

1、调用 `open()` 函数，返回一个 File 对象。<br />
2、调用 File 对象的 `read()` 或 `write()` 方法。<br />
3、调用 File 对象的 `close()` 方法，关闭该文件。


### 2.1 创建文件

```python
>>> f = open('test.txt','w')
>>> f.write('Hello world!')
# 因为此时写入的数据还在内存中，并没有被写入磁盘，所以要关闭之后才能读取到数据
>>> f.close()
```
如果想不关闭就能读取到数据，可以这样：

```python
>>> f.flush()
```

### 2.2 读取文件

```python
# 默认以“r”模式打开文本（只读）
>>> f = open('test.txt')
# 读取文本中所有内容
>>> f.read()
```

如果这时再用f.readline()读取文本，将会得到空字符串，因为它是以迭代器的方式打开这个文本，所以此时它的内存指针已经指向了文本的最后一行

如果还想可以继续读，可以把它的内存指针指向第一行

```python
# 查看内存指针的位置
>>> f.tell()
# 将内存指针指向第一行
>>> f.seek(0)
```

### 2.3 遍历文件内容

```python
>>> a = open('user_info.txt')
>>> for line in a.readlines():
    # 加上逗号可以避免打印换行符
        print(line),
>>> a.close()
```

<font color=#8A2BE2>readlines</font>将文本中的所有内容都读取到了内存中，对于大文本来说会很耗内存。
为了解决这个问题，我们可以使用<font color=#8A2BE2>xreadlines。</font>

### 2.4 追加
```python
>>> F = open('test.txt','a')
>>> F.write("append to the end")
>>> f.close()
```

### 2.5 用 `pprint.pformat()` 函数保存变量

`pprint.pformat()` 函数将返回同样的文本字符串，但不是打印它。这个字符串不仅是易于阅读的格式，同时也是语法上正确的 Pthon 代码。`pprint.pformat()` 函数将提供一个字符串，你可以将它写入.py文件，该文件将成为你字节的<span id="inline-blue">模块</span>，如果你需要使用存储在其中的变量，就可以导入它。

```python
>>> import pprint
>>> cats = [{'name': 'Zophie', 'desc': 'chubby'}, {'name': 'Pooka', 'desc': 'fluffy'}]
>>> pprint.pformat(cats)
"[{'desc': 'chubby', 'name': 'Zophie'}, {'desc': 'fluffy', 'name': 'Pooka'}]"
>>> file = open('myCats.py', 'w')
>>> file.write('cats = ' + pprint.pformat(cats) + '\n')
83
>>> file.close()
```

import 语句导入的模块本身就是 Python 脚本。如果来自 `pprint.pformat()` 的字符串保存为一个.py文件，该文件就是一个可以导入的模块，像其他模块一样。

```python
>>> import myCats
>>> myCats.cats
[{'desc': 'chubby', 'name': 'Zophie'}, {'desc': 'fluffy', 'name': 'Pooka'}]
>>> myCats.cats[0]
{'desc': 'chubby', 'name': 'Zophie'}
>>> myCats.cats[0]['name']
'Zophie'
```

### 用 `shelf` 模块保存变量

shelve类似于一个 `key-value` 数据库，可以很方便的用来保存Python的内存对象，其内部使用 `pickle` 来序列化数据，简单来说，使用者可以将一个列表、字典、或者用户自定义的类实例保存到 `shelve` 中，下次需要用的时候直接取出来，就是一个 Python 内存对象，不需要像传统数据库一样，先取出数据，然后用这些数据重新构造一遍所需要的对象。

```python
>>> import shelve
>>> shelfFile = shelve.open('mydata')
>>> cats = ['Zophie', 'Pooka', 'Simon']
>>> shelfFile['cats'] = cats
>>> shelfFile.close()
```

shelf值不必使用读模式或写模式打开，因为它们在打开后，既能读又能写。

```python
>>> shelfFile = shelve.open('mydata')
>>> type(shelfFile)
<class 'shelve.DbfilenameShelf'>
>>> shelfFile['cats']
['Zophie', 'Pooka', 'Simon']
>>> shelfFile.close()
```

像字典一样，`shelf` 值有 `keys()` 和 `values()` 方法，返回 shelf 中键和值的类似列表的值。因为这些方法返回类似列表的值，而不是真正的列表，所以应该将它们传递给 `list()` 函数，取得列表的形式。

```python
>>> shelfFile = shelve.open('mydata')
>>> list(shelfFile.keys())
['cats']
>>> list(shelfFile.values())
[['Zophie', 'Pooka', 'Simon']]
>>> shelfFile.close()
```

<p id="div-border-left-red">创建文件时，如果你需要在文本编辑器中读取它们，纯文本就非常有用。但是，如果想要保存 `Python` 程序中的数据，那就使用 `shelve` 模块</p>

## <p markdown="1" style="margin-bottom:2em; margin-right: 5px; padding: 8px 15px; letter-spacing: 2px; background-image: linear-gradient(to right bottom, rgb(0, 188, 212), rgb(63, 81, 181)); background-color: rgb(63, 81, 181); color: rgb(255, 255, 255); border-left: 10px solid rgb(51, 51, 51); border-radius:5px; text-shadow: rgb(102, 102, 102) 1px 1px 1px; box-shadow: rgb(102, 102, 102) 1px 1px 2px;">3. **项目：多重剪切板**</p>
------

该程序被命名为 `mcb.py`，该程序将利用一个关键字保存每段剪切板文本。例如，当运行`python mcb.py spam`，这段文本稍后将重新加载到剪切板中。如果用户忘了有哪些关键字，他们可以运行 `python mcb.py list`，将所有关键字的列表复制到剪切板中。

下面是程序要做的事：

- 针对要检查的关键字，提供命令行参数。
- 如果参数是 `save`，那么将剪切板的内容保存到关键字。
- 如果参数是 `list`，就将所有的<span id="inline-purple">关键字</span>拷贝到剪切板。
- 否则，就将关键词对应的文本拷贝到剪切板。

这意味着代码要做下列事情：

- 从 `sys.argv` 读取命令行参数。
- 读写剪切板。
- 保存并加载 `shelve` 文件。

需要安装的软件（以Archlinux为例）：

```bash
$ pacman -S python-pyperclip
```

以下软件只需选择其中一种安装：

```bash
$ pacman -S xsel
$ pacman -S xclip
```
</p>

### 3.1 注释和 `shelve` 设置

```python
   #! python3
   # mcb.pyw - Save and loads pieces of text to the clipboard.
   # Usage: py mcb.pyw save <keyword> - Save clipboard to keyword.
   #        py mcb.pyw <keyword> - Load keyword to clipboard.
   #        py mcb.pyw list - Loads all keywords to clipboard.
(1)import shelve, pyperclip, sys

(2)mcbShelf = shelve.open('mcb')

   # TODO: Save clipboard content.

   # TODO: Save clipboard content

   mcbShelf.close()
```

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(1)</span> 拷贝和粘贴需要 `pyperclip` 模块，读取命令行参数需要 `sys` 模块。`shelve` 模块也需要准备好，当用户希望保存一段剪切板文本时，你需要将它保存到一个 `shelf` 文件中。<br />

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(2)</span> 当用户希望将文本拷贝回剪切板时，你需要打开 shelf 文件，将它重新加载到程序中。这个 shelf 文件命名时带有前缀 `mcb`。

### 3.2 用一个关键字保存剪切板内容

```python
   #! python3
   # mcb.pyw - Save and loads pieces of text to the clipboard.
   --snip--
   
   # Save clipboard content.
(1)if len(sys.argv) == 3 and sys.argv[1].lower() == 'save':
(2)    mcbShelf[sys.argv[2]] = pyperclip.paste()
   elif len(sys.argv) == 2:
(3)# TODO: List keywords and load content

   mcbShelf.close()
```

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(1)</span> 如果第一个命令行参数是字符串 `save`，<br />

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(2)</span> 那么第二个命令行参数就是保存剪切板内容的当前关键字。关键字将用作 `mcbShelf`中的键，值就是剪切板上的文本。<br />

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(3)</span> 如果只有一个命令行参数，就假定它要么是 `list`，要么是需要加载到剪切板上的关键字。

### 3.3 列出关键字和加载关键字的内容

```python
   #! python3
   # mcb.pyw - Save and loads pieces of text to the clipboard.
   --snip--
   
   # Save clipboard content.
   if len(sys.argv) == 3 and sys.argv[1].lower() == 'save':
       mcbShelf[sys.argv[2]] = pyperclip.paste()
   elif len(sys.argv) == 2:
   # List keywords and load content
(1)if sys.argv[1].lower() == 'list':
(2)     pyperclip.copy(str(list(mcbShelf.keys())))
   elif sys.argv[1] in mcbShelf:
(3)     pyperclip.copy(mcbShelf[sys.argv[1]])

   mcbShelf.close()
```

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(1)</span> 如果只有一个命令行参数，首先检查它是不是 `list`。<br />

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(2)</span> 如果是，表示 `shelf` 键的列表的字符串将被拷贝到剪切板。用户可以将这个列表拷贝到一个打开的文本编辑器，进行查看。<br />

<span style="display:inline; padding:.2em .6em .3em; font-size:80%; font-weight:bold; line-height:1; color:#fff; text-align:center; white-space:nowrap; vertical-align:baseline; border-radius:0; background-color: #2780e3;">(3)</span> 否则，你可以假定该命令行参数是一个关键字。如果这个关键字是 `shelf` 中的一个键，就可以将对应的值加载到剪切板。
