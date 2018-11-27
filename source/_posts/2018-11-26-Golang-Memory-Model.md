title: "Go语言内存模型"
date: 2018-11-26 23:11:58
categories: golang
tags: [golang, memory model]
---

## Introduction

Go内存模型指定了一系列条件，在该条件下，可以保证在一个goroutine中对某个变量的读取操作可以观察（observe）到其他goroutine对这个变量写入的值。（内存可见性）

## Happens-before

指令重排序对goroutine内部的读写顺序可能有影响，但不会影响代码定义的当前goroutine整体的行为。
例如在goroutine1中有代码`a = 1; b = 2;`，在其他goroutine中可能观察到b先于a赋值，但对于goroutine1，其行为不会因为指令重排序发生变化。

Go语言中的Happens-Before：Happens-Before定义了内存操作的顺序。如果e1 happens-before e2, 则 e2 一定在e2发生之后才发生。如果e1 e2 没有happens-before的关系限制，则e1 e2是并发发生的。在单个goroutine内部， happens-before 次序就是程序定义的顺序。

读取操作r对变量v 可以观察到写入操作w对变量v的写入，必须同时满足如下两个条件：
1. r不能先于w发生
2. 没有其他的对变量v的写入操作w‘ 晚于 w 但 先于r发生

读取操作保证能观察到写入操作w对变量v的写入，必须同时满足如下两个条件：
1. w 先于 r发生
2. 任何其他对变量v的写入操作，要么先于w发生，要么晚于r发生。

<!-- more -->

初始化变量v为其对应类型的零值，在此内存模型视为写入操作。读取或者写入长于一个机器字长的值，会被分为多个机器字长、执行顺序不固定的读取或者写入操作.

常见的Happens-before：

* The go statement that starts a new goroutine **happens before** the goroutine's execution begins.
例如：

```
var a string

func f() {
	print(a)
}

func hello() {
	a = "hello, world"
	go f() // 在未来的某个时刻执行f() 可能是在hello() 返回之后
}
```

* A send on a channel **happens before** the corresponding receive from that channel completes.
       向channel中写入数据先于从对应channel中接收数据
* The closing of a channel **happens before** a receive that returns a zero value because the channel is closed.
      关闭channel先于从对应channel中接收数据
下面的程序保证能打印a的值
```go
var c = make(chan int, 10)
var a string

func f() {
	a = "hello, world"
	c <- 0 // or close(c)
}

func main() {
	go f()
	<-c
	print(a)
}
```

* A receive from an unbuffered channel **happens before** the send on that channel completes.
从非缓冲channel中接收数据先于向channel发送数据发生
违背直觉，但下面的程序会保证输出hello world
```go
var c = make(chan int)
var a string

func f() {
	a = "hello, world"
	<-c
}
func main() {
	go f()
	c <- 0
	print(a)
}
```

* The kth receive on a channel with capacity C **happens before** the k+Cth send from that channel completes.

下面这个程序定义了信号量为3，因此同时最多只有3个worker在工作

```
var limit = make(chan int, 3)

func main() {
	for _, w := range work {
		go func(w func()) {
			limit <- 1
			w()
			<-limit
		}(w)
	}
	select{}
}
```
* For any `sync.Mutex` or `sync.RWMutex` variable `l` and `n < m`, call n of `l.Unlock()` happens before call m of `l.Lock()` returns.
下面的程序中，f()函数中的unlock（1）先于Lock（2）执行
```go
var l sync.Mutex
var a string

func f() {
	a = "hello, world"
	l.Unlock() //1 
}

func main() {
	l.Lock()
	go f()
	l.Lock()  // 2
	print(a)
}
```
* For any call to `l.RLock` on a `sync.RWMutex` variable `l`, there is an n such that the `l.RLock` **happens (returns) after** call n to `l.Unlock` and the matching `l.RUnlock` **happens before** call n+1 to `l.Lock`.

* A single call of f() from once.Do(f) happens (returns) before any call of once.Do(f) returns.
`f()`函数先于`once.Do()`返回
下面的程序只会执行setup函数一次
```
var a string
var once sync.Once

func setup() {
	a = "hello, world"
}

func doprint() {
	once.Do(setup)
	print(a)
}

func twoprint() {
	go doprint()
	go doprint()
}
```

## Reference

* https://golang.org/ref/mem
