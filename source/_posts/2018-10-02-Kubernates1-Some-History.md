title: "Kubernetes学习笔记01: 一点历史"
tags: [kubernetes]
date: 2018-10-02 22:02:34
categories: Cloud Compute
---

## 1

2013年，作为云计算PaaS热潮中的一份子，dotCloud相比于OpenStack、 Cloud Foundry、Heroku、Pivotal、RedHat似乎有些微不足道。

Cloud Foundry的开源PaaS项目，代表了当时PaaS技术的事实标准，被广泛接纳。它提供了一种"应用托管"能力，通过提供简单的命令，使开发者可以方便的将应用"上云", 例如：`cf push "my_app"`其核心是应用的打包和分发。Cloud Foundry为每种主流语言都定义了一种打包格式， `cf push`的作用，就是将应用包、启动脚本上传到云端，通过调度器选择一批应用的虚拟机，
将脚本和应用包分发到机器上并启动执行。一个虚拟机上，往往启动多个来自不同用户的应用，PaaS平台会调用操作系统的Cgroups和Namespace机制，为每个应用单独创建隔离环境。
实现多个租户之间互不干涉的在虚拟机中部署和执行应用。整个过程就是PaaS项目最核心的能力。所谓的隔离环境，就是现在的容器技术。

在dotCloud公司开源自己的Docker项目之前，容器技术作为PaaS底层机制，并没有太多人关注。可就在开源后的短短几个月时间，Docker项目就迅速崛起，席卷了整个PaaS社区，改变了整个云计算领域的发展历程。

Docker项目区别于传统PaaS项目的秘密武器就是Docker镜像。如前面所述，当时PaaS项目的痛点就是用用的打包分发，用户需要为每一种语言、每一个应用维护一个打好的包，很难保持本地环境和云端环境的一致性。

Docker镜像的出现，从根本上解决了应用打包分发的问题：相比PaaS应用的压缩包只包含启动脚本加应用执行文件，Docker镜像则直接包含一个完整的操作系统所有文件和目录和应用启动的所有文件和脚本。轻松的保持了本地和云端环境的高度一致。
使用`docker build`、 `docker push` 和 `docker run` 即可将应用本地环境完整一致的打包推送到云端运行。

另外，Docker项目还对开发者有者天然的亲和力，开发者无需精通Linux内核原理和太多其他知识，就可以打包定制自己的镜像。简单的几个命令，就可以构建一个网站镜像，一个Nginx集群。深受开发者的欢迎。

Docker项目，重新定义了PaaS，使其演变为以Docker容器为核心，以Docker镜像为打包标准的"容器化"的PaaS。

## 2

随着Docker项目的崛起，dotCloud公司也将自己的公司名字改为Docker，并且不甘于仅仅提供创建和启停容器的小工具，希望提供更多平台层的能力，向PaaS进化。

2014年底，Docker公司发布Swarm，展示了Docker公司PaaS方向的野心。Swarm项目的最大亮点，就是它基本保持了单机部署和集群部署API的一致性，操作方式简单明了，受到众多开发者的热捧。（当时在公司的容器控制项目依赖Swarm也是基于这个原因）。

随后，Docker公司收购了率先提出"容器编排"(Container Orchestration)概念的[Fig项目](http://www.fig.sh/)(后来改名为Compose)。一时间，容器生态相关的项目层出不穷：容器网络处理SocketPlane项目（后被Docker公司收购），容器存储Flocker项目（后被EMC公司收购）， 集群图形化管理Tutum项目(被Docker公司收购)等。

2014年6月，Google开源名为Kubernetes的项目，再一次改变了容器市场的格局。

## 3

为了限制Docker公司在Docker开源项目中的绝对话语权和强势态度，以及Docker项目在告诉迭代中表现出的不稳定和频繁变更问题，2015年6月，Docker公司、CoreOS、Google、RedHat共同宣布将Libcontainer（Containerd）项目捐出，改名为RunC，交由完全中立的基金会管理，并以其为依据，共同制定标准和规范，即OCI（Open Container Initiative）. 

然而OCI的成立，并没有改变Docker公司一家独大的现状。随后，Google、RedHat牵头发起名为CNCF（Cloud Native Computing Foundation)的基金会。希望以Kubernetes项目为基础，建立开源基础设施领域厂商主导的、按照独立基金会方式运营的平台级社区。

在容器编排方面，RedHat与Google结盟，打造出了一个与众不同的容器编排和管理生态。并在整个社区推进民主化架构。与Docker社区和Mesos社区形成三足鼎立局面。

2017年10月，DOcker公司在企业版Docker中内置Kubernetes，标志编排之争落下帷幕。

次年3月，Docker公司CTO Solomon Hykes宣布辞职，5年容器纷争尘埃落定。


