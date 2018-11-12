title: "Kubernetes3 为什么需要Pod"
date: 2018-11-06 23:01:09
categories: Cloud Compute
tags: [kubernetes]
---

## 为什么需要Pod

1. 在工业实际部署中，经常需要多个进程部署在同一个节点上。类似于Linux操作系统中的进程组的概念（`pstree -g` 命令查看进程组），他们之间有着"超亲密关系"，例如相互之间会发生直接的文件交换、使用localhost或者Socket文件进行本地通信、共享某些Linux Namespace等。
2. 容器的"单进程模型"，PID=1的进程往往是应用本身，无法像正常操作系统中的init进程那样拥有进程管理的功能。
3. 存在"超亲密关系"的进程，需要按照严格的拓扑顺序启动。也就是需要对容器成组进行调度（gang scheduling）。
基于上述原因，Kubernetes提供了Pod这个逻辑概念，将需要在同一节点上，可能共享Namespace以及其他本地资源的容器进行成组调度。

## Pod的实现机制

Pod是逻辑概念，其实是一组共享了某些资源（Network Namespace）的容器组。在没有成组调度时，如要实现容器A和容器B共享网络和Volume，可以通过如下命令实现：
<!-- more -->
```bash
$ docker run --net=B --volumes-from=B --name=A image-A ...
```
但容器B就必须先于容器A启动，改变了容器A和容器B的对等关系。

因此，在Kubernetes项目中，Pod的是基于一个中间容器——**Infra容器**来实现的。

![1](http://zuoqy.com/images/2018-11-06/1.png)
`k8s.gcr.io/pause`这个镜像，是用汇编写的永远暂停的很小的镜像。用户容器通过加入Infra容器的Network Namespace实现资源的本地共享。

在Pod中，对于AB两个容器：
* 可以直接通过localhost进行网络通信
* 看到的网络设备跟Infra容器看到的完全一样，网络资源被Pod中的所有容器共享
* 一个Pod对应一个IP地址
* Pod的生命周期只和Infra容器有关，与AB容器无关。
* Volume只需要在Pod中挂载一次，Pod内的所有容器即可共享。


## [容器设计模式](https://www.usenix.org/conference/hotcloud16/workshop-program/presentation/burns)

Kubernetes 希望当用户想在同一个容器中跑多个不相关的应用时，优先考虑使用Pod模式，看它们是否可以被描述为一个Pod中的多个容器。

典型的例子：

1. war包和Web服务器

在这种模型下，我们可以将war包和web服务器分别制作成两个容器镜像（包含war包的镜像可以做的非常小和简单，方便应用更新和部署），并且共享同一个Volume，包含war包的容器先于web服务器容器启动。

例如：

```text
apiVersion: v1
kind: Pod
metadata:
  name: javaweb-2
spec:
  initContainers:
  - image: app:v2
    name: war
    command: ["cp", "/app.war", "/app"]
    volumeMounts:
    - mountPath: /app
      name: app-volume
  containers:
  - image: tomcat:7.0
    name: tomcat
    command: ["sh","-c","/root/apache-tomcat-7.0.42-v2/bin/start.sh"]
    volumeMounts:
    - mountPath: /root/apache-tomcat-7.0/webapps
      name: app-volume
    ports:
    - containerPort: 8080
      hostPort: 8001 
  volumes:
  - name: app-volume
    emptyDir: {}
```

所有`spec.initContainers`定义的容器，都会比`spec.containers` 定义的用户容器先启动。并且，`spec.initContainers` 容器会按顺序逐一启动，而直到它们都启动并且退出了，用户容器才会启动。

2. 日志收集

应用进程容器不断的输出日志到特定的Volume路径，日志收集进程容器共享日志Volume进行收集。

其实，上述Pod组合模式，就是容器设计模式中的**Sidecar模式**，更多细节，可参见之前的文章：[Pattern-Service-Mesh](http://zuoqy.com/2018/10/07/Pattern-Service-Mesh/)