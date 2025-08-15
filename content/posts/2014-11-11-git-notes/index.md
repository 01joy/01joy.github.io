---
date: '2014-11-11T23:12:34+08:00'
draft: false
title: 'Git相关笔记'
---
# 一、第一次使用Github的步骤：

1. 在这个页面中填写Repo名称
2. 不要勾选Initialize this repository with a README
3. 点击Create repository
4. 在本地使用Git命令行工具进入到和第1步填写Repo相同名称的文件夹中（此文件夹中已包含你要push到Github上的内容），执行以下几个命令：

```shell
git init
touch README.md #optional
git add .
git commit -m ‘your comment’
git remote add origin https://github.com/UserName/RepoName
git push origin master
```

5. 如果你在第2步中勾选了Initialize this repository with a README，那么在第4步中省略touch README.md并且在git add .之前，执行第5行代码，然后git pull origin master将远端（remote）的内容pull到本地
6. 关于Git命令中的fetch和pull的区别，请看这篇博文
7. 关于Git bash和Github的连接，请看这篇博文

# 二、Git命令中fetch和pull的区别（转载）

Git中从远程的分支获取最新的版本到本地有这样2个命令：

1. git fetch：相当于是从远程获取最新版本到本地，不会自动merge

```shell
git fetch origin master
git log -p master..origin/master
git merge origin/master
```

以上命令的含义：首先从远程的origin的master主分支下载最新的版本到origin/master分支上，然后比较本地的master分支和origin/master分支的差别，最后进行合并。

上述过程其实可以用以下更清晰的方式来进行：

```shell
git fetch origin master:tmp
git diff tmp
git merge tmp
```

从远程获取最新的版本到本地的test分支上，之后再进行比较合并。

2. git pull：相当于是从远程获取最新版本并merge到本地

```shell
git pull origin master
```

上述命令其实相当于git fetch + git merge。

在实际使用中，git fetch更安全一些，因为在merge前，我们可以查看更新情况，然后再决定是否合并。