title: "Kubernates2 基本概念"
date: 2018-10-29 22:39:15
categories: Cloud Compute
tags: [kubernates]
---
## 要解决什么问题

可以方便的将用户应用的镜像部署到集群，并提供路由网关、水平扩展、监控、备份灾难恢复等一系列运维能力。这些问题，其实一个PAAS平台都可以解决。

除了解决以上问题，Kubernates项目区别于其他PAAS平台，重点要解决的问题，来自于Borg项目的研究人员在论文中的一个重要观点：

> 运行在大规模集群中的各个任务之间，存在着各种各样的关系。这些关系的处理，才是作业编排和管理系统最困难的地方。

## 需要什么样的架构

* 节点分为控制节点Master和计算节点Node
* Master节点包含kube-controller, kube-api-server 和 kube-scheduler三个组件
* Node节点中的核心组件kubelet：
    - 通过CNI(Container Networking Interface)与网络插件交互，配置容器网络；
    - 通过CSI(Container Storage Interface)与存储插件交互，配置持久化存储；
    - 通过CRI（Container Runtime Interface）与容器运行时交互，定义容器运行时的各项操作。
    - 容器运行时通过OCI容器运行时规范，与Linux操作系统交互。
<!-- more -->

![1](http://zuoqy.com/images/2018-10-29/1.png)

其控制节点的架构理论，参考Google内部系统Borg

![2](http://zuoqy.com/images/2018-10-29/2.png)

Kubernates项目的设计思想，就是从更宏观的角度，以统一的方式来定义任务之间的各种关系，并未将来支持更多类型的关系留有余地。

如果应用内部各个子服务之间的依赖关系不复杂，则用Swarm+Compose的方式完全可以解决。在Compose文件中，经常会出现类似这样的编排配置：

```bash
    DB_NAME=/web/db
    DB_PORT=tcp://172.17.0.5:5432
    DB_PORT_5432_TCP=tcp://172.17.0.5:5432
    DB_PORT_5432_TCP_PROTO=tcp
    DB_PORT_5432_TCP_PORT=5432
    DB_PORT_5432_TCP_ADDR=172.17.0.5
```

对应子系统之间依赖负责的应用，例如：有的子服务需要部署在同一台机器上（例如需要本地进程间通信，如[Service Mesh](http://zuoqy.com/2018/10/07/Pattern-Service-Mesh/)），有的需要安排在不同的机器上(如web服务和DB)。

此时，Kubernates的设计理念就派上了用场。Kubernates以Pod为核心，抽象出了处理容器间关系的各种上层对象，如下图所示：

![3](http://zuoqy.com/images/2018-10-29/3.png)

例如，容器间需要紧密协作，则需要Pod；容器间需要访问授权，则由Secret对象来完成等等。

## 参考

* http://malteschwarzkopf.de/research/assets/google-stack.pdf