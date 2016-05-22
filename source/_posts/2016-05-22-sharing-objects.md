title: "Java对象的共享"
date: 2016-05-22 15:48:56
categories:
tags: [Java,concurrency]
---
**摘要**：Java内存可见性、对象的发布和逸出以及不变性
**Abstract**:Visibility、publish and escape、immutable。
<!-- more -->

## 可见性

可见性是指某个线程对变量写入的值，其他线程是否总能够正确的读取。通常，为了确保多线程之间对内存写入操作的可见性，必须使用同步机制。

### 重排序

在多线程情况下，存在指令重排序的情况，因此在没有同步的情况下，不能假定多线程程序的指令执行顺序。

### 失效数据

在没有同步保证的多线程程序中，一个线程可能读取到某个变量的新值，也可能读取到其已经失效的值。


### 非原子的64位操作

在多线程程序中使用共享且可变的long和double等类型的变量是不安全的，除非用volatile声明或者用锁保护起来。因为JVM允许将64位的操作分解为两个32位的操作。

### 加锁与可见性

加锁的含义不仅仅局限于互斥行为，还包括内存可见性。为了确保所有线程都能看到共享变量的最新值，所有执行读写操作的线程都必须在同一个锁上进行同步。

### volatile变量

volatile变量不会被缓存在寄存器中或者对其他处理器不可见的地方，因此在读取volatile类型的变量时，总会返回最新写入的值。
仅当volatile变量能简化代码实现以及对同步策略的验证时，才应该使用它们。使用方式包括：确保变量自身状态的可见性、确保所引用对象状态的可见性、标识一些重要的程序生命周期事件的发生（如初始化或关闭）

```java
    // 判断某个状态，决定是否退出循环
    volatile boolean asleep;
    ...
    while(!asleep) {
        countSomeSheep();
    }
```

注：volatile语义不足以保证递增操作（count++）的原子性，因为递增是读-修改-写操作。**加锁机制既可以确保可见性，又可以确保原子性，而volatile变量只能确保可见性**。

**当且仅当满足以下所有条件时，才应该使用volatile变量**：
* 对变量的写入操作比依赖变量当前的值，或者确保只有一个线程更新变量的值。
* 该变量不会与其他状态变量一起纳入不变性条件。
* 访问该变量时不需要加锁。

## 发布与逸出

**发布（publish）**对象，是指是对象能够在当前作用域之外的代码中使用。例如将对象的引用保存到其他类的代码中，或者将引用传递到其他类的方法中。
**逸出（escape）**：当不应该发布的对象被发布，则成为逸出。

### this逸出

在一个类的构造函数中发布对象时，只是发布了一个尚未构造完成的对象，即使发布对象的语句位于构造函数的最后一行。如果this引用在构造函数中逸出，这种对象的创建就是不正确的构造。**不要在函数构造方法中，使this逸出**

#### 错误1：在构造方法内发布内部类对象

```java

public class ThisEscape {
    // 不正确的构造
    public ThisEscape(EventSource source) {
        source.registerListener() {
            new EventListener() {
                public void onEvent(Event e) {
                    doSomeThing(e);
                }
            }
        }
    }

```

上例中，假设EventListener是ThisEscape类的内部类，在发布内部类的对象时，this隐含的也被发布了。

#### 错误2：在构造函数中启动线程


如果想在构造器中启动线程或者设置事件监听，应该使用一个私有构造方法和一个公共的静态工厂方法，从而避免不正确的构造过程。

```java
public class SafeListener {
    private final EventListener listener;
    private SafeListener() {
        listener = new EventListener() {
            public void onEvent(Event e) {
                doSomething(e);
            } 
    };
}
    public static SafeListener newInstance(EventSource source) {
        SafeListener safe = new SafeListener();
        source.registerListener(safe.listener);
        return safe;
    } 
}
```

## 线程封闭（Thread Confinement）

当某个对象封闭在一个线程中时，将自动实现线程安全性，即使被封闭的对象本身不是线程安全的。

### Ad-hoc线程封闭

Ad-hoc线程封闭是指维护线程封闭性的职责完全有程序实现来承担。例如在volatile变量上的读-修改-写操作确保只有一个线程来完成。
这种线程封闭较脆弱，应该尽量避免使用。

### 栈封闭

栈封闭：是指只能通过局部变量才能访问对象。

### ThreadLocal类
ThreadLocal是维持线程封闭性的一种更规范的方法，ThreadLocal对象通常用于防止可变的单例或者全局变量进行共享。静态的ThreadLocal对象可以将包含在其中的全局变量为每个使用它的线程都保存一份，当线程终结时，会被垃圾回收掉。运用此机制，可以很好的实现线程上下文的保存。

## 不变性

不可变对象一定是线程安全的，当满足下面的条件时，对象才是不可变的：

* 对象创建以后其状态不可修改
* 对象所有域都是final类型
* 对象是正确被创建的（在构造方法中没有this逸出）

### final域

final域能确保初始化过程的安全性，从而可以不受限制的访问不可变对象。

### 安全发布的常用模式

* 在静态初始化函数中初始化一个对象引用
* 将对象的引用保存到volatile类型的域或者AtomicReference对象中。
* 将对象的引用保存到某个正确构造对象的final类型的域中
* 将兑现给的引用保存到一个由锁保护的域中。

## 参考

* 1 Goetz, Brian, and Tim Peierls. Java concurrency in practice. Pearson Education, 2006.