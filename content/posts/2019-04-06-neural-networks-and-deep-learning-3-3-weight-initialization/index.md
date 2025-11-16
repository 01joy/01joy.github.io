---
date: '2019-04-06T17:52:56+08:00'
draft: false
title: 'Neural Networks and Deep Learning（三·三）权重初始化及其他'
categories: ['0和1','neuralnetworksanddeeplearning.com']
tags: ['ReLU','tanh']
---
# 权重初始化

在之前的章节中，我们都是用一个标准正态分布\(N(0,1^2)\)初始化所有的参数\(w\)和\(b\)，但是当神经元数量比较多时，会出现意想不到的问题。

假设一个神经网络的输入层有1000个神经元，且某个样本的1000维输入中，恰好有500维是0，另500维是1。我们目前考察隐藏层的第一个神经元，则该神经元为激活的输出为\(z = \sum_j w_j x_j+b\)，因为输入中的500维是0，所以\(z\)相当于有501个来自\(N(0,1^2)\)的随机变量相加。因为\(w_j\)和\(b\)的初始化都是独立同分布的，所以\(z\)也是一个正态分布，均值为0，但方差变成了\(\sqrt{501} \approx 22.4\)，即\(z\sim N(0,\sqrt{501}^2)\)。我们知道对于正态分布，如果方差越小，则分布的形状是高廋型的；如果方差越大，则分布的形状是矮胖型的。所以\(z\)有很大的概率取值会远大于1或远小于-1。又因为激活函数是sigmoid，当\(z\)远大于1或远小于-1时，\(\sigma (z)\)趋近于1或者0，且导数趋于0，变化缓慢，导致梯度消失。

![](https://i0.wp.com/neuralnetworksanddeeplearning.com/images/tikz32.png)  |  ![](ch3.8.png)
:-------------------------:|:-------------------------:

请注意，这里的梯度消失和[之前介绍得梯度消失](https://bitjoy.net/posts/2019-03-18-neural-networks-and-deep-learning-3-1-gradient-vanishing/)稍有不同，之前是说在误差反向传播过程中，损失函数对权重的导数中包含梯度消失项，所以可以通过更换损失函数来解决。但是这里的梯度消失并不是在误差反向传播过程中产生的，而是在正向传播产生的，跟损失函数没关系。

解决这个问题的方法很简单，根据上面的分析，如果输入\(x_j\)全为1，\(w\)和\(b\)都来自\(N(0,1^2)\)，则\(z\sim N(0, \sqrt{n+1}^2)\)，其中\(n\)为输入样本的维度。要减小\(z\)的方差，减小\(w\)和\(b\)的方差就可以了。因为\(b\)只有一个，对整体的影响不大，可以不修改\(b\)的分布，\(b\)依然来自\(N(0,1^2)\)。把\(w_j\)的分布修改为\(N(0, (\frac{1}{\sqrt{n}})^2)\)，此时\(z\sim N(0, \sqrt{2}^2)\)，\(\sqrt{2}=1.414\)就非常接近1了，\(z\)的分布也变成了一个高廋型的，梯度消失问题也就不存在了。

如果是开头的例子，输入维度为1000，其中500为0，500为1，\(w_j\sim N(0, (\frac{1}{\sqrt{1000}})^2)\)，\(b\sim N(0,1^2)\)，则\(z\sim N(0, \sqrt{\frac{3}{2}}^2)\)，\(\sqrt{3/2} = 1.22\ldots\)也是高廋型的，不会有梯度消失的问题。

由下图可知，在新的权重初始化策略下，网络很快就收敛了，比之前的方法快很多。

![](https://i0.wp.com/neuralnetworksanddeeplearning.com/images/weight_initialization_30.png)

# 怎样选择超参数

大原则：在网络优化的前期，尽量使网络结构、问题简单，以便快速得实验结果，不断尝试超参数取值，当找到正确的优化方向后，再慢慢把网络和问题变复杂，精细调整超参数。比如MNIST问题，开始可以减少训练数据，只取0和1的图片，做二分类；同时可以减少网络层数，验证集大小等，以便快速得到网络输出，判断网络性能变化。这样可以快速尝试新的超参数。

# 学习率\(\eta\)

在误差反向传播中，学习率太大，虽然可以加速学习，但在后期可能导致网络震荡，无法收敛；学习率太小，导致学习速度太慢，训练时间过长。

![](https://i0.wp.com/neuralnetworksanddeeplearning.com/images/multiple_eta.png)

确定学习率的方法是：首先随便选定一个值，比如0.01，然后不断增大10倍：0.1, 1, 10, 100…如果发现cost曲线在震荡，说明选大了，要降低，直到找到一个比较合适的值。这个过程只要找到合适的数量级就可以了，不一定要非常精确。比如发现0.1是比较合适的，那么可以再尝试0.2,0.3…，如果发现0.5不错，可以设学习率为0.5的一半0.25，这样可以使得在后续epoch中，不容易发生震荡。最好的方法是可变学习率，即前期学习率稍大（0.5），后期学习率稍小（0.1）之类的。

# epoch

no-improvement-in-ten rule，就是说如果模型在最近的10个epoch中，验证集的accuracy都没有提高，则可以stop了。在早期实验中可以这么做，后续精细优化时可以改变ten，比如no-improvement-in-20/30等。

# 正则化参数\(\lambda\)

首先不要正则（\(\lambda=0\)），使用上面提到的方法确定学习率\(\eta\)，在确定的学习率情况下，正则\(\lambda=1\)开始进行优化，比如每次乘以10或者除以10，观察验证集上的accuracy指标，找到正则化所在的合适的数量级，然后再fine-tune。

# Mini-batch size

太小了，无法利用现有软件包的矩阵操作的优势，速度会很慢。极端情况下，如果mini-batch size=1，就是说每次只用一个sample做BP，则100次mini-batch=1会比一次mini-batch=100操作慢很多，因为很多软件包对矩阵操作有优化，而没有对for循环优化。太大了，则一次BP要很久，参数更新的次数也比较少。

# 其他技术

## 随机梯度下降SGD的变种

### 海森矩阵法

SGD优化的目标就是最小化损失函数\(C\)，\(C\)是所有参数\(w = w_1, w_2, \ldots\)的函数，即\(C=C(w)\)。希望能够通过改变\(w\)，不断最小化\(C\)，即找一个\(\Delta w\)，使得\(C(w+\Delta w)\)最小化。把\(C(w+\Delta w)\)泰勒展开得到：

$$\begin{eqnarray}C(w+\Delta w) & = & C(w) + \sum_j \frac{\partial C}{\partial w_j} \Delta w_j\nonumber \\ & & + \frac{1}{2} \sum_{jk} \Delta w_j \frac{\partial^2 C}{\partial w_j\partial w_k} \Delta w_k + \ldots\tag{1}\end{eqnarray}$$

写成矩阵形式就是：

$$\begin{eqnarray}C(w+\Delta w) = C(w) + \nabla C \cdot \Delta w +\frac{1}{2} \Delta w^T H \Delta w + \ldots,\tag{2}\end{eqnarray}$$

其中的\(\nabla C\)就是常规的梯度向量，\(H\)就是著名的海森矩阵，其中\(H_{jk}=\partial^2 C / \partial w_j \partial w_k\)。如果把(2)中的高阶项扔掉，得到如下的近似等式：

$$\begin{eqnarray} C(w+\Delta w) \approx C(w) + \nabla C \cdot \Delta w +\frac{1}{2} \Delta w^T H \Delta w.\tag{3}\end{eqnarray}$$

最小化(3)的右边，得：

$$\begin{eqnarray}\Delta w = -H^{-1} \nabla C.\tag{4}\end{eqnarray}$$

所以我们可以通过如下方式更新\(w\)已达到最小化\(C\)的目的，当然也可以给\(\Delta w\)乘上学习率\(\eta\)。

![](ch3.9.png)

海森矩阵法有点像通过解析的方式最小化\(C\)，感觉上比SGD方法更精确靠谱。事实上，海森矩阵法确实比SGD方法收敛速度更快，但是因为在公式(4)中需要求解海森矩阵\(H\)的逆矩阵\(H^{-1}\)，当网络的参数量很大时，求解过程会非常慢，导致海森矩阵法不实用。

### 基于动量的梯度下降

增加速度这个变量，个人不是太理解：

$$\begin{eqnarray} v & \rightarrow & v’ = \mu v – \eta \nabla C \tag{5}\\w & \rightarrow & w’ = w+v’.\tag{6}\end{eqnarray}$$

## 不同的激活函数

tanh是和sigmoid很像的一个激活函数，其函数形式为：

$$\begin{eqnarray}\tanh(z) \equiv \frac{e^z-e^{-z}}{e^z+e^{-z}}.\tag{7}\end{eqnarray}$$

事实上，sigmoid函数\(\sigma(z)\)和\(\tanh(z)\)有线性关系：

$$\begin{eqnarray} \sigma(z) = \frac{1+\tanh(z/2)}{2},\tag{8}\end{eqnarray}$$

\(\tanh(z)\)的函数图像如下，和sigmoid非常类似：

![](ch3.10.png)

\(\tanh(z)\)和sigmoid的主要区别就是值域不一样，前者值域为[-1,1]，后者值域为[0,1]。这会导致什么差异呢？观察(BP4)这个公式，对于第\(l\)层的第\(j\)个神经元和第\(l-1\)层的所有神经元的连接权重\(w_{jk}^l\)，如果使用sigmoid激活，则\(a_k^{l-1}\)都是非负的，而这些梯度共用一个\(\delta_j^l\)，所以对于固定的\(j\)，不同的\(k\)，所有的梯度\(\frac{\partial C}{\partial w^l_{jk}}\)方向是一样的！这在无形中就减小了搜索空间。而如果用\(\tanh(z)\)激活的话，不同的\(k\)的\(a^{l-1}_k\)正负号可能就不一样，搜索空间更大，更容易收敛。


![](https://i0.wp.com/neuralnetworksanddeeplearning.com/images/tikz21.png)  |  ![](ch3.11.png)
:-------------------------:|:-------------------------:

另一个比较常见的激活函数是ReLU激活函数，其函数形式如下：

$$ReLU(z)=max(0, z)\tag{9}$$

函数图像如下：

![](ch3.12.png)

ReLU和Sigmoid、tanh很不一样，ReLU在\(z>0\)的方向上不会有梯度消失的问题。

好了，第三章的内容就全部介绍完毕了，这一章介绍了很多调试神经网络的经验法则，没有太多的理论基础，相信随着这个领域的发展，神经网络的黑盒子会被慢慢打开。