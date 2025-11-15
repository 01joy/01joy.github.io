---
date: '2018-11-25T11:33:45+08:00'
draft: false
title: 'Neural Networks and Deep Learning（一）MNIST数据集介绍'
categories: ['0和1','neuralnetworksanddeeplearning.com']
tags: ['神经网络','MNIST','深度学习']
---
最近开始学习神经网络和深度学习，使用的是网上教程：[http://neuralnetworksanddeeplearning.com/](http://neuralnetworksanddeeplearning.com/)，这是学习心得第一讲，介绍经典的MNIST手写数字图片数据集。

MNIST（Modified National Institute of Standards and Technology database）数据集改编自美国国家标准与技术研究所收集的更大的NIST数据集，该数据集来自250个不同人手写的数字图片，一半是人口普查局的工作人员，一半是高中生。该数据集包括60000张训练集图片和10000张测试集图片，训练集和测试集都提供了正确答案。每张图片都是28×28=784大小的灰度图片，也就是一个28×28的矩阵，里面每个值是一个像素点，值在[0,1]之间，0表示白色，1表示黑色，(0,1)之间表示不同的灰度。下面是该数据集中的一些手写数字图片，可以有一个感性的认识。

![](https://i0.wp.com/neuralnetworksanddeeplearning.com/images/digits_separate.png)

MNIST数据集可以在Yann LeCun的网站上下载到：[http://yann.lecun.com/exdb/mnist/](http://yann.lecun.com/exdb/mnist/)，但是他提供的MNIST数据集格式比较复杂，需要自己写代码进行解析。目前很多深度学习框架都自带了MNIST数据集，比较流行的是转换为pkl格式的版本：[http://deeplearning.net/data/mnist/mnist.pkl.gz](http://deeplearning.net/data/mnist/mnist.pkl.gz)，该版本把原始的60000张训练集进一步划分成了50000张小训练集和10000张验证集，下面以这个版本为例进行介绍。

pkl是python内置的一种格式，可以将python的各种数据结构序列化存储到磁盘中，需要时又可以读取并反序列化到内存中。mnist.pkl.gz做了两次操作，先pkl序列化，再gz压缩存储，所以要读取该文件，需要先解压再反序列化，在python3中，读取mnist.pkl.gz的方式如下：

```python
import pickle
import gzip
f = gzip.open(‘../data/mnist.pkl.gz’, ‘rb’)
training_data, validation_data, test_data = pickle.load(f, encoding=’bytes’)
f.close()
```

这样就得到了训练集、验证集和测试集。将数据集序列化到文件中的方法也很简单，需要注意的是pickle在序列化和反序列化时有不同的协议，可以用protocol参数进行设置。

```python
dataset=[training_data, validation_data, test_data]
f=gzip.open(‘../data/mnist3.pkl.gz’,’wb’)
pickle.dump(dataset,f,protocol=3)
f.close()
```

我们从mnist.pkl.gz读取到的training_data, validation_data, test_data这三个数据的结构是一样的，每个都是一个二维的tuple。以training_data为例，training_data[0]是训练样本，是一个50000×784的矩阵，表示有50000个训练样本，每个训练样本是一个784的一维数组，784就是把一张28×28的图片展开reshape成的一维数组；training_data[1]是训练样本对应的类标号，大小为50000的一维数组，每个值为0~9中的某个数，表示对应样本的数字标号。

对于第一次接触MNIST数据集的同学来说，以压缩的pkl格式存储的手写数字图片往往不利于他们感性直观的认识这个问题，下面介绍怎样将MNIST数据集打印成常见的png格式图片，也就是博客开头的真正的“图片”。

就像上面介绍的一样，training_data, validation_data, test_data这三个数据的结构都是一个二维的tuple，下标0存储了n张图片数据，下标1存储了这n张图片对应的答案。现在我们把validation_data的第一张图片打印出来看看，代码如下：

```python
def plot_digit(X, y):
    np.savetxt('../fig/%d.csv'%y, X, delimiter=',')

import matplotlib.pyplot as plt
plt.imshow(X, cmap='Greys') # or 'Greys_r'
plt.savefig('../fig/%d.png'%y)
plt.show()

training_data, validation_data, test_data = load_data()
X=np.reshape(validation_data[0][0], (28, 28))
y=validation_data[1][0]
plot_digit(X, y)
```

首先我们取出validation_data数据集的第一张图片，reshape成原始图片的28×28的矩阵形式，保存在X中，然后我们取出这张图片对应的正确答案，保存在y中，最后调用plot_digit函数打印这个数字。

在plot_digit函数中，我们首先把矩阵X保存到一个csv表格中，如果我们打开这个表格，会发现传说中的图片真的就是一个28×28的矩阵，单元格的值在[0,1]之间，如果我们使用LibreOffice默认的条件格式进行着色的话，能明显看到一个数字3。

![](3_plain.png)  |  ![](3_color.png)
:-------------------------:|:-------------------------:

另外，我们还可以matplotlib打印出这张手写数字图片，使用imshow并指定着色规则是灰度Greys即可，得到的就是本文开头看到的那种白底黑字了。

![](3.png)

好啦，有关MNIST数据集的介绍就到这里，完整代码可以查看我的Github：[https://github.com/01joy/neural-networks-and-deep-learning/blob/master/src/mnist_loader.py](https://github.com/01joy/neural-networks-and-deep-learning/blob/master/src/mnist_loader.py)，下一步开始学习使用BP网络进行图片分类。