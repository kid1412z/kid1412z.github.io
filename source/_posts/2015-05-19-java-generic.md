title: "深入Java泛型"
date: 2015-05-19 21:34:22
categories: Java
tags: [Java,generic]
---
**摘要**：本文参考Oracle的文档，系统介绍了Java泛型和使用中应注意的问题。
**Abstract**:
<!-- more -->
## 为什么使用泛型

简而言之，泛型就是在定义类、接口、方法的时候，可以把类型（types）作为参数。类型参数使相同的逻辑能够复用在不同类型的输入上。

### 使用泛型的好处：

* 编译期强类型检查（编译期错误排查难度小于运行时错误）
* 去除类型转换


    List list = new ArrayList();
    list.add("hello");
    String s = (String) list.get(0);

    List<String> list = new ArrayList<String>();
    list.add("hello");
    String s = list.get(0);   // no cast
    
* 方便开发泛型算法

## 泛型类型（Generic Types）

泛型类型是通用类或者接口的参数化类型。

### 简单的Box类

    public class Box {
        private Object object;
    
        public void set(Object object) { this.object = object; }
        public Object get() { return object; }
    }

因为类中的方法接受的参数类型是Object，所以可以接受任何类型的输入参数，。但是在编译期没有办法验证Box类是否被正确的使用了。如果期望从Box中获得一个Integer而却往Box中放入String类型的值，则会出现运行时错误。

### 泛型版本的Box类

泛型类/接口的定义如下：

    class name<T1, T2, ..., Tn> { /* ... */ }
    interface name<T1, T2, ..., Tn> { /* ... */ }

尖括号中包含类型参数声明，分别是T1,T2...Tn

    /**
     * Generic version of the Box class.
     * @param <T> the type of the value being boxed
     */
    public class Box<T> {
        // T stands for "Type"
        private T t;
    
        public void set(T t) { this.t = t; }
        public T get() { return t; }
    }

正如上面代码所示，Object类型被替换为T，T是一个类型变量，代表任意非原始类型（non-primitive）。 作为一个例子，并没有问题，但是结合JDK源码，get方法一般不限定泛型，[详见这里](http://stackoverflow.com/questions/857420/what-are-the-reasons-why-map-getobject-key-is-not-fully-generic)。不要滥用泛型！

### 类型参数命名惯例

* E - Element (used extensively by the Java Collections Framework)
* K - Key
* N - Number
* T - Type
* V - Value
* S,U,V etc. - 2nd, 3rd, 4th types

### 调用和实例化泛型类型

    Box<Integer> integerBox = new Box<Integer>();

> **类型形参（Type Parameter）**和**类型实参（Type Argument）**：Box<T>中的T时类型形参，Box<Integer>中的Integer时类型实参。在能区分两者的语境中，经常不做区分的称为类型参数。

<a id="the-diamond" href="#the-diamond"></a>
### The Diamond

在JDK7及以后的版本，调用和初始化泛型可以省略构造方法类型实参：
    
    Box<Integer> integerBox = new Box<>();

更多内容请参见[类型推断（Type Inference）](#type-inference)

### 多个类型参数

    public interface Pair<K, V> {
        public K getKey();
        public V getValue();
    }
    
    public class OrderedPair<K, V> implements Pair<K, V> {
    
        private K key;
        private V value;
    
        public OrderedPair(K key, V value) {
    	this.key = key;
    	this.value = value;
        }
    
        public K getKey()	{ return key; }
        public V getValue() { return value; }
    }
    
可以这样实例化OrderedPair：

    Pair<String, Integer> p1 = new OrderedPair<String, Integer>("Even", 8);
    Pair<String, String>  p2 = new OrderedPair<String, String>("hello", "world");
    
正如在[The Diamond](#the-diamond)一节中所述的，可以将初始化构造方法类型参数省略：

    OrderedPair<String, Integer> p1 = new OrderedPair<>("Even", 8);
    OrderedPair<String, String>  p2 = new OrderedPair<>("hello", "world");

### 参数化类型嵌套

    OrderedPair<String, Box<Integer>> p = new OrderedPair<>("primes", new Box<Integer>(...));

## 原始类型（Raw Types）

原始类型是没有任何类型实参的泛型类或泛型接口。例如:Box类定义如下：

    public class Box<T> {
        public void set(T t) { /* ... */ }
        // ...
    }
    
如果类型实参被省略，则创建一个原始类型的Box：

    Box rawBox = new Box();
    
上面的代码中，Box是Box<T>的原始类型。JDK5及之前的代码不支持泛型，为了向后兼容设置的。

未完待续。。。

<a id="type-inference" href="#type-inference"></a>
## 类型推断（Type Inference）

## 参考

[https://docs.oracle.com/javase/tutorial/java/generics/index.html](https://docs.oracle.com/javase/tutorial/java/generics/index.html)






