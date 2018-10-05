title: "关于回溯算法的几点心得"
date: 2018-09-26 23:23:54
categories:
tags: [backtracking,algorithm]
---
**摘要**：关于回溯算法的几点心得
**Abstract**: Some inspirations about backtracking algorithms.

## 回溯（Backtracking）算法思路：

在当前局面下，你有若干种选择。逐一尝试每一种选择。
如果发现某种选择行不通（违反了某些限定条件）就返回；
如果某种选择试到最后发现是正确解，就将其加入解集。

> 这里需要注意的是，为了能够回溯，多个选择都是从相同起点出发的，注意在同一层次下的多个选择结果之间不要相互影响。


使用递归解决问题需要明确以下三点：**选择 (Options)**、**限制 (Restraints)** 和 **结束条件 (Termination)**。即“ORT原则”。

<!-- more -->

## 例题

### 例1：[generate parentheses](https://leetcode.com/problems/generate-parentheses/)

Given n pairs of parentheses, write a function to generate all combinations of well-formed parentheses.

For example, given n = 3, a solution set is:

```
[
  "((()))",
  "(()())",
  "(())()",
  "()(())",
  "()()()"
]
```

思路：

* 选择：有两种选择：

加左括号。
加右括号。

* 限制：同时有以下限制：

如果左括号已经用完了，则不能再加左括号了。
如果已经出现的右括号和左括号一样多，则不能再加右括号了。因为那样的话新加入的右括号一定无法匹配。

* 结束条件： 左右括号都已经用完。

结束后的正确性： 左右括号用完以后，一定是正确解。因为
1. 左右括号一样多
2. 每个右括号都一定有与之配对的左括号。因此一旦结束就可以加入解集（有时也可能出现结束以后不一定是正确解的情况，这时要多一步判断）。

递归函数传入参数： 限制和结束条件中有“用完”和“一样多”字样，因此你需要知道左右括号的数目，还有参数记录解集。

因此，把上面的思路拼起来就是代码：

```
if (左右括号都已用完) {
  加入解集，返回
}
//否则开始试各种选择
if (还有左括号可以用) {
  加一个左括号，继续递归
}
if (右括号小于左括号) {
  加一个右括号，继续递归
}
```


Java代码如下：

```java
class Solution {
    public List<String> generateParenthesis(int n) {
        List<String> list = new ArrayList<>();
        gen(list, "", n, n);
        return list;
    }

    private void gen(List<String> list, String s, int leftCount, int rightCount) {
        if (leftCount == 0 && rightCount == 0) {
            list.add(s);
        }
        if (leftCount > 0) {
            gen(list, s + "(", leftCount - 1, rightCount);
        }
        if (rightCount > leftCount) {
            gen(list, s + ")", leftCount, rightCount - 1);
        }
    }
}
```


### 例2： [Letter Combinations of a Phone Number](https://leetcode.com/problems/letter-combinations-of-a-phone-number/description/)

Given a string containing digits from 2-9 inclusive, return all possible letter combinations that the number could represent.

A mapping of digit to letters (just like on the telephone buttons) is given below. Note that 1 does not map to any letters.

Input: "23"
Output: ["ad", "ae", "af", "bd", "be", "bf", "cd", "ce", "cf"].

思路：

* 选择：当前数字上的所有letters，每个letter都是一个选择
* 限制：只能使用当前数字键上的letters，每次只能选一个
* 结束条件： 数字串结束

```java
class Solution {
    
    private static final String[] MAPPER = {"0", "1", "abc", "def", "ghi", "jkl", "mno", "qprs", "tuv", "wxyz"};
    
    public List<String> letterCombinations(String digits) {
        List<String> list = new ArrayList<>();
        if (digits == null || digits.length() == 0) {
            return list;
        }
        combine(list, "", digits, 0);
        return list;
    }
    
    private void combine(List<String> list, String value, String digits, int n) {
        // 结束条件
        if (n >= digits.length()) {
            list.add(value);
            return;
        }
        // 选择
        String letters = MAPPER[digits.charAt(n) - '0'];
        for (int i = 0; i < letters.length(); i++) {
            // 限制
            combine(list, value + letters.charAt(i), digits, n+1);
        }
    }
}
```


### 例3： [Combination Sum](https://leetcode.com/problems/combination-sum/description/)

Given a set of candidate numbers (candidates) (without duplicates) and a target number (target), find all unique combinations in candidates where the candidate numbers sums to target.

The same repeated number may be chosen from candidates unlimited number of times.

Note:

All numbers (including target) will be positive integers.
The solution set must not contain duplicate combinations.
```text
Example 1:
Input: candidates = [2,3,6,7], target = 7,
A solution set is:
[
  [7],
  [2,2,3]
]
Example 2:

Input: candidates = [2,3,5], target = 8,
A solution set is:
[
  [2,2,2,2],
  [2,3,3],
  [3,5]
]
```

思路：

* 选择：所有candidates中的一个
* 限制： 当前任何情况下，list中元素的和需要小于target
* 结束条件： 当前list中的元素和等于target

需要注意： 

* 结果去重， 引入index解决
* list副本在回溯过程中不应该相互影响


```java
class Solution {
    public List<List<Integer>> combinationSum(int[] candidates, int target) {
        List<List<Integer>> results = new ArrayList<>();
        if (candidates == null || candidates.length == 0) {
            return results;
        }
        Arrays.sort(candidates);
        combinations(results, new ArrayList<>(), candidates, target, 0);
        return results;
    }

    private void combinations(List<List<Integer>> results, List<Integer> list, int[] candidates, int target, int index) {
        int s = sum(list);
        if (s == target) {
            results.add(copyOf(list));
            return;
        }
        if (s > target) {
            return;
        }

        for (int i = index; i < candidates.length; i++) {
            list.add(candidates[i]);
            combinations(results, list, candidates, target, i);
            list.remove(list.size() - 1);
        }
    }

    private int sum(List<Integer> list) {
        if (list == null) {
            return 0;
        }
        int sum = 0;
        for (Integer i : list) {
            sum += i;
        }
        return sum;
    }

    private List<Integer> copyOf(List<Integer> list) {
        return new ArrayList(list);
    }
}
```


## 参考：

* http://www.1point3acres.com/bbs/forum.php?mod=viewthread&tid=172641&page=1#pid2237150