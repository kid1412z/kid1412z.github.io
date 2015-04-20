title: "Java内存回收算法和引用类型"
date: 2015-04-20 09:52:24
categories: Java
tags: [Java,JVM,GC]
---
**摘要**：*本文介绍了两种内存回收算法和4种Java引用类型。*
**Abstract**: *This article introduced two kinds of Garbage Collection Algorithm and four kinds of reference type in Java.*

<!-- more -->

## 内存回收算法

### 引用计数(Reference Counting)

给对象添加一个引用计数器，当有一个对象引用它，计数值加1；当引用失效时，计数值减1；任何时刻，计数为0的对象可回收。
主流的JVM并没有选用该算法，主要原因是：*无法解决循环引用的问题*。

### 可达性分析(Reachability Analysis)

通过一系列的称为*GC Roots*的的对象作为起始点，向下搜索（搜索路径为**引用链** (*Reference Chain*)），当对象没有任何引用链与GC Roots相连时，对象可回收。
一般以下对象可作为GC Roots：
* 虚拟机栈中本地变量表所引用的对象
* 方法区中类静态属性所引用的对象
* 方法区中常量引用的对象
* 本地方法栈引用的对象

## 引用(Reference)

JDK1.2之前**引用**的定义：如果内存中存储的数值是另一块内存的起始地址，则这块内存代表一个引用。
JDK1.2之后，**引用**引用分为强引用(Strong Reference)、软引用(Soft Reference)、弱引用(Weak Reference)、虚引用(Phantom Reference)四种（依次减弱）。

### 强引用

类似Object obj = new Object()这类引用，只要引用还存在，对象就不会被回收。

### 软引用

用来描述有用但非必须的对象。OOM之前，JVM会在这些对象范围中进行第二次回收。

### 弱引用

弱引用指向的对象只能生存到下一次垃圾回收之前，无论当前内存是否足够，都会回收掉被弱引用关联的对象。

### 虚引用

虚引用也称为幽灵引用或者幻影引用，它使最弱的一种引用关系。虚引用的存在，不会对对象的生存时间构成影响，也无法通过虚引用取得对象实例。
为对象设置虚引用管理的唯一目的是能在这个对象**执行了finalize方法，准备好被垃圾回收时**(不能在运行时通过幽灵引用判断对象是否已经被GC[2])收到一个系统通知。

> A Phantom Reference can't tell when an Object was GCed. It is just a signal which says that an Object has been finalized and is ready for GC.

## Reference

* *《深入理解Java虚拟机》*
* *[有关是否能在运行时得知对象是否已经被GC在StackOverflow上的讨论](http://stackoverflow.com/questions/4223956/check-if-object-can-be-fetched-by-garbage-collector)*