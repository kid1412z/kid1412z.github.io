title: "《Hbase in Action》读书笔记"
date: 2015-11-04 20:38:18
categories:
tags: [Hbase]
---
**摘要**：*Hbase in Action* 读书笔记。

**Abstract**: *HBase in Action* notes.
<!-- more -->

## 使用场景和成功案例

### 抓取增量数据

* 抓取监控指标 OpenTSDB：采集机器监控指标和日志信息，并支持按照时间序列进行查询
* 抓取用户交互数据：Facebook 和 StumbleUpon
* 遥测技术：Mozillahe Trend Micro: 收集软件崩溃报告
* 广告效果和点击流：

### 内容服务

* URL短连接：存储短连接和原始连接之间的映射关系
* runa.com用户模型服务：实时报价。

### 信息交换

* Facebook的短信交换系统

## 入门

### 五个基本命令

* Get
* Put
* Delete
* Scan
* Increment

### 数据存储

#### 无模式

Hbase是无模式的，不需要事先定义Schema，不需要提前指定列和数据类型，只需要在写数据时给出列的名字。

### 工作机制

#### 写机制
* **持久化保证**写入时会写到两个地方：预写式日志（WAL）和MemStore，只有这两个地方写完成才算写成功。
* **写速度**：Memstore是内存缓冲区，缓冲区满才刷磁盘（HFile）。HFile是磁盘文件，对应列族。**列族和HFile之间是一对多的关系。一个列族可以有多个HFile，但一个HFile只对应一个列族**。
* **崩溃恢复**：在写动作完成之前先写WAL，HBase集群中的每台服务器维护一个WAL，服务器宕机情况下，可以通过回放WAL的方式来恢复。跳过WAL可以提高写性能，但可能会产生数据丢失。

```
Put p = new Put();
//禁用预写日志
p.setWriteToWAL(false);
```

#### 读机制

* **毫秒级读**：Hbase在读操作上使用了LRU缓存BlockCache（与MemStore在同一个JVM堆里），每个列族都有自己的BlockCache。
* **Block设置**：Block是简历索引和从磁盘读的最小单位，默认是64KB。根据查询方式是Scan居多还是KV查询居多可以调整Block大小。scan居多时，调大block可以增大读取速度。并减少索引所占空间。

#### 删除机制
* **合并**：Delete命令之后，并不是立即删除内容，而是针对被删除内容写入一条新的墓碑记录（tombstone）来标记删除。墓碑记录不能在scan和get时返回结果。直到执行一次大合并（major compaction）这些墓碑记录占用的空间才被释放。
* **小合并**：合并分为大合并和小合并，小合并把多个HFile合并成一个大HFile。然后把新Hfile标记为激活状态，合并前的旧HFile被删除。
* **大合并**：处理给定region一个列族的所有HFile。大合并消耗资源，不会频繁发生，但是清理被删除记录的唯一机会。

#### 时间版本
Hbase中的数据有时间版本的概念，Hbase中的时间版本是long类型的，以毫秒为单位的当前时间。

```
List<KeyValue> kv = r.getColumn(Bytes.toBytes("family"),Bytes.toBytes("col1"));
kv.get(0).getValue();
kv.get(1).getValue();
```