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

## 概要

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

### 数据模型

* **表（Table）**：Hbase使用table组织数据，表名是字符串，由可以在文件系统路径里使用的字符构成。
* **行（Row)**: 在表里，数据按行存储，行由行键（Rowkey）作为唯一标识。行键没有数据类型，总是视为`byte[]`.
* **列族（column family）**：行里的数据按照列族分组，列族影响到Hbase数据的物理存放。他们必须事先定义好并且不轻易修改。
* **列限定符（column qualifier）**：列族里的数据通过列限定符或列来定位。列限定符不必实现定义，不必再不同行之间保持一致。列限定符都是`byte[]`。
* **单元（cell）**：行键、列族和列限定符一起确定一个单元。存储在单元中的数据成为*值（value）*。值都是`byte[]`.
* **时间版本**：单元值有时间版本，时间版本用long型时间戳标识。时间版本的数量基于列族配置，默认数量是3.

关系型数据库中的数据是*结构化数据*，Hbase中的数据是*半结构化数据*。Hbase是专门为半结构化数据和水平可扩展性设计的数据库。

### 数据坐标

Hbase依次使用：行键、列族、列限定符和时间版本作为数据的坐标。基于非键值查询Hbase的唯一办法就是带过滤器的扫描。


### 事务特性

Hbase不是ACID兼容数据库。

* 同一行上的`Put()`操作具有原子性。要么整体成功，要么整体失败。
* 行间的`Put()`操作不是原子性的。
* `Get()`操作返回当时所保存的完整行数据。
* `Scan()`操作不是扫描快照，在扫描过程中如果有行更新，则扫描到的结果包含更新后的完整的行

## Hbase表设计

### IO优化

#### 写优化

* 散列：通过散列行键（如取Md5或SHA1）来避免Region热点的问题。
* salting：通过在行键上加上前缀，将数据分散到各个Region。

但以上两种方案会使Scan性能下降(连续的记录被打散到多个Region中)。

#### 读优化

例：推贴按照倒序时间戳和用户id组成的复合行键可以scan出最近n条用户推贴。