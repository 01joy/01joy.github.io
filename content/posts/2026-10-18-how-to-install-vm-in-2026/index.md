---
date: '2026-10-18T10:10:25+08:00'
draft: false
title: '2026年如何安装虚拟机'
categories: ["流水账"]
tags: ["VMware","VirtualBox","虚拟机"]
---
在大学时代，经常使用daoban的VMware在Windows上安装各种虚拟机操作系统，后来daoban成本越来越高，转而使用开源免费的VirtualBox。VirtualBox使用了几年体验还不错，但是最近想继续使用的时候，发现很多新的问题。可能主要原因是宿主机的Windows版本升级之后，新增了很多安全策略，比如内存完整性，Hyper-V等等，导致VirtualBox打开虚拟机的时候报错，而且报错信息非常不明朗，折腾了好几天尝试各种办法都没有解决。

后来想到VMware毕竟是商业软件，它的使用体验应该会比VirtualBox好吧？于是顺手搜索了VMware。发现时代真的变了，2023年博通收购了VMware，2024年VMware宣布个人使用VMware免费！因此，以后个人使用VMware再也不用冒着daoban的风险了。

于是非常高兴的跑去VMware官网下载使用。但是发现天下没有免费的午餐啊，虽然免费了，但是获取成本增加了很多。单是要从官网下载这一件事，就非常的麻烦！需要注册博通账号，阅读协议，填写个人信息，期间还会遇到 `Account verification is Pending. Please try after some time.` 令人摸不着头脑的问题。查了下网上吐槽VMware被博通收购后下载繁琐的控诉非常多。好在网友的智慧还是更多一些，在 [我熬夜3天！终于搞定了VMware 2026官网免费下载的终极避坑指南](https://juejin.cn/post/7664180397866237952) 这个教程的帮助下，我终于从官网成功下载到了免费版本的VMware。

安装VMware的过程比较简单，而且安装过程中VMware会自动根据宿主机的安全设置进行提醒，应该如何安装之类的，比VirtualBox的体验确实好很多。

安装完VMware之后，继续在VMware里面安装各种虚拟机，会发现虚拟机无法全屏，分辨率对不上等小问题，官网推荐安装VMware Tools来解决。但是被博通收购后的新版本中，`VMware Tools 不再随旧版客户机操作系统提供`，为了安装VMware Tools，又需要折腾一番！在 [VMware Tools 不再随旧版客户机操作系统的 VMware Workstation 一起提供](https://juejin.cn/post/7560657869608321034) 这个教程的帮助下，使用开源的 [open-vm-tools](https://github.com/vmware/open-vm-tools) 实现了快速平替。

总结一句话：VMware和VirtualBox现在都可以官方免费使用；而且VMware比VirtualBox功能更强大、使用体验更好；但是VMware的下载过程比VirtualBox麻烦很多，建议参考上述教程。