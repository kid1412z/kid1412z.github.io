title: "Java ClassLoader"
date: 2016-02-05 21:53:45
categories: Java
tags: [Java,ClassLoader]
---
**摘要**：Java类加载器
**Abstract**: An overview of Java ClassLoaders
<!-- more -->
## 走进CLassLoader

每个类加载器（classloader）自身都是一个扩展自`java.lang.ClassLoader`类的实例。那么如果类加载器本身也有类型，并且每类都是由classloader加载的，那么加载的顺序是怎样的？我们需要了解classloader的机制和JVM类加载体系。首先看一下classloader的API：

```java
package java.lang;
public abstract class ClassLoader {
  public Class loadClass(String name);
  protected Class de neClass(byte[] b);
  public URL getResource(String name);
  public Enumeration getResources(String name);
  public ClassLoader getParent()
}
```

`loadClass`方法是`java.lang.ClassLoader`类中最重要的方法，接收类的全名，返回改类型的实例对象。
`defineClass`方法，参数为byte数组，一般是从磁盘或其他地方加载的Java字节码。
`getResource`和`getResources`返回资源的URL，它有类似于`loadClass`方法的**委托机制**，首先委托给父类加载，然后再在本地查找。`loadClass`方法等同于`defineClass(getResource(name).getBytes())`.
`getParent`方法返回父类加载器（parent classloader），在下一节中我们将详细描述。
由于Java的晚期绑定，类型加载延迟到最晚时刻进行。一个类只有在第一次调用其构造方法、static方法或static属性时，才会被加载。

```java
public class A {
  public void doSomething() {
    B b = new B();
    b.doSomethingElse();
  }
}
```

`B b = new B();`在语义上等同于`getClassLoader().loadClass("B").newInstance();`
在Java中，所有的对象都和他们的类关联，而所有的类都和该类的加载器关联。
当我们实例化一个`ClassLoader`，我们可以通过构造方法指定其父类加载器（`parent ClassLoader`），如果没有显式的指定，则JVM会指定一个默认的parent classloader。那么默认的parent classloader是什么呢？这取决于JVM的ClassLoader继承体系。

## JVM的类加载委托体系（classloader delegation hierarchy）

JVM在启动时，会首先加载**bootstrap classloader**，bootstrap classloader是所有类加载器的parent，负责加载重要的Java基础类（如java.lang package）和其他运行时类型。*bootstrap类加载器是JVM中，唯一一个没有parent的类加载器*。
接着是加载**extension classloader**。它的parent是bootstrap classloader，负责加载`java.ext.dirs`路径下的所有jar包。
第三步，也是最重要的一步，就是加载**system classpath classloader**,该classloader的直接父节点是extention classloader。它负责从`CLASSPATH`变量指定的路径、`java.class.path`系统变量或`-classpath`命令行参数指定的路径中加载类。

```text

  +---------------------+
  |bootstrap classloader|
  +---------------------+
            |
            v
  +---------------------+
  |extention classloader|
  +---------------------+
            |
            v
 +----------------------------+
 |system classpath classloader|
 +----------------------------+
```

> 值得注意的是，以上JVM的类加载体系并非一个继承体系，而是一个委托体系（delegation hierarchy）。

大部分的classloader在加载自己本地classpath种的资源和类之前，优先委托给他们的parent。如果parent classloader不能找到目标类或者资源，classloader才会尝试在本地的classpath中搜索并加载资源。也就是说，classloader只加载它的parent无法加载的类或资源。相反，被处于委托体系下层的classloader加载的class不能被委托体系上层的类访问。

> 最初建立这样的类加载委托体系的初衷是为了避免相同类型可能被加载数次。回到1995年，当时Java平台的主要应用是Web Applet。当时网络带宽的限制，决定了JVM需要延迟加载类型。但后来证明Java在服务端程序和JavaEE中表现优异，在服务端程序中，classloader理想的加载顺序是相反的——优先在本地查找并加载class，没有找到时，再向parant中去查找。

## JavaEE类型加载委托体系

下面是一个典型的web容器classloader体系：每个EAR（J2EE Enterprise Archive）module和WAR都有自己的类加载器。

```text

                   +-----------+
                   | container |
                   +-----------+
                         |
           +---------------+----------+
           |               |          |
      +--------+       +--------+ +--------+
      |App1.ear|       |App2.ear| |App3.ear|
      +--------+       +--------+ +--------+
          |                |          |
    +-----------+          |          |
    |           |          |          |
+-------+   +-------+  +-------+  +-------+
| WAR1  |   | WAR2  |  | WAR3  |  | WAR4  |
+-------+   +-------+  +-------+  +-------+
```

Java Servlet规范建议web模块的classloader优先加载类加载器本地的内容。之后当没有找到目标类时，才委托parent加载。

> 颠倒委托顺序的原因是：应用容器中的加载的众多类库都有自己的发布周期，不一定适用于开发者。典型的例子就是log4j类库，在container中使用的是一个版本，而在应用中使用的是另一个版本。

然而这带来了问题：

> JEVGENI KABANOV:The reversed behavior of web module classloader has caused more problems with classloaders than anything else... ever.

### JavaEE类加载错误

JavaEE的委托模型又是会出现以下几种有趣的错误。`NoClassDefFoundError`, `LinkageError`, `ClassNotFoundException`, `NoSuchMethodError`, `ClassCastException`.

#### NoClassDefFoundError

`NoClassDefFoundError` 是上述错误中最常见的一种，排错分析的复杂程度取决于你Web项目的复杂性和规模。Java文档中是这样描述的：

> NoClassDefFoundError is thrown if the Java Virtual Machine or a ClassLoader instance tries to load in the de nition of a class and no de nition of the class could be found.

也就是说，类型定义在编译期存在，而在运行时无法找到。这就是你不能完全依赖IDE的错误信息提示，许多运行时的错误IDE并帮不上忙。

> JEVGENI KABANOV: All classloading happens at runtime, which makes the IDE results irrelevant.


例如：

```java

public class NoClassDefFoundErrorServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        PrintWriter writer = resp.getWriter();
        writer.print(StringUtils.defaultString("hello"));
    }
}

```

`NoClassDefFoundErrorServlet` 调用`StringUtils`类的defaultString方法，打印一条信息。但是在运行时会发生如下错误：

```text

java.lang.NoClassDefFoundError: org/apache/commons/lang3/StringUtils
	com.zuoqy.classloader.NoClassDefFoundErrorServlet.doGet(NoClassDefFoundErrorServlet.java:20)
	javax.servlet.http.HttpServlet.service(HttpServlet.java:620)
	javax.servlet.http.HttpServlet.service(HttpServlet.java:727)
	org.apache.tomcat.websocket.server.WsFilter.doFilter(WsFilter.java:52)
```

如何排除这个错误？ 很显然你需要检查`StringUtils`这个类是否真的被引入到了package里。由于maven依赖的`commons-lang3`的scope是provided，因此在编译期间并不会出错。由于运行时tomcat的lib目录中没有对应的jar包，才会产生运行时错误。

这里有一个技巧，就是打印出classloader加载类的classpath：

```java

public class NoClassDefFoundErrorServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        PrintWriter writer = resp.getWriter();
        writer.print(Arrays.toString(((URLClassLoader) NoClassDefFoundErrorServlet.class.getClassLoader()).getURLs()));
        //writer.print(StringUtils.defaultString("hello"));
    }
}
```

你会看到类似下面的输出：

```text

[file:/opt/tomcat/deploy/ROOT/WEB-INF/classes/, file:/opt/tomcat/deploy/ROOT/]
```

但打印classpath的方法不是在所有情况下都可以，我们还可以使用`jconsole`命令连接到tomcat进程上查看classpath信息以及在运行时加载了哪些类。

#### NoSuchMethodError

产生`NoSuchMethodError`的原因一般是被引用的class存在，但是不是正确的版本。首先需要知道这个版本不正确的class是从哪加载的。可以通过设置JVM参数`‘-verbose:class`查看类的加载和卸载日志。确定所加载的class路径之后，可以使用`javap -private classfile`命令来查看此class文件中是否有目标方法。

如果是maven项目，还可以通过在项目根目录下运行 `mvn clean dependency:tree` 命令查看是否存在依赖冲突。然后把错误版本的jar包在依赖中排除掉即可。

未完待续...

## 参考

* [http://zeroturnaround.com/rebellabs/rebel-labs-tutorial-do-you-really-get-classloaders/](http://zeroturnaround.com/rebellabs/rebel-labs-tutorial-do-you-really-get-classloaders/)