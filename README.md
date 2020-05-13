## mdserver(mac版) 3.3.1.0

Mac上高度可定制的PHP开发环境,集成必要的扩展,方便使用。
(pkg安装方式),安装方便,是你Mac上的PHP开发利器。

- 支持80端口。
- Redis(6.0.0)。
- MongoDB(4.2.6)。
- Memcached(1.6.5)。
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

### 下载链接

- 3.3.1.0
    * [官方下载](https://github.com/midoks/mdserver-mac/releases/download/3.3.1.0/mdserver3.3.1.0.mpkg.zip)
	* 百度云-密码:ntvj:[3.3.1.0](https://pan.baidu.com/s/1OIjnAH1hMM4ImWRP7eTJ-g)
	* [天翼云盘](https://cloud.189.cn/t/QzEJ3mAfQ3ui)

### 相关链接 - 2.x
- 旧版安装地址:[2.x](/README_2x.md)

### 使用说明
[说明](https://github.com/midoks/mdserver-mac/wiki/%E4%BD%BF%E7%94%A8%E8%AF%B4%E6%98%8E-3.0)


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

### 软件版本说明[可能不一致]
- 一个为软件界面开发版本。
- 一个为打包版本。

### 版本版本

- 3.3.1.0

```
* 对reinstall部分脚本优化。
* 菜单[CMD]->php-ext-init->install脚本优化。
* 72,73,74更新到最新。
* HOSTS配置保存公共位置,下次跟新不回覆盖。
* 更新redis,memcached,mongodb更新最新的稳定版。
* reinstall目录安装脚本更新。
```

### 文件说明
- host(修改hosts命令)
- mdserver(主功能)
- Screenshot(截图)


### 最新版本截图
[![最新版本截图](https://github.com/midoks/mdserver-mac/blob/master/Screenshot/Screenshot_3.png)](https://github.com/midoks/mdserver-mac/blob/master/Screenshot/Screenshot_3.png)


### 联系我
- e-mail:midoks@163.com
- https://t.me/midoks

### Stargazers over time

[![Stargazers over time](https://starchart.cc/midoks/mdserver-mac.svg)](https://starchart.cc/midoks/mdserver-mac)

### 访问统计，😊
[![Visit tracker](http://www.clustrmaps.com/map_v2.png?d=WGjERIEklP1qbkyucGHB7tWPSBrRHY04mK1xZCft-rA&cl=ffffff)](https://clustrmaps.com/site/1ap6t)


### License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_large)

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_shield)