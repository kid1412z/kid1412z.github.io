title: "二阶段提交协议"
date: 2016-03-27 11:55:25
categories:
tags: [2PC,二阶段提交,2 Phase Commit,一致性协议]
---
**摘要**：简要介绍二阶段提交协议的思想
**Abstract**:Main ideas of 2 phase commit.
<!-- more -->

## 两阶段提交协议（Two Phase Commit Protocol）

两阶段提交协议是分布式事务处理使用的一种一致性协议。它用来协调分布式事务中的每个参与者，应对系统分布式系统执行事务过程中的短暂系统异常（如：节点失败、网络通信异常等）。

## 前提

* 系统有存在一个协调者（coordinator）节点，其他节点为参与者（cohorts）
* 系统中有稳定的存储，用来记录事务日志（预写日志WAL，Write-ahead logging），预写日志不会因为节点宕机而丢失。
* 系统中，任意两个节点之间都可以相互通信。（相比前两条，可放宽一些）

## 算法描述

### 第一阶段：请求提交阶段Commit Request Phase（投票阶段 voting phase）

* 协调者向所有参与值发起事务提交请求，等待所有参与者的投票响应。
* 所有参与者执行协调者发起的事务，记录Undo和Redo log。
* 所有参与者投票给协调者（事务可以执行成功，回复*Yes*，否则回复*No*）。任何一个参数者没有回复yes都会导致事务回滚。

### 第二阶段：事务提交阶段（Commit Phase）

#### 执行成功：

* 协调者向所有参与者发送commit命令
* 所有参与者完成事务提交，并释放事务处理期间所占用的锁和资源
* 参与者发送ACK给协调者
* 当协调者收到所有参与者的ACK之后，事务执行成功

#### 执行失败：

* 任何一个参与者投票No或者超时，都导致事务回滚
* 每个参与者根据WAL日志回滚
* 每个参与者发送ACK给协调者
* 协调者收到所有ACK后，事务回滚完成

时序图：

```text
Coordinator                                         Cohort
                              QUERY TO COMMIT
                -------------------------------->
                              VOTE YES/NO           prepare*/abort*
                <-------------------------------
commit*/abort*                COMMIT/ROLLBACK
                -------------------------------->
                              ACKNOWLEDGMENT        commit*/abort*
                <--------------------------------  
end
```

`*`表示改操作需要依赖稳定的存储

## 算法缺陷

* 同步阻塞：两阶段提交最大的缺点，等待其他参与者响应的过程中是阻塞的，无法进行其他操作。如果在阶段二协调者失败，则参与者永远处于阻塞状态，直到收到commit命令或者abort命令。
* 单点问题：协调者存在单点问题
* 太过保守：任何参与者错误或者超时，都会导致整个分布式事务失败。


## 参考

* [https://en.wikipedia.org/wiki/Two-phase_commit_protocol](https://en.wikipedia.org/wiki/Two-phase_commit_protocol)
* [从paxos到zookeeper——分布式一致性原理与实践](http://www.amazon.cn/%E5%9B%BE%E4%B9%A6/dp/B00RECRKPK)