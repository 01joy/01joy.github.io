---
date: '2018-11-13T11:09:48+08:00'
draft: false
title: 'Ubuntu下使用VSCode连接Github'
categories: ['0和1']
tags: ['Github','VSCode']
---
VSCode是微软开源的一个很强大的IDE，可以支持几乎所有编程语言，而且是跨平台的，Linux用户终于可以用上宇宙最强IDE了。我最近在使用VSCode编写调试Python项目，其调试功能很强大，和VS上调试C++的感觉是一样的，强烈推荐。

VSCode还可以连接Github，进行版本控制。下面以我最近学习的深度学习项目为例，介绍下怎样在Ubuntu下使用VSCode连接Github。以我fork的repo为例：[https://github.com/01joy/neural-networks-and-deep-learning](https://github.com/01joy/neural-networks-and-deep-learning)。

连接Github有两种方式，一种是HTTPS，另一种是SSH，在每个repo页面的右边，有一个Clone or download按钮，可以获取到这两种连接方式的地址。HTTPS方式和网址类似，以HTTPS开头；SSH方式以git@githu.com开头。使用HTTPS连接比较简单，但是每次push的时候需要输入用户名和密码，比较麻烦，如果想记住密码，需要把用户名和密码以明文的形式保存到一个文件中，个人感觉不方便且不安全。下面以SSH连接为例进行介绍。

1. 首先设置Github提交时的用户名和密码，一般设置成全局的：[https://help.github.com/articles/setting-your-username-in-git/](https://help.github.com/articles/setting-your-username-in-git/)、[https://help.github.com/articles/setting-your-commit-email-address-in-git/](https://help.github.com/articles/setting-your-commit-email-address-in-git/)
2. 生成一对新的SSH公钥和私钥，并添加到ssh-agent中。注意生成的时候需要输入passphrase，这个passphrase不是Github的密码，自己随便取一个记住就好。[https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)
3. 把SSH的公钥添加到Github账号中：[https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/)
4. 测试SSH连接是否成功：[https://help.github.com/articles/testing-your-ssh-connection/](https://help.github.com/articles/testing-your-ssh-connection/)
5. （可选）修改SSH密码，即第1步设置的passphrase：[https://help.github.com/articles/working-with-ssh-key-passphrases/](https://help.github.com/articles/working-with-ssh-key-passphrases/)
6. 到这里，本级就能通过SSH连接Github了。

如果没有安装VSCode，可以直接通过Ubuntu的终端连接Github，步骤如下：

1. 在本地创建一个和远程repo名称一样的空文件夹
2. 终端cd到该文件夹内
3. git init # 在该文件夹内初始化
4. git remote add origin git@github.com:01joy/notes-on-writing.git # 使用repo的SSH地址
5. git pull origin master # 把远程代码拉到本地
6. 修改代码
7. git add . # 在根目录执行，添加所有修改
8. git commit -m ‘comments’ # commit第7步添加的修改
9. git push origin master # 把第8步发布到远程

如果安装了VSCode，其实和直接用终端是一样的，在菜单栏的Terminal下新建一个终端，在这个终端内执行上述代码，如果在第4步出现”Enter password to unlock the private key”时，输入创建SSH时第2步的密码即可，只需一次，下次就不用再输入密码了。点击File的Open Folder打开本地repo文件夹。点击VSCode左边栏的Explorer可以在编辑器下修改代码。切换到左边栏的Source Control可以进行Git相关操作，修改的文件右边会出现一个M，点击这个M会出现diff视图；Source Control左边的右上角有三个点，点击这个按钮会出现很多Git操作，包括commit、push等，其实相当于调用上述代码，效果是一样的。

VSCode快捷键Ctrl+Shift+P会出现命令窗口，在里面输入commit、push等会出现相关操作的，能起到一定的加速效果，当然也可以自定义快捷键。

Have Fun!