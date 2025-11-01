---
date: '2017-02-07T19:15:56+08:00'
draft: false
title: 'Linux性能分析工具简介'
categories: ["0和1"]
tags: ["gperftools","gprof","Linux","Valgrind","性能分析"]
---
这半年一直在研究pLink 2的加速策略，了解了相关的性能分析工具，现记录如下。

对软件进行加速的技术路线一般为：首先对代码进行性能分析（ performance analysis，也称为 profiling），然后针对性能瓶颈提出优化方案，最后在大数据集上评测加速效果。所以进行性能优化的前提就是准确地测量代码中各个模块的时间消耗。听起来很简单，不就是测量每行代码的运行时间吗，直接用time_t t=clock();不就好了，但是事情并没有那么简单。如果只进行粗粒度的性能分析，比如测量几个大的模块的运行时间，clock()还比较准确，但是如果测量的是运算量比较小的函数调用，而且有大量的小函数调用，clock()就不太准确了。

比如下面的一段代码，我最开始的性能分析方法是在fun1()~fun3()前后添加time_t t=clock()，然后作差求和的。但是3个fun()加起来的时间居然不等于整个while循环的时间，有将近50%的时间不翼而飞了！

```cpp
while (true) {
  if (fun1()) {
    for (int i = 0; i < k; ++k) {
      if (flag1) {
        fun2();
      }
    }
  } else {
    fun3();
  }
}
```

一种可能是while循环以及内部的for循环本身占用了较多的时间，但是好像不太可能呀。还有一种可能是clock()测量有误，time_t只能精确到秒，clock_t只能精确到毫秒，如果一次fun*()的时间太短，导致一次测量几乎为0，那么多次的while和for循环调用累加的时间也几乎为0，导致实际测量到的fun*()时间远小于真实时间。所以自己用代码进行性能分析可能会有较大的误差，最好借助已有的性能分析工具。

性能分析和操作系统有较大的关系。因为C++11以前的多线程在不同操作系统中有不同的实现，比如在Windows中使用的是Win32 threads，需要包含windows.h头文件，在Linux中使用的是POSIX Threads，需要包含pthread.h头文件，所以选择性能分析工具首先需要看代码使用的多线程是哪个版本。如果使用的是Win32 threads，则需要在Windows平台选择热点分析工具；如果使用的是POSIX Threads，则需要在Linux平台选择热点分析工具；当然，如果代码中没有多线程或者采用的多线程是C++11标准统一的多线程，原则上可以忽略操作系统的限制。

Windows平台上，之前用过微软的Visual Studio工具进行Profiling，效果很不错，网上的介绍也很多，这里就不详细介绍了。

通过网络搜索我发现了三款Linux平台下主流的热点分析工具，分别是GNU gprof、Valgrind和Google perftools，三款工具的主要特点如下表：

|工具|使用命令|是否需要重新编译|Profiling速度|是否支持多线程热点分析|是否支持链接库热点分析|
|:---:|:---:|:---:|:---:|:---:|:---:|
|[GNU gprof](https://sourceware.org/binutils/docs/gprof/)|./test; gprof ./test ./gmon.out|是|慢|否|否|
|[Valgrind](http://valgrind.org/)|Valgrind –tool=callgrind ./test|否|非常慢|是|是|
|[Google perftools](https://gperftools.github.io/gperftools/cpuprofile.html)|LD_PRELOAD=/usr/lib/libprofiler.so CPUPROFILE=./test.prof ./test|否|快|是|是|

[GNU gprof](https://sourceware.org/binutils/docs/gprof/)是GNU G++自带的热点分析工具，使用方法是：1. 使用-pg选项重新编译代码；2. 执行程序./test，生成热点分析结果gmont.out；3.使用gprof查看结果gprof ./test ./gmon.out。因为gprof要求用-pg重新编译代码，需要在Debug模式下进行Profiling，所以速度较慢。另外gprof不支持多线程的热点分析。这个工具另一个大问题是，不支持链接库的热点分析。很多大型项目为了模块化管理会生成很多动态链接库供其他程序调用，如果要分析每个模块的热点，这个工具就不适用了。

[Valgrind](http://www.valgrind.org/)是一系列工具的套装，包括内存分析、热点分析等。它的使用非常简单，安装好之后，直接调用Vallgrind中的callgrind工具即可，命令为Valgrind –tool=callgrind ./test。使用该工具Profiling无需重新编译代码，也支持多线程和链接库的热点分析，但是由于Profiling原理的特殊性，其Profiling速度非常之慢，比直接运行程序慢了将近50倍，所以并不适合稍大型程序的热点分析。本人试用之后发现其结果展示做得也不是很好。

[Google perftools](https://gperftools.github.io/gperftools/cpuprofile.html)原是Google内部的性能分析工具，后来在Github上开源了，地址是[https://github.com/gperftools/gperftools](https://github.com/gperftools/gperftools)。gperftools 的工作原理为通过定期采样当前正在执行的指令进行性能分析，如果某个函数被采样到的次数越多，则该函数在执行时占用的时间比例越大，很可能就是性能瓶颈。 gperftools 可以在被测软件处于 Release 模式下进行性能分析，所以能最大程度的模拟软件的实际使用情况。这个工具使用起来也非常简单，只需Preload其.so文件并指定生成的Profiling文件路径即可，命令为LD_PRELOAD=/usr/lib/libprofiler.so CPUPROFILE=./test.prof ./test。程序结束之后，使用命令google-pprof –web ./test ./test.prof即可查看热点分析结果。使用该工具Profiling无需重新编译代码，也支持多线程和链接库的热点分析，同时由于其是通过定期采样正在执行的指令进行热点分析，所以Profiling速度非常快，和正常release下执行程序的速度几乎相当。

通过试用，发现gperftools的易用性、可视化效果等都是最好的，所以推荐大家使用gperftools。我最看重gperftools的特点是支持链接库和多线程的热点分析。下一篇博客将简单举一个用gperftools对链接库进行性能分析的例子。

参考：

Linux平台性能分析工具“综述”：[http://gernotklingler.com/blog/gprof-valgrind-gperftools-evaluation-tools-application-level-cpu-profiling-linux/](http://gernotklingler.com/blog/gprof-valgrind-gperftools-evaluation-tools-application-level-cpu-profiling-linux/)