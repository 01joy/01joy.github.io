---
date: '2016-08-18T11:00:43+08:00'
draft: false
title: '稳定版快速排序算法'
categories: ["0和1"]
tags: ["快速排序"]
---
我们知道常规的快速排序算法是一个不稳定的算法，也就是两个相等的数排序之后的顺序可能和在原序列中的顺序不同。这是因为当选定一个枢轴（pivot），要把其他数分到小于pivot和大于pivot的两边的时候，不同实现的分法不一样。

下面我实现了一种稳定版快速排序算法，在Partition函数中保持了原序列中所有元素的相对顺序，只把pivot放到了它的正确位置。具体方法是三遍扫描原序列：1）第一遍先把小于pivot的元素按先后顺序放到tmp里，然后把pivot放到它的正确位置tmp[k]；2）第二遍把大于pivot的元素按先后顺序追加在tmp里，这样除了pivot以前的其他元素，都保持了和原序列中一样的顺序；3）第三遍把tmp赋值回原数组A。

当排序算法稳定之后，就可以借此统计逆序数了，文件[Q5.txt](Q5.zip)中共包含100000个**不同**的整数，每行一个数。我们可以使用稳定版快速排序算法对其排序，并统计出其中的逆序数个数。

具体的Python 3实现如下：

```python
# -*- coding: utf-8 -*-
"""
Created on Tue Oct 6 00:21:37 2015
@author: bitjoy
"""
import time

inversions = 0

def Partition(A, p, r):
    global inversions
    tmp = [0] * (r-p+1)
    pivot = A[p]
    k = 0
    for i in range(p+1, r+1): # first
        if A[i] < pivot:
            tmp[k] = A[i]
            inversions = inversions + i – k – p
            k = k + 1
        tmp[k] = pivot
        ans = k + p
        k = k + 1
    for i in range(p+1, r+1): # second
        if A[i] > pivot:
            tmp[k] = A[i]
            k = k + 1
            k = 0
    for i in range(p, r+1): # third
        A[i] = tmp[k]
        k = k + 1
    return ans

def QuickSortAndCount(A, p, r):
    if p < r:
    q = Partition(A, p, r)
    QuickSortAndCount(A, p, q-1)
    QuickSortAndCount(A, q + 1, r)

if __name__ == "__main__":
    Q5 = open('Q5.txt', encoding = 'utf-8')
    data = [ int(x) for x in Q5 ]
    Q5.close()
    start = time.clock()
    QuickSortAndCount(data, 0, len(data) -1 )
    end = time.clock()
    print("number of inversions:%d\ntime:%f s"%(inversions,end-start))
```

虽然这种快排的时间复杂度还是O(nlgn)，但是在Partition函数中扫描了3次数组，并且借用了辅助数组tmp，不再是in-place排序算法，所以排序用时会比常规快排或者归并排序要慢。