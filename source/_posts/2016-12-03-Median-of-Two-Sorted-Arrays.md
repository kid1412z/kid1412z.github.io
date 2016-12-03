title: "Median of Two Sorted Arrays"
date: 2016-12-03 18:48:58
categories: Algorithm
tags: [Algorithm]
---
**摘要**：两个有序数组的中位数
**Abstract**: Median of Two Sorted Arrays
最近遇到一个有意思的题，求两个有序数组的中位数，亲自做了一下发现坑很多，除了二分查找的思想运用的很巧妙，还有各种边界条件把我搞得很崩溃。于是记录下来。
<!-- more -->
首先，题目是这样的：
有两个有序数组，长度分别是m和n，找到两个数组的中位数，要求时间复杂度是` O(log (m+n))`

```
Example 1:
nums1 = [1, 3]
nums2 = [2]
The median is 2.0

Example 2:
nums1 = [1, 2]
nums2 = [3, 4]
The median is (2 + 3)/2 = 2.5
```
`O(m+n)`的解法就是一趟归并排序然后再取中位数，比较简单。`O(log(m+n))`的解法需要用到二分的思想。
假设`i`,`j`将数组`A`，`B`分为左右两部分：

```text
left_part                |        right_part
A[0], A[1], ..., A[i-1]  |  A[i], A[i+1], ..., A[m-1]
B[0], B[1], ..., B[j-1]  |  B[j], B[j+1], ..., B[n-1]
```
如果保持左右两部分数量相同，则`i`和`j`：的关系如下：

```text
i + j = (m - i) + (n - j)
==> i + j = (m + n) / 2
==> j = (m + n) / 2 - i
```

即：我们只需要找到`i`,`j`满足：`i + j = (m - i) + (n - j)`且`max(left_part) <= min(right_part)`即可通过：`A[i-1]、A[i]、B[j-1]、B[j]`计算出中位数：

```text
median = (max(left_part) + min(right_part))/2
```

```text
在A数组中二分查找，当前元素index = i：
1）当A[i - 1] > B[j]，说明i过大，要找的i在A[0...i-1]中；
2）当B[j - 1] > A[i]，说明i过小，要找的i在A[i+1...m]中；
循环1）2）直到找到符合条件的i和j
```
以上就是这个算法的主要思想，当然有这些还不够，还需要注意`i = 0`、`i = m`、`j = 0`、`j = n`和空数组`[]`等边界情况。

具体代码如下：

```java
public class Solution {
    public double findMedianSortedArrays(int[] A, int[] B) {
        int m = A.length;
        int n = B.length;
        int left = 0;
        int right = m;
        int i = 0, j = 0;
        if (m > n) {
            return findMedianSortedArrays(B, A);
        }
        if (m == 0) {
            return (B[n/2] + B[(n - 1) / 2])/2.0;
        }
        while (left <= right) {
            i = (left + right) / 2;
            j = (m + n) / 2 - i;
            if (i > 0 && j < n && A[i - 1] > B[j]) { // i > 0 ==> j < n
                right = i - 1;
            } else if (j > 0 && i < m && B[j - 1] > A[i]) { // j > 0 ==> i < m
                left = i + 1;
            } else {
                break;
            }
        }
        int leftMax, rightMin;
        if (i == 0) {
            leftMax = B[j-1];
        } else if (j == 0) {
            leftMax = A[i - 1];
        } else {
            leftMax = Math.max(A[i-1], B[j-1]);
        }
        if (i == m) {
            rightMin = B[j];
        } else if (j == n) {
            rightMin = A[i];
        } else {
            rightMin = Math.min(A[i], B[j]);
        }
        if ((m + n) % 2 == 1) {
            return rightMin;
        }
        return (leftMax + rightMin) / 2.0;
    }
}
```





