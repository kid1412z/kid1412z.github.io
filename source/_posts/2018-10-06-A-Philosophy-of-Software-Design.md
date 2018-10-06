title: 软件设计的哲学（John Ousterhout分享）
tags: [Software Design]
date: 2018-10-06 22:37:57
categories: Software Design
---
## 软件设计的目标

1. 软件设计最大的目标是降低软件的复杂性（Complexity），复杂性使软件难于理解和维护。

2. 复杂性的来源：

 - 含义模糊（Obscurity）： 重要信息不突出。
 - 相互依赖：模块无法独立于其他模块而被理解。

3. 复杂性的危害

复杂性会逐渐递增，前面埋的坑，会导致后面的设计越来越复杂。

## 设计原则

### 暴露简单通用的接口，隐藏复杂的实现。

<!-- more -->

![Class should go deep](http://zuoqy.com/images/2018-10-06/1.png) 

正例：Unix 文件I/O 接口

* Unix文件操作逻辑极为复杂，但前端模块只暴露的5个简单的接口。
* 隐藏了文件在磁盘上的表现形式、块分配、目录管理、权限管理、磁盘调度、块缓存和设备信息等复杂的底层内容。

![A deep interface](http://zuoqy.com/images/2018-10-06/2.png) 

反例：Java文件操作接口，读写一个文件要客户端感知很多类和细节：

![A deep interface cont'd](http://zuoqy.com/images/2018-10-06/3.png) 


### 模块外部需要感知和必须处理的异常越少越好：

![minimize exceptions outside](http://zuoqy.com/images/2018-10-06/4.png) 

### 注重设计 vs. 注重速度

如果目标是尽快把feature作为，把bug都fix掉，最终导致的结果就是设计缺陷，越来越复杂。

![tactical](http://zuoqy.com/images/2018-10-06/5.png) 

如果初始有一个良好的设计，则在后面的迭代中形成良性循环，最小化复杂性。长远看来则节省了很多时间。

![strategy](http://zuoqy.com/images/2018-10-06/6.png) 

Facebook由最初的口号"Move quickly and break things"转变为"Move quickly with solid infrastructure"
Google和VMWare由于注重设计而成功，吸引了大量顶级工程师。

![invest](http://zuoqy.com/images/2018-10-06/7.png) 

持续的在设计上的小投入，最终换来巨大回报。

![invest](http://zuoqy.com/images/2018-10-06/8.png) 

## 参考

* https://www.youtube.com/watch?v=bmSAYlu0NcY

