## mdserver(mac版) 4.0.0.0

Mac上高度可定制的PHP开发环境,集成必要的扩展,方便使用。
(pkg安装方式),安装方便,是你Mac上的PHP开发利器。



- 支持80端口。
- OpenResty(1.15.8.3)支持Lua开发。
- Redis(6.2.5),MongoDB(5.0.0),Memcached(1.6.10)。
- **php-fpm以sock文件方式管理。多php进程共存,快速切换开发。**
- **高效控制PHP扩展安装、启动、停止、卸载。**
- **完美再现安装过程，利于学习。**
- 安装完全脚本化,易于管理。
- 减小文件大小，利于下载。
- 支持PHP版本菜单[Command]下直接进入命令行,并自动设置当前PHP变量。
- 支持CMD菜单下应用的安装、启动、停止、卸载。

## PHP|MYSQL

- ***PHP版本集成***

```
php[55,56,71,72,73,74,80]
[redis,memecached,mongo,memcached,yaf,swoole,xhprof,...]
```

- ***MYSQL版本集成***

```
MySQL[51,55,56,57,80]
```

### 下载链接

- 4.0.0.0 - [官方下载](https://github.com/midoks/mdserver-mac/releases/download/4.0.0.0/mdserver4.0.0.0.mpkg.zip)

```
下载版本中，mysql57,mysql80集成。其他皆需要现在执行Install,再执行。
```


### 相关项目

- 最新的安装脚本[mdserver-mac-reinstall](https://github.com/midoks/mdserver-mac-reinstall)对应目录->[/Applications/mdserver/bin/reinstall]

### 重要操作说明

```
菜单[CMD]->php-ext-init->install(解决大部分的依赖问题)
```

### 安装失败
- 安装失败是获取权限脚本没有执行成功,执行下面命令即可:
```
sudo sh /Applications/mdserver/install.sh
```

### 版本版本

- 4.0.0.0

```
* mysql51-80版本集成。
* mysql{57,80}版本打包集成,其他需要手动Install。
* redis,memcached,mongodb版本更新。
* PHP8正式版。
* PHP8扩展更新。
```

### 文件说明
- host(修改hosts命令)
- mdserver(主功能)
- Screenshot(截图)


### 最新版本截图
[![最新版本截图](/Screenshot/Screenshot_3.png)](/Screenshot/Screenshot_3.png)


### 联系我
- e-mail:midoks@163.com
- https://t.me/midoks

### Stargazers over time

[![Stargazers over time](https://starchart.cc/midoks/mdserver-mac.svg)](https://starchart.cc/midoks/mdserver-mac)

### License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_large)

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_shield)