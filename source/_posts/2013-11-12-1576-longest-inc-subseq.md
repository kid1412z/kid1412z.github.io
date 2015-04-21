---
title: "1576 最长严格上升子序列"
date: 2013-11-12 12:40:39
categories: "coding gym"
tags: [DP,动态规划,wikioi]
---

## [题目描述 Description](http://www.wikioi.com/problem/1576/)

非常经典的问题，拿来给大家练手了。
序列 { 1,2,...,n } 的一个子序列是指序列 { i1, i2, ……, ik },其中 1<=i1 < i2 < …… < ik<=n, 序列 { a1, a2, ……, an } 的一个子序列是指序列 { ai1, ai2, ……, aik },其中 { i1, i2, ……, ik } 是 { 1, 2, ……, n } 的一个子序列.同时,称 k 为此子序列的长度.
如果 { ai1, ai2, ……, aik } 满足 ai1 ≤ ai2 ≤ …… ≤ aik,则称之为上升子序列.如果不等号都是严格成立的,则称之为严格上升子序列.同理,如果前面不等关系全部取相反方向,则称之为下降子序列和严格下降子序列.
长度最长的上升子序列称为最长上升子序列.本问题对于给定的整数序列,请求出其最长严格上升子序列的长度

<!-- more -->

**输入描述 Input Description**
第一行，一个整数N。
第二行 ，N个整数（N < = 5000）
**输出描述 Output Description**
输出K的极大值，即最长严格上升子序列的长度
样例输入 Sample Input
5
9 3 6 2 7
样例输出 Sample Output
3
数据范围及提示 Data Size & Hint
【样例解释】
最长严格上升子序列为3,6,7

## 思路
1. 子问题描述：用dp[i] 表示到i位置为止，最长严格上升子序列的长度,a[i] 为数组中的元素
2. 状态转换： 对于0<=j < i 先求出符合a[j] < a[i] 的最大子序列长度，a[i] = max(a[j]) + 1;
因此： dp[i] = max(dp[j]+1. dp[i]) 0<=j < i && a[j] < a[i]

## 代码示例
    
    int lis(int *a, int n)
    {
        int res = 1;
        int dp[5009]={1};
        for (int i = 1; i < n; i++) {
        	dp[i] = 1;
            for (int j = 0; j < i; j++) {
                if (a[j] < a[i]) {
                    dp[i] = max(dp[i], dp[j] + 1);
                }
            }
            if(dp[i] > res){
            	res = dp[i];
            }
        }
        return res;
    }



