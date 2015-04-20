---
title: "3027 线段覆盖 2"
date: 2013-11-11 11:55:17
categories: 编程题解
tags: [DP,动态规划,Algorithm]
---
## [题目描述 Description](http://www.wikioi.com/problem/3027/)
数轴上有n条线段，线段的两端都是整数坐标，坐标范围在0~1000000，每条线段有一个价值，请从n条线段中挑出若干条线段，使得这些线段两两不覆盖（端点可以重合）且线段价值之和最大。
n<=1000

<!-- more -->

输入描述 Input Description
第一行一个整数n，表示有多少条线段。
接下来n行每行三个整数, ai bi ci，分别代表第i条线段的左端点ai，右端点bi（保证左端点<右端点）和价值ci。
输出描述 Output Description
输出能够获得的最大价值
样例输入 Sample Input
3
1 2 1
2 3 2
1 3 4
样例输出 Sample Output
4
数据范围及提示 Data Size & Hint
数据范围
对于40%的数据，n≤10；
对于100%的数据，n≤1000；
0<=ai,bi<=1000000
0<=ci<=1000000

## 思路：
对线段按照左端点进行排序
子问题描述：用v[i] 表示到第i个线段为止的最大价值
状态迁移方程： v[i] = max(v[j]) + a[i].value (0<= j < i && a[j].end <= a[i].start)

## 代码示例：

    
    int cmp(const line lhs, const line rhs)
    {
        return lhs.start < rhs.start;
    }
    
    int cover(line *a, int n)
    {
        sort(a, a + n, cmp);
        int pmax = 0;
        v[0] = a[0].value;
        for (int i = 1; i < n; i++) {
            v[i] = a[i].value;
            int max = 0;
            for (int j = 0; j < i; j++) {
                if (a[j].end <= a[i].start && max < v[j]) {
                    max = v[j];
                }
            }
            v[i] += max;
            if (pmax < v[i]) {
                pmax = v[i];
            }
        }
        return pmax;
    }



