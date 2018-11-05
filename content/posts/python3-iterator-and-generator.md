---
title: "Python3 系列之迭代器 & 生成器"
subtitle: "使用迭代器和生成器实现单线程异步并发"
date: 2017-07-27T18:38:59Z
draft: false
toc: true
categories: "python"
tags: ["python"]
bigimg: [{src: "https://ws2.sinaimg.cn/large/006tNbRwgy1fwtkgo7kp3j31kw0d0750.jpg"}]
---

<!--more-->
<div align=life> 
<iframe frameborder="no" marginwidth="0" marginheight="0" width=400 height=140 src="https://music.163.com/outchain/player?type=2&id=34341360&auto=0&height=66"></iframe>
</div>

## 1. 迭代器
------

<p markdown="1" style="display: block;padding: 10px;margin: 10px 0;border: 1px solid #ccc;border-top-width: 5px;border-radius: 3px;border-top-color: #2780e3;">
迭代器是访问集合元素的一种方式，迭代器对象从集合的第一个元素开始访问，直到所有的元素被访问结束。迭代器只能往前不会后退，不过这也没什么，因为人们很少在迭代途中往后退。另外，迭代器的一大优点是不要求事先准备好整个迭代过程中所有的元素。迭代器仅仅在迭代到某个元素时才计算该元素，而在这之前或之后，元素可以不存在或者被销毁。这个特点使得它特别适合用于遍历一些巨大的或是无限的集合，比如几个G的文件。
</p>

### 特点

- 访问者不需要关心迭代器内部的结构，仅需通过 `next()` 方法不断去取下一个内容
- 不能随机访问集合中的某个值，只能从头到尾依次访问
- 访问到一半时不能往回退
- 便于循环比较大的数据集合，节省内存

### 生成一个迭代器

```python
>>> names = iter(['alex', 'jack', 'list'])
>>> print(names)
<list_iterator object at 0x7f92dc158b70>

# 不能通过下标形式访问特定元素
>>> names[1]
Traceback (most recent call last):
  File "<input>", line 1, in <module>
    names[1]
TypeError: 'list_iterator' object is not subscriptable

# 只能从头到尾依次取出
>>> print(names.__next__())
alex
>>> print(names.__next__())
jack
>>> print(names.__next__())
list

# 如果再想往后取就会报错，因为已经迭代完了
>>> print(names.__next__())
Traceback (most recent call last):
  File "<input>", line 1, in <module>
    print(names.__next__())
StopIteration
```

## 2. 生成器
------

一个函数调用时返回一个迭代器，那这个函数就叫做生成器（generator），如果函数中包含 `yield` 语法，那这个函数就会变成生成器。

### yield 语法的作用
使函数中断，并保存中断状态，中断后，代码可以继续往下执行，过一段时间还可以再重新调用这个函数，从上次 `yield` 的下一句开始执行。

### 生成一个生成器

定义一个函数
```python
def cash_money(amount):
    while amount > 0:
        amount -= 100
        yield 100
        print("又来取钱啦！")
```

下面我们来调用一下这个函数
 
```python
>>> atm = cash_money(500)
>>> print(atm)
<generator object cash_money at 0x7f92dc086bf8>
```

奇怪，不是执行了吗，为什么没有输出？很显然，这里并没有执行，我们可以看一下它的类型：

```python
>>> type(atm)
<class 'generator'>
```

这就不仅仅是一个函数了，它现在是一个生成器，不能按照函数的执行方法去理解它，因为它的返回值是一个迭代器。下面我们来调用一下这个迭代器：

```python
>>> print(atm.__next__())
100
>>> print(atm.__next__())
又来取钱啦！
100
>>> print(atm.__next__())
又来取钱啦！
100
>>> print(atm.__next__())
又来取钱啦！
Traceback (most recent call last):
  File "<input>", line 1, in <module>
    print(atm.__next__())
StopIteration
```

但是这个东西有什么用呢？很多人可能不明白，那我来给你解释一下：

> 当你调用一个正常的函数的时候，你只要一调用它，你就得等着它的返回，如果它没执行完，不给你返回，你只能干等着，没法干别的事。它要是执行10分钟，你就得在那边卡住，因为你的程序是串行从上到下。

> 举个例子，你写了一个程序，向银行发一个请求说你要取5万块钱，但是银行的接口说这是一个比较大额的数目，大概需要半个小时才能审核通过，半个小时之后才能告诉你能不能取。所以这半个小时你只能等着，不等着它一会儿回来就找不到你了，等它返回了之后，你再根据返回的结果执行下一步动作。假设现在银行升级了，审核需要两天，你的程序就得等两天，你没法不等，因为你的程序设计就是串行的。如果你这么干，你就被老板开除了。

所以我们应该有一种需求：当我要调用另外应该程序的接口时，那个接口需要执行很长时间，我能不能不等它，先去干点别的事情，等它处理好了再告诉我。这就是一个异步的需求。

下面再来实验一下：

```python
>>> atm = cash_money(500)
>>> print(atm.__next__())
100
>>> print(atm.__next__())
又来取钱啦！
100

# 如果我现在停了下来，函数并没有真正结束，里面还有三百块钱没取。现在我不想取了，钱够花了，我想先去干点别的事情，一会儿回来再取
# 干什么好呢？叫个大保健吧。。。
>>> print("叫个大保健。。。")

# 现在两百块钱花完了，还可以再回来取钱
>>> print(atm.__next__())
又来取钱啦！
100
# 现在函数并不是从头执行，而是从上一次的断点继续执行
```

我们开始定义的函数是一个 `while` 循环，当你进入一个循环后，按理说除非你从这个循环退出，不然你没法跳出这个循环。但这里的情况是我可以循环一会儿就跳出，过一会儿再进入循环，可以随意切入切出，这个非常了不起！你用正常的程序写一个循环是很难做到这一点的，好好感受一下它的魅力吧！


### 使用yield实现单线程中的异步并发效果

```python
$ cat yield异步.py
#!/usr/bin/env python
# encoding: utf-8
import time
def consumer(name):
    print("{}准备吃包子啦".format(name))
    while True:
        baozi = yield
        print("包子{0}来了，被{1}吃了！".format(baozi, name))

def producer(name):
    c = consumer('A')
    c2 = consumer('B')
    c.__next__()
    c2.__next__()
    print("老子开始准备做包子啦！")
    for i in range(3):
        time.sleep(1)
        print("做了两个包子！")
        c.send(i)
        c2.send(i)

producer("alex")

$ python3 yield异步.py
A准备吃包子啦
B准备吃包子啦
老子开始准备做包子啦！
做了两个包子！
包子0来了，被A吃了！
包子0来了，被B吃了！
做了两个包子！
包子1来了，被A吃了！
包子1来了，被B吃了！
做了两个包子！
包子2来了，被A吃了！
包子2来了，被B吃了！
```

这里定义了一个消费者和生产者模型，生产者通过 `send` 传递参数给 `yield` 表达式，这时传递的参数会作为 `yield` 表达式的值，虽然这是一个单线程的串行函数，但这里表现出来的是一种异步的效果。

总结：

- 我理解的生成器(generator)能够迭代的关键是它有一个next()方法，工作原理就是通过重复调用next()方法，直到捕获一个异常。
- 带有 yield 的函数不再是一个普通函数，而是一个生成器generator，可用于迭代，工作原理同上。
- yield 是一个类似 return 的关键字，迭代一次遇到yield时就返回yield后面的值。重点是：下一次迭代时，从上一次迭代遇到的yield后面的代码开始执行。
- 简要理解：yield就是 return 返回一个值，并且记住这个返回的位置，下次迭代就从这个位置后开始。
