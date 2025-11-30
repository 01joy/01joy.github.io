---
date: '2019-06-23T13:07:09+08:00'
draft: false
title: 'CS224N（1.10）Word Vectors 2 and Word Senses'
categories: ['0和1','Stanford CS224N: NLP with Deep Learning']
tags: ['词向量','词义','GloVe','NLP']
---
这一讲是上一讲的补充，内容比较零碎，包括：Word2vec回顾、优化、基于统计的词向量、GloVe、词向量评价、词义等，前两个内容没必要再介绍了，下面逐一介绍后四个内容。

# 基于统计的词向量

词向量的目的就是希望通过低维稠密向量来表示词的含义，而词的分布式语义表示方法认为词的含义由其上下文语境决定。Word2vec把中心词和临近词抽取出来，通过预测的方式训练得到词向量。在Word2vec之前，传统的方式通过统计词的共现性来得到词向量，即一个词的词向量表示为其临近词出现的频率，如果两个词的含义很相近，则其临近词分布会比较像，得到的词向量也比较像。其具体计算过程在[第一次作业](https://github.com/01joy/stanford-cs224n-winter-2019/blob/master/1.8/assignment/a1/exploring_word_vectors.ipynb)中有详细的描述，这里再简单回顾如下。

假设一个语料库中包含三个句子，共有8个特异词（包括点号），对于每个词，统计其前后一个词的词频（临近窗口为1），由此能得到一个8×8的对称矩阵，其每一行（或每一列）表示该词的词向量。比如对于like这个词，在三个句子中，其左右共出现2次I，1次deep和1次NLP，所以like对应的词向量中，I、deep和NLP维的值分别为2,1,1。

![](co-occurrence_matrix.png)

这种基于词频统计的方法很简单，但是它有如下不足：

* 特异的词很多，所以矩阵很大，维度很高，需要的存储空间也很大
* 特异词的数目是在不断增长的，则词向量的维度也在不断增长
* 矩阵很稀疏，即词向量很稀疏，会导致很多NLP任务会遇到稀疏计算的问题

所以需要把上述计数矩阵转换为一个低维稠密的矩阵，方法就是SVD分解。上述矩阵原本是一个\(n\times n\)的矩阵，SVD分解后能得到一个\(n\times k\)的矩阵，其中\(k\ll n\)。即原本的词向量是一个\(n\)维的高维稀疏向量，变成了\(k\)维的低维稠密向量，而且还不会损失太多的信息。

[2005年的一篇文章](https://pdfs.semanticscholar.org/73e6/351a8fb61afc810a8bb3feaa44c41e5c5d7b.pdf)对上述简单的计数方法进行了改进，包括去掉停用词、使用倾斜窗口、使用皮尔逊相关系数等，提出了COALS模型，该模型得到的词向量效果也不错，也具有句法特征和语义特征。使用统计的方法和使用预测的方法训练词向量，两者的对比如下。基于统计计数的方法的主要特点是：训练速度快，能充分利用统计信息，主要用来捕获词的相似性。基于预测的方法的主要特点是：对语料库的大小可扩展，没有充分利用统计信息，能捕获除了词的相似性之外的其他复杂特征。

![](count_based_vs_direct_prediction.png)

# GloVe

GloVe的全称是[GloVe: Global Vectors for Word Representation](https://nlp.stanford.edu/projects/glove/)，正是这门课的老师Christopher D. Manning的研究成果。有关GloVe论文的详细解读，可以看[这篇博客](https://blog.csdn.net/coderTC/article/details/73864097)。GloVe希望能综合上述基于统计和基于预测的两种方法的优点。

GloVe的基本思想依然是基于统计的方法，当统计得到共现矩阵X之后，可以计算得到词\(k\)是词\(i\)的临近词的概率：

$$P_{i,k}=\dfrac{X_{i,k}}{X_{i}}$$

再定义两个\(P\)的比值：

$$ratio_{i,j,k}=\dfrac{P_{i,k}}{P_{j,k}}$$

如果词\(k\)在两个词\(i\)和\(j\)的临近概率相同，无论是同样大（water）还是同样小（fashion），经过比值计算后，\(ratio_{i,j,k}\)都约等于1了，说明在维度water和fashion上，无法区分ice和steam。而在维度solid和gash上，由于概率\(P\)的差异，导致\(ratio_{i,j,k}\)很大或者很小，这是有意义的，说明在solid和gas维度上，可以区分ice和steam的语义。

![](GloVe.png)

基于这样的观察，GloVe首先统计语料库中三元组\(i,j,k\)的\(ratio_{i,j,k}\)，然后初始化词向量\(v\)，构造函数\(g\)，使得利用词向量计算得到的\(g(v_{i},v_{j},v_{k})\)和真实\(ratio_{i,j,k}\)尽量接近。

$$\dfrac{P_{i,k}}{P_{j,k}}=ratio_{i,j,k}=g(v_{i},v_{j},v_{k})$$

$$J=\sum_{i,j,k}^N(\dfrac{P_{i,k}}{P_{j,k}}-g(v_{i},v_{j},v_{k}))^2$$

但是上述方法的复杂度太高了，对于一个\(N\times N\)的共现矩阵，上述算法需要计算所有的三元组，复杂度是\(N\times N\times N\)。GloVe文章通过各种转换技巧，把复杂度降为了一个\(N\times N\)的问题，具体过程可以看上面提到的博客或者paper原文。

总的来说，基于共现矩阵这种统计的方法，能捕获整个语料库全局的信息；而类似word2vec的预测的方法，则主要捕获局部的滑动窗口内的共现信息，两种方法训练得到的词向量效果都不错。

# 词向量评价

评价词向量的好坏主要有两个尺度，一是内部任务评价（intrinsic），一是外部任务评价（extrinsic），两者的主要特点如下。大概意思是内部任务是根据词本身具有的性质，比如近义、反义等，评价词向量本身的性能。外部任务是指词向量对NLP下游任务的性能的影响，比如同样是一个文本分类问题，换不同的词向量，对文本分类任务的性能的影响能反映出词向量的性能。

![](word_vector_evaluation.png)

常见的内部任务评价是词的类比推理（Word Vector Analogies），就是类似man:woman :: king:queen这种，word2vec还专门整理出了这样的测试数据：[word2vec/trunk/questions-words.txt](https://code.google.com/archive/p/word2vec/source/default/source)。另一个内部任务评价是使用训练得到的词向量计算的词相似度，和人类认为的相似度做比较，有团队专门整理出了人类对两个词的相似度打分，具体可以看[这里](http://www.cs.technion.ac.il/~gabr/resources/data/wordsim353/)。

对词向量的外部任务评价就很多了，几乎所有的NLP任务都可以用来作为词向量的外部任务评价，比如命名实体识别、文本分类等等，这里不再展开。

# 词义

一个词往往具有多个含义（word senses），特别是对于常用的词或者存在很久的词。那么一个词向量能同时包含这个词的多个语义吗？有文章把一个词的多个语义通过线性加权的方式叠加到一个词向量中，然后还能通过稀疏编码的方式求解出每个语义的词向量，具体可以看下图中的参考文献。

![](word_senses.png)