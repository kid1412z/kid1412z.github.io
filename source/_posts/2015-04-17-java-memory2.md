title: "Java内存溢出(Java OutOfMemoryError)"
date: 2015-04-17 14:59:40
categories: Java
tags: [Java,JVM,OOM]
---
**摘要**：*本文介绍了Java内存溢出的四种形式：Java堆溢出、虚拟机栈和本地方法栈溢出、方法区和运行时常量池溢出、直接内存溢出。并对JVM堆外内存使用做了简单了介绍。*
**Abstract**: *This article describes the four types of memory overflow in Java: Java heap overflow, virtual machine stack and local method stack overflow, the method area and runtime constant pool overflow, direct memory overflow. And a simple introduction of off-heap memory usage.*

## Java堆溢出

    //JVM args: -Xms20m -Xmx20m -XX:+HeapDumpOnOutOfMemoryError
    public class TestMemLeak {
        public static void main(String[] args) {
            List<Object> list = new ArrayList<Object>();
            while(true) {
                list.add(new Object());
            }
        }
    }

<!-- more -->

-XX:+HeapDumpOnOutOfMemoryError 设置JVM在出现OOM时，对Heap进行转储，可以使用Eclipse MemoryAnalyzer 进行分析。
如果对运行中的服务进行dump，可以使用jmap命令：
    
    jmap -dump:live,format=b,file=heap.bin
    
使用MAT分析结果会有如下的描述：
![oom](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-04-17/1.png)
帮助查找问题所在

## 虚拟机栈和本地方法栈溢出

HotSpot JVM不区分虚拟机栈和本地方法栈，虽然存在-Xoss设置，但是*实际上是无效的*。栈容量只有-Xss来确定。
虚拟机规范中规定了虚拟机栈和本地方法栈的两种异常：
### StackOverflowError: 

线程请求的栈深度大于虚拟机允许的最大深度。
    
    //JVM args: -Xss256k (规定最小栈大小是160k)
    public class TestSOF {
        public static void main(String[] args) {
            test();
        }
        private static void test () {
            test();
        }
    }
    
### OutOfMemoryError: 

虚拟机扩展栈的大小时，不能申请到足够的内存空间。可通过不断创建线程的方式，使JVM出现内存溢出的错误。

## 方法区和运行时常量池溢出

    //JVM args: -XX:PermSize=2M -XX:MaxPermSize=4M
    public class TestConstancePoolOOM {
        public static void main(String[] args) {
            int i = 0;
            List<String> list = new ArrayList<String>();
            while(true) {
                list.add(String.valueOf(i++).intern());
            }
        }
    }

以上代码在JDK1.6运行时会抛*java.lang.OutOfMemoryError: PermGen space*错误。Jdk1.7不会出现此错误。*TODO*
String.intern方法检查当前String是否在常量池中，如果存在，返回该对象；否则将当前对象放入常量池并返回其引用；

## 直接内存溢出

JVM通过参数 -XX:MaxDirectMemorySize 指定可用直接内存的大小，如果不指定，则默认与-Xms最大对内存大小相同
Java使用直接内存有两种方法：一种是使用sun.misc.UnSafe类来申请直接内存；另外就是直接调用nio的ByteBuffer.allocateDirect()方法。

### sun.misc.Unsafe申请直接内存：

直接使用以下代码申请直接内存空间：

    Unsafe unsafe = Unsafe.getUnsafe();
    unsafe.allocateMemory(1024*1024);
   
会报如下的错误：

    Exception in thread "main" java.lang.SecurityException: Unsafe
    	at sun.misc.Unsafe.getUnsafe(Unsafe.java:90)
    	at DirectMemoryOOM.main(DirectMemoryOOM.java:9)
    	at sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)
    	at sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:57)
    	at sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)
    	at java.lang.reflect.Method.invoke(Method.java:606)
    	at com.intellij.rt.execution.application.AppMain.main(AppMain.java:140)

官方的解释是：
> Although the class and all methods are public, use of this class is limited because only trusted code can obtain instances of it.

解决方案就是使用反射：

    Field f = Unsafe.class.getDeclaredField("theUnsafe");
    f.setAccessible(true);
    Unsafe us = (Unsafe) f.get(null);
    long p = us.allocateMemory(1000);
    us.freeMemory(p);
    
直接内存溢出代码如下：

    //JVM args: -Xms10m -Xmx10m -XX:MaxDirectMemorySize=10m
    public class DirectMemoryOOM {
        public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
            Field f = Unsafe.class.getDeclaredFields()[0];
            f.setAccessible(true);
            Unsafe us = (Unsafe) f.get(null);
            long size = 1024 * 1024 * 1024;
            while (true) {
                long p = us.allocateMemory(size);
                for (int i = 0; i < size; i++) {
                    us.putByte(p + i, Byte.MAX_VALUE);
                }
            }
        }
    }
    
上述代码在MacOS jdk1.7上运行，内存分配会暴涨并开始使用交换分区，但不会报OOM错误。
在[StackOverFlow](http://stackoverflow.com/questions/28670700/java-unsafe-memory-allocation-limit)上的回答是直接调用了操作系统的malloc函数，从而不受虚拟机参数的限制。呃，太凶险了。尽信书不如无书，周志明的《深入理解JAVA虚拟机》也有BUG。

### Java NIO申请直接内存：

其实有了Java NIO之后，使用直接内存比Unsafe要方便的多：
    
    //JVM args: -Xms10m -Xmx10m -XX:MaxDirectMemorySize=10m
    public class DirectMemoryOOM {
        public static void main(String[] args) throws NoSuchFieldException, IllegalAccessException {
            int size = 1024 * 1024;
            System.out.println(sun.misc.VM.maxDirectMemory());
            while (true) {
                ByteBuffer.allocateDirect(size);
            }
        }
    }

上面这段程序很快就可以造成OOM错误，JVM退出。翻了一下ByteBuffer.allocateDirect()的实现，里面就是用的Unsafe.allocateMemory()函数。这难道不很奇怪？
原来是我没有仔细看，JDK1.7 java.nio.Bits line:123 调用了Bits.reserveMemory()，这个方法对申请内存大小进行了检查，超出之后抛出OOM错误。

    // These methods should be called whenever direct memory is allocated or
    // freed.  They allow the user to control the amount of direct memory
    // which a process may access.  All sizes are specified in bytes.
    static void reserveMemory(long size, int cap) {
        ...
        synchronized (Bits.class) {
                    if (totalCapacity + cap > maxMemory)
                        throw new OutOfMemoryError("Direct buffer memory");
                    reservedMemory += size;
                    totalCapacity += cap;
                    count++;
        }
        ...
    }
    
并且，在Bits.java中，也有根据-XX:MaxDirectMemorySize=<size>初始化的代码：
    
    // initialization if it is launched with "-XX:MaxDirectMemorySize=<size>".
    private static volatile long maxMemory = VM.maxDirectMemory();

参见：[StackOverFlow](http://stackoverflow.com/questions/29702028/why-xxmaxdirectmemorysize-cant-limit-unsafe-allocatememory)
    
