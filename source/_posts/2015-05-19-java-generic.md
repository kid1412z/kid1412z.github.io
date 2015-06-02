title: "深入Java泛型"
date: 2015-05-19 21:34:22
categories: Java
tags: [Java,generic]
---
**摘要**：泛型可以将某些类型相关的错误从运行时提前到编译时显现，但Java泛型尤其特殊性和不彻底性，稍不注意就会犯错误，甚至影响到设计。这篇博文参照Oracle给出的教程，全面的介绍了Java泛型的重要知识点。
**Abstract**: Java generics add stability to your code by making some bugs about types be detected early on complie-time. This article gives a comprehensive introduction to the important points Java generics.
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

正如上面代码所示，Object类型被替换为T，T是一个类型变量，代表任意非基本类型（non-primitive）。 作为一个例子，并没有问题，但是结合JDK源码，get方法一般不限定泛型，[详见这里](http://stackoverflow.com/questions/857420/what-are-the-reasons-why-map-getobject-key-is-not-fully-generic)。不要滥用泛型！

### 类型参数命名惯例

* E - Element (used extensively by the Java Collections Framework)
* K - Key
* N - Number
* T - Type
* V - Value
* S,U,V etc. - 2nd, 3rd, 4th types

### 调用和实例化泛型类型

    Box<Integer> integerBox = new Box<Integer>();

> **类型形参（Type Parameter）**和**类型实参（Type Argument）**：`Box<T>`中的T时类型形参，`Box<Integer>`中的Integer时类型实参。在能区分两者的语境中，经常不做区分的称为类型参数。

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

<a id="raw-types" href="#raw-types"></a>
## 原始类型（Raw Types）

原始类型是没有任何类型实参的泛型类或泛型接口。例如:Box类定义如下：

    public class Box<T> {
        public void set(T t) { /* ... */ }
        // ...
    }
    
如果类型实参被省略，则创建一个原始类型的Box：

    Box rawBox = new Box();
    
上面的代码中，Box是`Box<T>`的原始类型。但如果Box不是泛型类，创建的对象就不能叫做Box的原始类型。JDK5及之前的代码不支持泛型，为了向前兼容设置的。把一个泛型对象赋值给原始类型引用是被允许的。

    Box<String> stringBox = new Box<>();
    Box rawBox = stringBox;               // OK

但是如果你将原始类型赋值给泛型引用，则会产生警告：

    Box rawBox = new Box();           // rawBox is a raw type of Box<T>
    Box<Integer> intBox = rawBox;     // warning: unchecked conversion


使用原始类型的引用去调用泛型类对象的方法，同样会得到警告：

    Box<String> stringBox = new Box<>();
    Box rawBox = stringBox;
    rawBox.set(8);  // warning: unchecked invocation to set(T)

原因是使用原始类型的引用去调用泛型类对象的方法，把可能的类型错误推迟到了运行时才能发现。在[类型擦除](#type-erasure)部分，将详细介绍编译器如何使用原始类型的。

### 未检查错误信息（Unchecked Error Messages）

如上面提到的，如果你将泛型代码与遗留的非泛型代码混合使用，就会出现类似下面的编译警告信息：

    Note: Example.java uses unchecked or unsafe operations.
    Note: Recompile with -Xlint:unchecked for details.

如下面所示，当代码试图使用原始类型引用操作泛型类的对象时：

    public class WarningDemo {
        public static void main(String[] args){
            Box<Integer> bi;
            bi = createBox();
        }
    
        static Box createBox(){
            return new Box();
        }
    }
    
*unchecked*的意思是编译器没有得到足够的类型信息做必要的的类型检查以确保类型安全。尽管编译器会做出提示，但是unchecked警告默认是关闭的，如果需要查看详细的unchecked警告信息，需要在编译时加上*-Xlint:unchecked选项*。
重新编译后会得到像下面这样详细的提示结果：

    WarningDemo.java:4: warning: [unchecked] unchecked conversion
    found   : Box
    required: Box<java.lang.Integer>
            bi = createBox();
                          ^
    1 warning

当不需要unchecked警告信息的时候，需要显式的使用-Xlint:-unchecked编译选项，或者使用@SuppressWarnings("unchecked")注解。

<a id="generic-methods" href="#generic-methods"></a>
## 泛型方法（Generic Methods）

泛型方法是自身引入类型参数的方法。与泛型类和接口引入的泛型参数不同，其作用范围只在方法声明范围内有效。静态方法、非静态方法以及泛型类的构造方法都可以声明为泛型方法。

    public class Util {
        public static <K, V> boolean compare(Pair<K, V> p1, Pair<K, V> p2) { //静态泛型方法
            return p1.getKey().equals(p2.getKey()) &&
                   p1.getValue().equals(p2.getValue());
        }
    }
    
    public class Pair<K, V> {
    
        private K key;
        private V value;
    
        public Pair(K key, V value) {
            this.key = key;
            this.value = value;
        }
    
        public void setKey(K key) { this.key = key; }
        public void setValue(V value) { this.value = value; }
        public K getKey()   { return key; }
        public V getValue() { return value; }
    }

调用上述静态泛型方法的正确语法如下：

    Pair<Integer, String> p1 = new Pair<>(1, "apple");
    Pair<Integer, String> p2 = new Pair<>(2, "pear");
    boolean same = Util.<Integer, String>compare(p1, p2);  //在.和方法名之间加入<>
    
一般情况下，编译器会做[类型推断](#type-inference)，调用泛型方法时可以不写全。

    Pair<Integer, String> p1 = new Pair<>(1, "apple");
    Pair<Integer, String> p2 = new Pair<>(2, "pear");
    boolean same = Util.compare(p1, p2);

## 有界类型参数（Bounded Type Parameters）

在有些时候，我们想限制类型参数的范围，比如针对Numbers的泛型方法，想限制直接收Numbers和它的所有子类型。这就需要限定泛型参数的界限。
在声明类型参数的时候，可以使用*extends XXX*（对类和接口来说都应该使用该关键字）限定类型参数的上限是XXX。

    public class Box<T> {
    
        private T t;          
    
        public void set(T t) {
            this.t = t;
        }
    
        public T get() {
            return t;
        }
    
        public <U extends Number> void inspect(U u){
            System.out.println("T: " + t.getClass().getName());
            System.out.println("U: " + u.getClass().getName());
        }
    
        public static void main(String[] args) {
            Box<Integer> integerBox = new Box<Integer>();
            integerBox.set(new Integer(10));
            integerBox.inspect("some text"); // error: this is still String!
        }
    }

编译器会提示如下的编译错误：

    Box.java:21: <U>inspect(U) in Box<java.lang.Integer> cannot
      be applied to (java.lang.String)
                            integerBox.inspect("some text");
                                      ^
    1 error

除了限定类型，你还可以实例化一个泛型类型。

    public class NaturalNumber<T extends Integer> {
    
        private T n;
    
        public NaturalNumber(T n)  { this.n = n; }
    
        public boolean isEven() {
            return n.intValue() % 2 == 0;
        }
    
        // ...
    }



### 多个界限（Multiple Bounds）

一个类型参数可以有多个界限：

    <T extends B1 & B2 & B3>

表示T的上界是B1或者B2或者B3，如果其中一个类型参数是类，则必须放在第一个：

    Class A { /* ... */ }
    interface B { /* ... */ }
    interface C { /* ... */ }
    class D <T extends A & B & C> { /* ... */ }  // OK
    class D <T extends B & A & C> { /* ... */ }  // compile-time error
    
### 有界类型参数和泛型方法

    public static <T> int countGreaterThan(T[] anArray, T elem) {
        int count = 0;
        for (T e : anArray)
            if (e > elem)  // compiler error
                ++count;
        return count;
    }
    
上面的代码会产生编译错误，原因是>运算符只能用于比较基本类型（Primitive Types）如：short, int, double, long, float, byte, 和 char。
解决这个问题，可以使用上界为`Comparable<T>`的类型参数：

    public interface Comparable<T> {
        public int compareTo(T o);
    }
    
    public static <T extends Comparable<T>> int countGreaterThan(T[] anArray, T elem) {
        int count = 0;
        for (T e : anArray)
            if (e.compareTo(elem) > 0)
                ++count;
        return count;
    }

<a id="g-i-s" href="#g-i-s"></a>
## 泛型、继承和子类型（Generics, Inheritance, and Subtypes）

如果两个类型兼容，可以把一个类型的对象赋予另个一类型的引用。例如：

    Object someObject = new Object();
    Integer someInteger = new Integer(10);
    someObject = someInteger;   // OK

在面向对象术语中成为：*"Is-a"*关系。因为Integer类型也是一种Object类型。下面的代码也成立，因为Double和Integer都是Number：

    public void someMethod(Number n) { /* ... */ }
    
    someMethod(new Integer(10));   // OK
    someMethod(new Double(10.1));   // OK
    
以上继承规则对于类型参数来说也是成立的，你可以想Box中添加任何和Number兼容的子类型：

    Box<Number> box = new Box<Number>();
    box.add(new Integer(10));   // OK
    box.add(new Double(10.1));  // OK

但是考虑如下的方法：

    public void boxTest(Box<Number> n) { /* ... */ }

boxTest方法会接受什么类型的参数？如果传入`Box<Integer>`或者`Box<Double>`可以吗？答案是*不可以*，因为**`Box<Integer>`和`Box<Double>`不是`Box<Number>`的子类型**！

![generic subtypes](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-05-19/1.png)

> 注意：给定两个具体类型A和B（如：Integer和Double），无论A，B两个类有什么样的关系，`MyClass<A>` 和 `MyClass<B>` 两个类没有任何关系，他们唯一相同的父类就是Object。关于如何创建一个泛型类的子类型，参见[通配符和子类型](#wildcards-and-subtyping)

### 泛型类和子类型

你可以通过继承泛型类或者实现泛型接口来创建一个泛型类或者泛型接口的子类型（subtype）。以Java集合类为例：

![Collections hierarchy](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-05-19/2.png)

若自己实现一个PayloadList类：

    interface PayloadList<E,P> extends List<E> {
      void setPayload(int index, P val);
      ...
    }

以下类型实参的PayLoadList是ListString>的子类型（subtype）：
    
    PayloadList<String,String>
    PayloadList<String,Integer>
    PayloadList<String,Exception>
    
而任何`PayloadList<XXX,...>`都不是`List<String>`的子类型。

<a id="type-inference" href="#type-inference"></a>
## 类型推断（Type Inference）

类型推断是Java编译器根据方法调用和相应的声明去推断类型实参的过程。类型推断算法往往取决于实参类型、赋值操作等号右边的类型或返回值类型。最后，类型推断算法会找到适合所有条件的最具体的类型作为推断结果。
例如，下面的例子，类型推断的结果是Serializable：

    static <T> T pick(T a1, T a2) { return a2; }
    Serializable s = pick("d", new ArrayList<String>());

### 泛型方法的类型推断

[泛型方法](#generic-methods)引入了类型推断，类型推断使你能够像调用普通方法那样调用泛型方法，如下代码所示：

    public class BoxDemo {
    
      public static <U> void addBox(U u, 
          java.util.List<Box<U>> boxes) {
        Box<U> box = new Box<>();
        box.set(u);
        boxes.add(box);
      }
    
      public static <U> void outputBoxes(java.util.List<Box<U>> boxes) {
        int counter = 0;
        for (Box<U> box: boxes) {
          U boxContents = box.get();
          System.out.println("Box #" + counter + " contains [" +
                 boxContents.toString() + "]");
          counter++;
        }
      }
    
      public static void main(String[] args) {
        java.util.ArrayList<Box<Integer>> listOfIntegerBoxes =
          new java.util.ArrayList<>();
        BoxDemo.<Integer>addBox(Integer.valueOf(10), listOfIntegerBoxes);
        BoxDemo.addBox(Integer.valueOf(20), listOfIntegerBoxes);
        BoxDemo.addBox(Integer.valueOf(30), listOfIntegerBoxes);
        BoxDemo.outputBoxes(listOfIntegerBoxes);
      }
    }

代码输出：

    Box #0 contains [10]
    Box #1 contains [20]
    Box #2 contains [30]

泛型方法*addBox*定义了类型形参U，通常Java编译器可以通过方法调用推断类型实参，所以在多数情况下，不需要指定类型实参。例如调用方法addBox时，可以像这样指定类型实参：

    BoxDemo.<Integer>addBox(Integer.valueOf(10), listOfIntegerBoxes);

也可以不指定，由编译器根据参数类型推断类型实参为Integer：

    BoxDemo.addBox(Integer.valueOf(20), listOfIntegerBoxes);

### 构造方法的类型推断

如果编译器可以根据上下文推断类型实参，则可以在调用构造方法时省略类型实参，例如：

    Map<String, List<String>> myMap = new HashMap<String, List<String>>();
    
也可以写成这样：

    Map<String, List<String>> myMap = new HashMap<>();

但是为了能够使编译器进行类型推断，调用构造方法的时候必须使用[the diamond](#the-diamond)，否则编译器报编译警告：

    Map<String, List<String>> myMap = new HashMap(); // unchecked conversion warning
    
原因是HashMap()构造方法是HashMap<String, List<String>>的原始类型（[raw types](#raw-types)）

> 无论在泛型类还是在非泛型类中，都可以存在泛型构造方法：

    class MyClass<X> {
      <T> MyClass(T t) {
        // ...
      }
    }

初始化MyClass实例：

    new MyClass<Integer>("")

上面的语句创建了`MyClass<Integer>`的对象，显式的指明泛型类`MyClass<X>`的类型实参是Integer。但是MyClass的构造方法包含类型形参T并没有被显式的赋值。编译器通过传入构造方法的String类型的参数推断类型参数T的实参是String类型。
在Java SE 7 之前的版本，编译器已经具备推断泛型构造方法类型实参的能力，Java SE 7及之后的版本，编译器可以推断泛型类的类型实参（必须使用[the diamond](#the-diamond)）

    MyClass<Integer> myObject = new MyClass<>("");
    
上面的语句，编译器既可以推断出泛型类的类型实参，也可以推断出泛型构造方法的类型实参。

> 注意：类型推断算法只使用*调用参数*、*目标类型*和*明显知道类型的返回值*来推断类型实参，推断算法不会使用当前程序之后的程序段对类型做推断。

### 目标类型

Java编译器利用目标类型推断泛型方法调用时的参数类型。表达式的目标类型是Java编译器根据表达式出现的位置，**期望的表达式的类型**。例如：有Collections.emptyList()方法的声明如下：

    static <T> List<T> emptyList();

若有以下的赋值语句：

    List<String> listOne = Collections.emptyList();

则期望的结果类型是`List<String>`；此类型即为目标类型。因为方法emptyList返回一个`List<T>`类型的值，编译器推断类型形参T一定是String。此机制Java SE 7 和 Java SE 8 都适用当然你也可以显示的指定泛型方法的类型参数：

    List<String> listOne = Collections.<String>emptyList();

当然，这在上下文语境中并**不是必须的**。但在下面的情况下：

    void processStringList(List<String> stringList) {
        // process stringList
    }

将设你想调用方法processStringList，传入一个空list，在Java SE 7中，下面的语句会出现编译错误：

    processStringList(Collections.emptyList());

错误大致是：

    List<Object> cannot be converted to List<String>
    
编译器需要类型实参T，所以被默认当成`List<Object>`，进而emptyList方法返回`List<Object>`类型的结果，和processStringList方法的参数类型不兼容。因此，在Java SE 7中，必须指定类型参数的值的值：

    processStringList(Collections.<String>emptyList());

这种情况在Java SE 8中将不复存在，在Java SE 8中，*目标类型*的范围被扩展到包括方法参数。即可以通过形参的类型参数推断返回值的类型参数。
因为形参是`List<String>`,Collections.emptyList返回`List<T>`类型的结果，`List<String>`被作为目标类型，编译器推断T为String类型。因此，下面的语句在Java SE 8中可以编译通过：

    processStringList(Collections.emptyList());
    
## 通配符（Wildcard）

泛型编程中，把问号（?）称为*通配符*，表示未知类型。通配符在很多情况下会用到：类型参数、属性、局部变量，甚至是返回类型（尽管明确的返回值类型才是好的编程习惯）。但*绝不会用于*：泛型方法调用的类型实参、泛型类实例化、超类型（supertype）。

### 有上界的通配符

你可以通过上界通配符减轻泛型对变量类型的限制。例如，你希望一个泛型方法同时能处理`List<Integer>`, `List<Double>` 和 `List<Number>`，你可以使用上界通配符。
应使用*?*和*extends*关键字（无论接口还是类），例如`List<? extends Number>`。 `List<Number>` 比`List<? extends Number>`的限制更严格。因为前者的匹配类型只有Number类型，而后者任何Number和Number的子类型都适用。
下面的process方法可以处理类型是任何Foo类或者Foo类的子类型。

    public static void process(List<? extends Foo> list) {
        for (Foo elem : list) {
            // ...
        }
    }

下面的sumOfList方法, `List<Integer>` 和 `List<Double>`都适用：

    public static double sumOfList(List<? extends Number> list) {
        double s = 0.0;
        for (Number n : list)
            s += n.doubleValue();
        return s;
    }
    
    List<Integer> li = Arrays.asList(1, 2, 3);
    System.out.println("sum = " + sumOfList(li));
    
    List<Double> ld = Arrays.asList(1.2, 2.3, 3.5);
    System.out.println("sum = " + sumOfList(ld));

### 无界通配符

无界通配符用一个单独的*?*表示，例如`List<?>`表示未知类型的List，一般无界通配符用于以下两个场景：
* 如果你正在写可以使用Object类提供的功能来实现的方法。
* 当使用泛型类中的不依赖于类型参数的方法时，例如List.size和List.clear. `Class<?>`经常被使用，因为`Class<T>`类中的大部分方法和类型参数T无关。

```    
    public static void printList(List<Object> list) {
        for (Object elem : list)
            System.out.println(elem + " ");
        System.out.println();
    }
```

如果上面的printList目的是打印任何类型的对象列表的话，是实现不了的。原因是`List<Integer>`, `List<String>`, `List<Double>`等都不是`List<Object>`的子类型。如果需要打印任何类型的对象，需要使用通配符：

    public static void printList(List<?> list) {
        for (Object elem: list)
            System.out.print(elem + " ");
        System.out.println();
    }

因为对于任意的具体类型T来说，`List<T>`是`List<?>`的子类型，你可以使用printList方法打印任意类型的对象列表。

    List<Integer> li = Arrays.asList(1, 2, 3);
    List<String>  ls = Arrays.asList("one", "two", "three");
    printList(li);
    printList(ls);

> 需要注意`List<Object>` 和 `List<?>`是不同的，你可以向`List<Object>`中插入任何Object的子类型的对象，但是你只能向`List<?>`中插入null。更多关于通配符应该在什么情况下使用，请参见[通配符使用指南](#wildcards-guideline)

### 有下界的通配符

和有上界的通配符相反，有下界的通配符使用`<? super A>` 表示通配符的下界是A。

> 注意，你可以指定上界，也可以指定下界，但是不同同时指定两者。

如果你想要一个方法能够处理Integer类型以及所有Integer类型的父类，则可以使用有下界的通配符：

```
    public static void addNumbers(List<? super Integer> list) {
        for (int i = 1; i <= 10; i++) {
            list.add(i);
        }
    }
```

<a id="wildcards-and-subtyping" href="#wildcards-and-subtyping"></a>
### 通配符和子类型

在[泛型、继承和子类型](#g-i-s)一节，我们曾经说过，仅仅类型参数有继承关系的泛型类或者泛型接口之间没有任何继承关系。但是你可以通过通配符建立泛型类和接口之间的继承关系。

```
    class A { /* ... */ }
    class B extends A { /* ... */ }
```

则你可以这样写代码：

```
   B b = new B();
   A a = b;
```

对于普通的类来说，子类型规则是成立的：如果B继承A，那么B是A的子类型。但是这个规则对于泛型类型来说，不适用。

Integer是Number类的子类，`List<Integer>`和`List<Number>`是什么关系？

![subtype](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-05-19/3.png)

尽管Integer是Number的子类型，但是`List<Integer>`和`List<Number>`并没有继承关系。它们之间仅有的关系就是共同的父类是`List<?>`.
下图说明了有上下界通配符的泛型类之间的继承关系：

![subtype-wildcard](http://7xi4cl.com1.z0.glb.clouddn.com/images/2015-05-19/4.png)

在[通配符使用指南](#wildcards-guidline)一节，将介绍更多关于上下界通配符的使用方法。

### 通配符捕获和辅助方法

在某些情况下，编译器会推断通配符的类型。例如，一个列表被定义为`List<?>`，当计算表达式的值的时候，编译器会根据代码推断出特定的类型。这种场景就叫做*通配符捕获（Wildcard Capture）*。
在大部分情况下，你都不需要关注通配符捕获，除非你得到包含*capture of*的错误提示。


```
    import java.util.List;
    
    public class WildcardError {
    
        void foo(List<?> i) {
            i.set(0, i.get(0));
        }
    }
```

在上面的代码中，编译器处理输入参数i时，把它的类型参数当成Object，当触发`List.set(int,E)`时，编译器无法确定set进list中的对象类型，从而报错。当有类型错误提示的时候，往往是编译器认为你对变量设置了错误的类型。添加泛型，正是为了解决编译期类型检查。
例如使用JDK 7编译上面的代码的时候，会提示如下的错误：

    WildcardError.java:6: error: method set in interface List<E> cannot be applied to given types;
        i.set(0, i.get(0));
         ^
      required: int,CAP#1
      found: int,Object
      reason: actual argument Object cannot be converted to CAP#1 by method invocation conversion
      where E is a type-variable:
        E extends Object declared in interface List
      where CAP#1 is a fresh type-variable:
        CAP#1 extends Object from capture of ?
    1 error

你可以写一个私有的辅助方法来解决上面的错误：

```
    public class WildcardFixed {
    
        void foo(List<?> i) {
            fooHelper(i);
        }
    
    
        // Helper method created so that the wildcard can be captured
        // through type inference.
        private <T> void fooHelper(List<T> l) {
            l.set(0, l.get(0));
        }
    
    }
```

辅助方法使编译器能够通过类型推断，得到T的类型是`CAP#1`。辅助方法惯例命名方式`originalMethodNameHelper`。
再看一个稍微复杂的例子：

```
    import java.util.List;
    
    public class WildcardErrorBad {
    
        void swapFirst(List<? extends Number> l1, List<? extends Number> l2) {
          Number temp = l1.get(0);
          l1.set(0, l2.get(0)); // expected a CAP#1 extends Number,
                                // got a CAP#2 extends Number;
                                // same bound, but different types
          l2.set(0, temp);	    // expected a CAP#1 extends Number,
                                // got a Number
        }
    }
```

这个例子尝试不安全的操作，例如用下面的方式调用`swapFirst`方法：

```
    List<Integer> li = Arrays.asList(1, 2, 3);
    List<Double>  ld = Arrays.asList(10.10, 20.20, 30.30);
    swapFirst(li, ld);
```

尽管`List<Integer>`和`List<Double>`都满足`List<? extends Number>`的类型限制，但试图把Integer列表中的元素放入Double类型的列表中肯定是错误的。
JDk javac程序编译以上代码会报类似下面的错误：

    WildcardErrorBad.java:7: error: method set in interface List<E> cannot be applied to given types;
          l1.set(0, l2.get(0)); // expected a CAP#1 extends Number,
            ^
      required: int,CAP#1
      found: int,Number
      reason: actual argument Number cannot be converted to CAP#1 by method invocation conversion
      where E is a type-variable:
        E extends Object declared in interface List
      where CAP#1 is a fresh type-variable:
        CAP#1 extends Number from capture of ? extends Number
    WildcardErrorBad.java:10: error: method set in interface List<E> cannot be applied to given types;
          l2.set(0, temp);      // expected a CAP#1 extends Number,
            ^
      required: int,CAP#1
      found: int,Number
      reason: actual argument Number cannot be converted to CAP#1 by method invocation conversion
      where E is a type-variable:
        E extends Object declared in interface List
      where CAP#1 is a fresh type-variable:
        CAP#1 extends Number from capture of ? extends Number
    WildcardErrorBad.java:15: error: method set in interface List<E> cannot be applied to given types;
            i.set(0, i.get(0));
             ^
      required: int,CAP#1
      found: int,Object
      reason: actual argument Object cannot be converted to CAP#1 by method invocation conversion
      where E is a type-variable:
        E extends Object declared in interface List
      where CAP#1 is a fresh type-variable:
        CAP#1 extends Object from capture of ?
    3 errors

没有辅助方法能够解决上面的问题，因为代码压根是错误的。

<a id="wildcards-guideline" href="#wildcards-guideline"></a>
### 通配符使用指南

使用带上下界的通配符是Java泛型中最容易让人产生迷惑的地方，这一节将提供一些代码设计上的指南。
为了方便后续讨论，读者应该理解一个变量有如下的两个功能：

* **传入参数（An "In" Variable）：** 传入参数在代码中往往作为数据使用，例如`copy(src,dest)`函数有两个参数，src作为被拷贝的对象，是传入变量，习惯上叫做*入参*。
* **传出参数（An "Out" Variable)：** 传出参数在代码中往往作为结果使用，例如`copy(src,dest)`函数中的dest就是传出参数，习惯上称为*传出参数*。

当然有些变量既被用做传入变量又被用作传出变量，这种情况在这一小节中也有讨论。
你可以结合*in*和*out*的原则，用下面列表中的tips作为决定使用哪种泛型通配符的依据：

> **通配符使用指南**
* 传入参数用上界通配符extends关键字
* 传出参数用下界通配符super关键字
* 传入参数在代码中可被当做Object对象访问时，使用无界通配符
* 既是传入参数又是传出参数时，不要使用通配符

> 注：上面的这些规则不适用与方法的返回类型，应该避免在返回值中使用通配符，因为这样强迫方法使用者去写额外的代码处理通配符。

如果列表定义为`List<? extends ...>`则非正规的定义了一个只读的列表，但不严格保证列表是只读的。
假设有如下的两个类：

```
    class NaturalNumber {
    
        private int i;
    
        public NaturalNumber(int i) { this.i = i; }
        // ...
    }
    
    class EvenNumber extends NaturalNumber {
    
        public EvenNumber(int i) { super(i); }
        // ...
    }
```

下面的代码会产生编译错误：：

```
    List<EvenNumber> le = new ArrayList<>();
    List<? extends NaturalNumber> ln = le;
    ln.add(new NaturalNumber(35));  // compile-time error
```

因为`List<EvenNumber>`是`List<? extends NaturalNumber>`的子类型，你可以把le赋值给ln，但是你不能向`EvenNumber`列表中添加`NaturalNumber`。你可以对`List<? extends ...>`列表做如下的操作：

* add null
* 调用 `clear()`
* 得到列表的Iterator并调用`remove()`方法
* 捕获通配符类型并把从列表读取的元素添加到列表

可以看到含有通配符的列表并非是只读的，但你无法添加新的非空元素，也无法改变已有元素。

<a id="type-erasure" href="#type-inference"></a>
## 类型擦除（Type Erasure）

Java语言通过引入泛型来提供更严格的编译期类型检查，为了实现泛型，Java编译器应用类型擦除：
* 将所有类型参数替换为通配符的界限或Object（如果无界限），产生的字节码只包含普通的那个的类、接口和方法。
* 如果需要保证类型安全，还需要插入类型转换。
* 生成桥接方法来保持泛型类型的多态性。

类型擦除确保了没有任何新的类型创建，从而不会造成任何运行时的开销。

### 泛型类的类型擦除

在类型擦除过程中，Java编译器将删除所有类型参数，并替换类型参数为他的界限，如果没有界限，将替换为Object。
例如：

```
    public class Node<T> {
    
        private T data;
        private Node<T> next;
    
        public Node(T data, Node<T> next) }
            this.data = data;
            this.next = next;
        }
    
        public T getData() { return data; }
        // ...
    }
```

因为类型参数没有界限，编译器将类型参数替换为Object。

```
   public class Node {
   
       private Object data;
       private Node next;
   
       public Node(Object data, Node next) {
           this.data = data;
           this.next = next;
       }
   
       public Object getData() { return data; }
       // ...
   }
```

如果类型参数有界限：

```
    public class Node<T extends Comparable<T>> {
    
        private T data;
        private Node<T> next;
    
        public Node(T data, Node<T> next) {
            this.data = data;
            this.next = next;
        }
    
        public T getData() { return data; }
        // ...
    }
```

Java编译器把有界限的类型参数`T`替换为第一个有界类型`Comparable`：

```
    public class Node {
    
        private Comparable data;
        private Node next;
    
        public Node(Comparable data, Node next) {
            this.data = data;
            this.next = next;
        }
    
        public Comparable getData() { return data; }
        // ...
    }
```

### 泛型方法的类型擦除

Java编译器也会擦除泛型方法实参中的类型参数：

```
    // Counts the number of occurrences of elem in anArray.
    //
    public static <T> int count(T[] anArray, T elem) {
        int cnt = 0;
        for (T e : anArray)
            if (e.equals(elem))
                ++cnt;
            return cnt;
    }
```

因为`T`没有界限限制，所以类型参数会被替换为`Object`：

```
    public static int count(Object[] anArray, Object elem) {
        int cnt = 0;
        for (Object e : anArray)
            if (e.equals(elem))
                ++cnt;
            return cnt;
    }
```

例如下面的三个类：

```
    class Shape { /* ... */ }
    class Circle extends Shape { /* ... */ }
    class Rectangle extends Shape { /* ... */ }
```

你可以写一个泛型方法来画出不同的图形：

```
    public static <T extends Shape> void draw(T shape) { /* ... */ }
```

Java编译器将`T`替换为Shape：

```
    public static void draw(Shape shape) { /* ... */ }

```

### 类型擦除和桥接方法的影响

有的时候类型擦除会引发预料不到的情况，在下面的[桥接方法](#bridge-methods)展示了编译器在某些时候会创建合成方法（*桥接方法*）。桥接方法是类型擦除处理过程的一部分。


```
    public class Node<T> {
    
        public T data;
    
        public Node(T data) { this.data = data; }
    
        public void setData(T data) {
            System.out.println("Node.setData");
            this.data = data;
        }
    }
    
    public class MyNode extends Node<Integer> {
        public MyNode(Integer data) { super(data); }
    
        public void setData(Integer data) {
            System.out.println("MyNode.setData");
            super.setData(data);
        }
    }
```

```
    MyNode mn = new MyNode(5);
    Node n = mn;            // A raw type - compiler throws an unchecked warning
    n.setData("Hello");     
    Integer x = mn.data;    // Causes a ClassCastException to be thrown.
```

类型擦除之后，上面的代码变为：


```
    MyNode mn = new MyNode(5);
    Node n = (MyNode)mn;         // A raw type - compiler throws an unchecked warning
    n.setData("Hello");
    Integer x = (String)mn.data; // Causes a ClassCastException to be thrown.
```

当代码运行时：
* `n.setData("Hello");` 实际上调用了MyNode对象的`setData(Object)`方法（`MyNode`继承了`Node`的`setData(Object)`方法）
* 引用`n`指向的对象的成员变量data被赋予`String`类型的值
* 引用`mn`指向的相同的对象的成员预期是Integer类型
* 试图将String类型的值赋给Integer类型，抛出`ClassCastException`异常

<a id="bridge-methods" href="#bridge-methods"></a>
### 桥接方法（Bridge Methods）

当一个类继承自有类型参数的类或实现有类型参数的接口时，编译器在编译它时一般需要生成桥接方法，作为类型擦除处理的一部分。一般你不需要担心桥接方法，但是如果它出现在堆栈跟踪中，会使人感到迷惑。
类型擦除过后，`Node`类和`MyNode`类如下所示：

```
    public class Node {
    
        public Object data;
    
        public Node(Object data) { this.data = data; }
    
        public void setData(Object data) {
            System.out.println("Node.setData");
            this.data = data;
        }
    }
    
    public class MyNode extends Node {
    
        public MyNode(Integer data) { super(data); }
    
        public void setData(Integer data) {
            System.out.println("MyNode.setData");
            super.setData(data);
        }
    }
```

可见类型擦除之后，方法签名不再匹配，`Node`中`setData(Object)`方法在`MyNode`中变成` setData(Integer)`，这样子类的方法不再覆盖父类的方法。
为了解决这个问题，并且能够在类型擦除之后，仍然保持多态性，Java编译器生成一个桥接方法来保证子类型工作正常。对于`MyNode`类，编译器生成下面的桥接方法：

```
    class MyNode extends Node {
    
        // Bridge method generated by the compiler
        //
        public void setData(Object data) {
            setData((Integer) data);
        }
    
        public void setData(Integer data) {
            System.out.println("MyNode.setData");
            super.setData(data);
        }
    
        // ...
    }
```

产生的桥接方法能够覆盖父类的`setData(Object data)`方法，并把真正的实现代理给了原有的`setData(Integer data)`方法。

## 非具体化类型（Non-Reifiable Types）

未完待续。。。

## 参考

[https://docs.oracle.com/javase/tutorial/java/generics/index.html](https://docs.oracle.com/javase/tutorial/java/generics/index.html)






