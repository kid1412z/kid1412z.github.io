---
title: "1214 线段覆盖"
date: 2013-11-09 12:24:01
categories: 编程题解
tags: [DP,动态规划,wikioi]
---
...
<!-- more -->
## [题目描述 Description](http://www.wikioi.com/problem/1214/)
给定x轴上的N（0<N<100）条线段，每个线段由它的二个端点a_I和b_I确定，I=1,2,……N.这些坐标都是区间（－999，999）的整数。有些线段之间会相互交叠或覆盖。请你编写一个程序，从给出的线段中去掉尽量少的线段，使得剩下的线段两两之间没有内部公共点。所谓的内部公共点是指一个点同时属于两条线段且至少在其中一条线段的内部（即除去端点的部分）。
输入描述 Input Description
输入第一行是一个整数N。接下来有N行，每行有二个空格隔开的整数，表示一条线段的二个端点的坐标。
**输出描述 Output Description**
输出第一行是一个整数表示最多剩下的线段数。
**样例输入 Sample Input**
3
6 3
1 3
2 5
**样例输出 Sample Output**
2

## 动态规划思路:
最优子结构：到j为止最多的线段数
子问题重叠：用f[j]数组存放重叠计算的子问题
1. 对输入的数据，把左端点放在左边
2. 按左端点坐标从小到大排序
3. 用数组f[j]存放到线段j为止，最多留下的线段数目，初始都是1。
4. 按顺序扫描线段，如果线段j的左端点大于等于之前线段的右端点，到j最多线段数为f[i] + 1， 如果有多个这样的情况，就取f[i] + 1（i = 1....j-1）中最大的一个。

## 代码示例:

    
    int n;
    cin >> n;
    for(int i = 0; i < n; i++){
        cin >> lines[i].start;
        cin >> lines[i].end;
        f[i] = 1;
        if(lines[i].start > lines[i].end){
            swap(lines[i].start, lines[i].end);
        }
    }
    qsort(lines, n, sizeof(line),cmp);
    for(int j = 1; j < n; j++){//scan all
        for(int i = 0; i < j; i++){ 
            if(lines[i].end <= lines[j].start){//如果与前面的不重叠
                f[j] = max(f[j], f[i] + 1); // 取最多的线段数
            }
        }
    }
    int max = 0;
    for(int i = 0; i < n; i++){
        if(f[i] > max){
            max = f[i];
        }
    }
    cout << max << endl;





