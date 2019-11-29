## mdserver(mac版) 3.3.0.0

Mac上高度可定制的PHP开发环境,集成必要的扩展,方便使用。
(pkg安装方式),安装方便,是你Mac上的PHP开发利器。

- 支持80端口。
- 配置Memcached,Redis,MongoDB通用支持。
- 配置MySQL5.7。
- OpenResty支持Lua开发。
- **php-fpm以sock文件方式管理。多php进程共存,快速切换开发。**
- **高效控制PHP扩展安装、启动、停止、卸载。**
- **完美再现安装过程，利于学习**
- 安装完全脚本化,易于管理。
- 减小文件大小，利于下载。
- 支持PHP版本菜单[Command]下直接进入命令行,并自动设置当前PHP变量。
- 支持CMD菜单下应用的安装、启动、停止、卸载。

```
php[55,56,71,72,73,74]
[redis,memecached,mongo,yaf,swoole,xhprof,...]
```

### 相关项目

- 最新的安装脚本[mdserver-mac-reinstall](https://github.com/midoks/mdserver-mac-reinstall)对应目录->[/Applications/mdserver/bin/reinstall]

### 重要操作说明

```
菜单[CMD]->php-ext-init->install(解决大部分的依赖问题)
```

### 软件版本说明[可能不一致]
- 一个为软件开发版本。
- 一个为打包版本。

### 版本版本

- 3.3.0.0

```
* 优化CMD，可以设置二级菜单。
* mysql有5.6更新至5.7。
* 对reinstall部分脚本优化。
* 菜单[CMD]->php-ext-init->install脚本优化。
* 减少维护PHP54,70。
* 优化hostname,可以设置localhost名称`但是localhost:8888为保留设置,不可重复!`。
```

### 文件说明
- host(修改hosts命令)
- mdserver(主功能)
- Screenshot(截图)

### 相关链接

- 3.3.0.0
	* 百度云:[3.3.0.0](https://pan.baidu.com/s/1sBbp47eFEQc2T92Bpdl9bA)
	* 微云:[3.3.0.0](https://share.weiyun.com/5oCFVfB)

### 相关链接 - 2.x
- 旧版安装地址:[2.x](/README_2x.md)

### 使用说明
[说明](https://github.com/midoks/mdserver-mac/wiki/%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E-3.0)


### 最新版本截图
[![Screenshot_3.png](/Screenshot/Screenshot_3.png)](/Screenshot/Screenshot_3.png)

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_shield)

### 联系我
- e-mail:midoks@163.com
- https://t.me/midoks

### Stargazers over time

[![Stargazers over time](https://starchart.cc/midoks/mdserver-mac.svg)](https://starchart.cc/midoks/mdserver-mac)

### 访问统计，😊
[![Visit tracker](http://www.clustrmaps.com/map_v2.png?d=WGjERIEklP1qbkyucGHB7tWPSBrRHY04mK1xZCft-rA&cl=ffffff)](https://clustrmaps.com/site/1ap6t)


### License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_large)