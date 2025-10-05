---
date: '2016-01-09T22:34:56+08:00'
draft: false
title: '和我一起构建搜索引擎（五）推荐阅读'
categories: ["0和1","和我一起构建搜索引擎"]
tags: ["jieba","sklearn","TFIDF","推荐系统"]
---
虽然主要的检索功能实现了，但是我们还需要一个“推荐阅读”的功能。当用户浏览某条具体新闻时，我们在页面底端给出5条和该新闻相关的新闻，也就是一个最简单的推荐系统。

![搜狐新闻“相关新闻”模块](sohu-news3.webp)
搜狐新闻“相关新闻”模块

推荐模块的思路是度量两两新闻之间的相似度，取相似度最高的前5篇新闻作为推荐阅读的新闻。

我们前面讲过，一篇文档可以用一个向量表示，向量中的每个值是不同词项t在该文档d中的词频tf。但是一篇较短的文档（如新闻）的关键词并不多，所以我们可以提取每篇新闻的关键词，用这些关键词的tfidf值构成文档的向量表示，这样能够大大减少相似度计算量，同时保持较好的推荐效果。

[jieba分词组件自带关键词提取功能](https://github.com/fxsjy/jieba#3-%E5%85%B3%E9%94%AE%E8%AF%8D%E6%8F%90%E5%8F%96)，并能返回关键词的tfidf值。所以对每篇新闻，我们先提取tfidf得分最高的前25个关键词，用这25个关键词的tfidf值作为文档的向量表示。由此能够得到一个1000*m的文档词项矩阵M，矩阵每行表示一个文档，每列表示一个词项，m为1000个文档的所有互异的关键词（大概10000个）。矩阵M当然也是稀疏矩阵。

得到文档词项矩阵M之后，我们利用[sklearn的pairwise_distances函数](http://sklearn.metrics.pairwise.pairwise_distances/)计算M中行向量之间的cosine相似度，对每个文档，得到与其最相似的前5篇新闻id，并把结果写入数据库。

推荐阅读模块的代码如下：

```python
# -*- coding: utf-8 -*-
"""
Created on Wed Dec 23 14:06:10 2015

@author: bitjoy.net
"""

from os import listdir
import xml.etree.ElementTree as ET
import jieba
import jieba.analyse
import sqlite3
import configparser
from datetime import *
import math

import pandas as pd
import numpy as np

from sklearn.metrics import pairwise_distances

class RecommendationModule:
    stop_words = set()
    k_nearest = []

    config_path = ''
    config_encoding = ''

    doc_dir_path = ''
    doc_encoding = ''
    stop_words_path = ''
    stop_words_encoding = ''
    idf_path = ''
    db_path = ''

    def __init__(self, config_path, config_encoding):
        self.config_path = config_path
        self.config_encoding = config_encoding
        config = configparser.ConfigParser()
        config.read(config_path, config_encoding)

        self.doc_dir_path = config['DEFAULT']['doc_dir_path']
        self.doc_encoding = config['DEFAULT']['doc_encoding']
        self.stop_words_path = config['DEFAULT']['stop_words_path']
        self.stop_words_encoding = config['DEFAULT']['stop_words_encoding']
        self.idf_path = config['DEFAULT']['idf_path']
        self.db_path = config['DEFAULT']['db_path']

        f = open(self.stop_words_path, encoding = self.stop_words_encoding)
        words = f.read()
        self.stop_words = set(words.split('\n'))

    def write_k_nearest_matrix_to_db(self):
        conn = sqlite3.connect(self.db_path)
        c = conn.cursor()

        c.execute("'DROP TABLE IF EXISTS knearest'")
        c.execute("'CREATE TABLE knearest(id INTEGER PRIMARY KEY, first INTEGER, second INTEGER, third INTEGER, fourth INTEGER, fifth INTEGER)'")

        for docid, doclist in self.k_nearest:
            c.execute("INSERT INTO knearest VALUES (?, ?, ?, ?, ?, ?)", tuple([docid] + doclist))

        conn.commit()
        conn.close()

    def is_number(self, s):
        try:
            float(s)
            return True
        except ValueError:
            return False

    def construct_dt_matrix(self, files, topK = 200):
        jieba.analyse.set_stop_words(self.stop_words_path)
        jieba.analyse.set_idf_path(self.idf_path)
        M = len(files)
        N = 1
        terms = {}
        dt = []
        for i in files:
            root = ET.parse(self.doc_dir_path + i).getroot()
            title = root.find('title').text
            body = root.find('body').text
            docid = int(root.find('id').text)
            tags = jieba.analyse.extract_tags(title + '。' + body, topK=topK, withWeight=True)
            #tags = jieba.analyse.extract_tags(title, topK=topK, withWeight=True)
            cleaned_dict = {}
            for word, tfidf in tags:
                word = word.strip().lower()
                if word == '' or self.is_number(word):
                    continue
                cleaned_dict[word] = tfidf
                if word not in terms:
                    terms[word] = N
                    N += 1
                    dt.append([docid, cleaned_dict])
                    dt_matrix = [[0 for i in range(N)] for j in range(M)]
        i =0
        for docid, t_tfidf in dt:
            dt_matrix[i][0] = docid
            for term, tfidf in t_tfidf.items():
                dt_matrix[i][terms[term]] = tfidf
                i += 1

        dt_matrix = pd.DataFrame(dt_matrix)
        dt_matrix.index = dt_matrix[0]
        print('dt_matrix shape:(%d %d)'%(dt_matrix.shape))
        return dt_matrix

    def construct_k_nearest_matrix(self, dt_matrix, k):
        tmp = np.array(1 – pairwise_distances(dt_matrix[dt_matrix.columns[1:]], metric = "cosine"))
        similarity_matrix = pd.DataFrame(tmp, index = dt_matrix.index.tolist(), columns = dt_matrix.index.tolist())
        for i in similarity_matrix.index:
            tmp = [int(i),[]]
            j = 0
            while j <= k:
                max_col = similarity_matrix.loc[i].idxmax(axis = 1)
                similarity_matrix.loc[i][max_col] = -1
                if max_col != i:
                    tmp[1].append(int(max_col)) #max column name
                    j += 1
                    self.k_nearest.append(tmp)

    def gen_idf_file(self):
        files = listdir(self.doc_dir_path)
        n = float(len(files))
        idf = {}
        for i in files:
            root = ET.parse(self.doc_dir_path + i).getroot()
            title = root.find('title').text
            body = root.find('body').text
            seg_list = jieba.lcut(title + '。' + body, cut_all=False)
            seg_list = set(seg_list) – self.stop_words
            for word in seg_list:
                word = word.strip().lower()
                if word == '' or self.is_number(word):
                    continue
                if word not in idf:
                    idf[word] = 1
                else:
                    idf[word] = idf[word] + 1
                idf_file = open(self.idf_path, 'w', encoding = 'utf-8')
                for word, df in idf.items():
                    idf_file.write('%s %.9f\n'%(word, math.log(n / df)))
                idf_file.close()

    def find_k_nearest(self, k, topK):
        self.gen_idf_file()
        files = listdir(self.doc_dir_path)
        dt_matrix = self.construct_dt_matrix(files, topK)
        self.construct_k_nearest_matrix(dt_matrix, k)
        self.write_k_nearest_matrix_to_db()

if __name__ == "__main__":
    print('—–start time: %s—–'%(datetime.today()))
    rm = RecommendationModule('../config.ini', 'utf-8')
    rm.find_k_nearest(5, 25)
    print('—–finish time: %s—–'%(datetime.today()))
```

这个模块的代码量最多，主要原因是需要构建文档词项矩阵，并且计算k邻居矩阵。矩阵数据结构的设计需要特别注意，否则会严重影响系统的效率。我刚开始把任务都扔给了pandas.DataFrame，后来发现当两个文档向量合并时，需要join连接操作，当数据量很大时，非常耗时，所以改成了先用python原始的list存储，最后一次性构造一个完整的pandas.DataFrame，速度比之前快了不少。

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