title: "Java内存区域"
date: 2015-04-16 21:38:41
categories: Java
tags: [Java,JVM]
---

**摘要**：本文主要介绍了Java运行时数据区域的划分、各个区域的职能、对象内存分配和定位方法。
**Abstract**: This article describes the division of the Java runtime data area, the functions of the corresponding region, the object memory allocation and positioning methods.

<!-- more -->

## 运行时数据区域

JVM在程序运行过程中，会把内存划分成以下区域：
![img](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-04-16/1.png)

### 程序计数器

每个线程都有独立存储的程序计数器，互不影响，独立存储，属于*线程私有*内存。如果线程执行的是Java方法，计数器记录的是正在执行的虚拟机字节指令的地址；如果正在执行的时Native方法，这个计数器的值则为空(Undefined)。
此内存区域是唯一一个在JVM规范中没有规定任何OutOfMemoryError情况的区域。

### Java虚拟机栈(Java Virtual Machine Stacks)

虚拟机栈描述的时Java方法执行的内存模型，每个方法在执行的时候都会创建一个栈帧(Stack Frame)用于存储局部变量表、操作数栈、动态链接、方法出口等信息。
局部变量表存放了*编译期*可知的各种基本数据类型、对象引用、和返回地址类型。其所需的内存空间在*编译期*分配，运行时不会改变局部变量表的大小。
异常状况：1）StackOverflowError: 线程请求的栈深度大于JVM允许的深度。2）OutOfMemoryError:虚拟机栈动态扩展的时候无法申请到足够的内存。

### 本地方法栈(Native Method Stack)

本地方法栈为虚拟机使用到的Native方法提供栈空间，本地方法栈也有上述两种异常情况。

### Java堆

Java堆是被所有线程共享的一块内存区域，在虚拟机启动时创建。几乎所有的对象实例都在这里分配内存。（逃逸分析和标量替换允许在栈上分配对象内存）
Java堆是垃圾收集器管理的主要区域，也被成为GC堆。从内存分代回收的角度看，Java堆可以细分为：新生代和老年代；从内存分配的角度看，Java堆可能分出多个线程私有的分配缓冲区(Thread Local Allocation Buffer, TLAB)

### 方法区(Method Area)

线程共享内存区域，用于存储虚拟机加载的类信息、常量、静态变量、及时编译器编译后的代码等数据。HotSpot JVM用永久代(Permanent Generation)实现方法区，但两者并不等价。但这种实现方法容易导致内存溢出（可通过-XX:MaxPermSize设置永久代上限），新版的JDK1.7 Hotspot 已经把原本放在永久带的字符串常量池移出。
这个区域的内存回收主要针对类型的卸载和常量池的回收。异常情况：OutOfMemoryError.

### 直接内存(Direct Memory)

直接内存不是JVM运行时数据区域，但在Java NIO中引入了基于Channel和Buffer的I/O方式，可以直接使用Native函数库分配*堆外内存*。申请直接内存大小超过限制，同样会有OutOfMemory异常。


### 新生对象内存分配方式

* 指针碰撞(Bump The Pointer): 指针作为分配和未分配的界限，要求JAVA堆规整。
* 空闲列表(Free List): Java堆不规整。

为了解决以上两种分配方式并发安全问题，可以采用：
* CAS失败重试
* 本地线程分配缓冲TLAB (配置参数：-XX:+/-UseTLAB)(只有本地缓冲用完，需要重新分配的时候才需要同步锁定)

## 对象的创建

### 对象的内存布局

对象的内存布局可以分为三块：对象头(Header)、实例数据（Instance Data）、对齐填充（Padding）。

#### 对象头

* 运行时数据：HashCode、GC分代、锁状态标识、线程持有的锁、偏向线程ID、偏向时间戳。这部分数据的长度与虚拟机位数相同。官方称为*“MarkWord”*
* 类型指针：确定对象是哪个类的实例。（不一定所有的虚拟机都通过保留类型指针来确定对象的类型）

#### 实例数据

存放代码中定义的各种类型的字段内容，顺序收到JVM内存分配策略的影响，相同长度的字段往往相邻分配。

#### 对齐填充

Hotspot虚拟机要求对象的大小是8字节的整数倍，不够的用Padding字段补全。

### 对象的访问定位

* 句柄：reference中包含了对象的句柄地址，句柄中包含对象各部分的地址
![img](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-04-16/2.png)
* 直接指针：reference中直接存储对象的地址（Hotspot实现）
![img](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-04-16/2.png)

## References

* 图片来自：《深入理解Java虚拟机》