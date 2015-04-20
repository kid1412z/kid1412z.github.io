title: "Java finalize方法"
date: 2015-04-20 10:49:05
categories: Java
tags: [Java,JVM,GC]
---
**摘要**：本文简单介绍了Java finalize方法，以及运行时是否可能查看对象的GC状态。
**Abstract**: This article introduces the Java finalize method, and whether it is possible to view the status of the runtime object GC.
<!-- more -->

即使在[可达性分析算法](/2015/04/20/java-gc-reference/)中不可达的对象，也并非是非死不可，对象要被回收，至少需要以下两个过程：
* 根据是否有必要执行finalize方法进行第一次筛选（如果finalize方法没有被覆盖或者JVM已经调用过，视为*没有必要执行*）。如果对象被判定为有必要执行finalize方法，则被加入F-Queue队列，稍后由JVM建立的低优先级的Finalizer线程调用其finalize方法（为防止死循环或者调用缓慢阻塞队列中其他对象，JVM不保证等待调用执行完毕）。
* 对象在finalize方法中，与GC Roots重新建立了连接，则不会被回收；否则对象将被回收。

在《深入理解Java虚拟机》中
http://stackoverflow.com/questions/4223956/check-if-object-can-be-fetched-by-garbage-collector

*注*：任何对象的finalize方法都只会被JVM调用一次，如果对象面临第二次回收过程，finalize方法将不会被再次调用。

    public class FinalizeTest {
        public static FinalizeTest SAVE_HOOK = null;
    
        public void alive() {
            System.out.println("I am alive!");
        }
    
        public static void die() {
            System.out.println("Die!");
        }
    
        @Override
        protected void finalize() throws Throwable {
            super.finalize();
            SAVE_HOOK = this;
            System.out.println("finalize()");
        }
    
        public static void main(String[] args) throws InterruptedException {
            SAVE_HOOK = new FinalizeTest();
            for (int i = 0; i < 2; i++) {
                gc();
                if (SAVE_HOOK != null) {
                    SAVE_HOOK.alive();
                } else {
                    die();
                }
            }
        }
    
        private static void gc() throws InterruptedException {
            SAVE_HOOK = null;
            System.gc();
            Thread.sleep(500);
        }
    }
    
*以上代码验证了finalize()方法只会被JVM调用一次，但不能说明对象是否在运行过程中是否已经被回收掉！换句话说，在运行时判断一个对象是否已经被回收掉是**不可能**的（[参见这里](http://stackoverflow.com/questions/4223956/check-if-object-can-be-fetched-by-garbage-collector)）。*

*finalize方法可以被try-finally替代，并处理的更好更及时。*