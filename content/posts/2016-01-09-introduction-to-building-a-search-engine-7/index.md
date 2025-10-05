---
date: '2016-01-09T23:52:13+08:00'
draft: false
title: '和我一起构建搜索引擎（七）总结展望'
categories: ["0和1","和我一起构建搜索引擎"]
tags: ["搜索引擎"]
---
至此，整个新闻搜索引擎构建完毕，总体效果令人满意，不过还是有很多可以改进的地方。下面总结一下本系统的优点和不足。

**优点**

倒排索引存储方式。因为不同词项的倒排记录表长度一般不同，所以没办法以常规的方式存入关系型数据库。通过将一个词项的倒排记录表序列化成一个字符串再存入数据库，读取的时候通过反序列化获得相关数据，整个结构类似于邻接表的形式。

推荐阅读实现方式。利用特征提取的方法，用25个关键词表示一篇新闻，大大减小了文档词项矩阵规模，提高计算效率的同时不影响推荐新闻相关性。

借用了Reddit的热度公式，融合了时间因素。

**不足**

构建索引时，为了降低索引规模，提高算法速度，我们将纯数字词项过滤了，同时忽略了词项大小写。虽然索引规模下降了，但是牺牲了搜索引擎的正确率。

构建索引时，采用了jieba的精确分词模式，比如句子“我来到北京清华大学”的分词结果为“我/ 来到/ 北京/ 清华大学”，“清华大学”作为一个整体被当作一个词项，如果搜索关键词是“清华”，则该句子不能匹配，但显然这个句子和“清华”相关。所以后续可以采用结巴的搜索引擎分词模式，虽然索引规模增加了，但能提升搜索引擎的召回率。

在推荐阅读模块，虽然进行了维度约减，但是当数据量较大时（数十万条新闻），得到的文档词项矩阵也是巨大的，会远远超过现有PC的内存大小。所以可以先对新闻进行粗略的聚类，再在类内计算两两cosine相似度，得到值得推荐的新闻。

在热度公式中，虽然借用了Reddit的公式，大的方向是正确的，但是引入了参数\(k_1\)和\(k_2\)，而且将其简单的设置为1。如果能够由专家给出或者经过机器学习训练得到，则热度公式的效果会更好。

---

完整可运行的新闻搜索引擎Demo请看我的Github项目[news_search_engine](https://github.com/01joy/news_search_engine)。

以下是系列博客：

[和我一起构建搜索引擎（一）简介](https://bitjoy.net/posts/2016-01-04-introduction-to-building-a-search-engine-1/)

[和我一起构建搜索引擎（二）网络爬虫](https://bitjoy.net/posts/2016-01-04-introduction-to-building-a-search-engine-2/)

[和我一起构建搜索引擎（三）构建索引](https://bitjoy.net/posts/2016-01-07-introduction-to-building-a-search-engine-3/)

[和我一起构建搜索引擎（四）检索模型](https://bitjoy.net/posts/2016-01-07-introduction-to-building-a-search-engine-4/)

[和我一起构建搜索引擎（五）推荐阅读](https://bitjoy.net/posts/2016-01-09-introduction-to-building-a-search-engine-5/)

[和我一起构建搜索引擎（六）系统展示](https://bitjoy.net/posts/2016-01-09-introduction-to-building-a-search-engine-6/)

[和我一起构建搜索引擎（七）总结展望](https://bitjoy.net/posts/2016-01-09-introduction-to-building-a-search-engine-7/)