## mdserver(mac版) 4.0.1.0

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
php[55,56,71,72,73,74,80,81]
[redis,memecached,mongo,memcached,yaf,swoole,xhprof,...]
```

- ***MYSQL版本集成***

```
MySQL[50,51,55,56,57,80]
```

### ***phpMyAdmin***

根据选中php版本，自动识别打开版本。需要试用mysql默认以外的版本，需要修改phpMyAdmin相应配置问题。

```
version 4.1.9 , 能登入mysql{50-57}, 需要php<70 , 默认mysql56 , 端口:3356 | http://localhost:8888/phpMyAdmin/
version 5.1.1 , 能登入mysql{55-80}, 需要php>70 , 默认mysql80 , 端口:3306 | http://localhost:8888/phpMyAdmin7/
```

### 下载链接

- 4.0.1.0[445MB] - [官方下载](https://github.com/midoks/mdserver-mac/releases/download/4.0.1.0/mdserver4.0.1.0.mpkg.zip)

```
下载版本中，mysql80集成。其他皆需要现在执行Install,再执行。
为了全版本兼容，可同时开始开启。端口默认如下,也可以自定义。
MySQL51 - port:3351
MySQL55 - port:3355
MySQL56 - port:3356
MySQL57 - port:3357
MySQL80 - port:3306
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

- 4.0.1.0

```
* 启动,停止优化(不再重复输入密码)。
* 加入PHP81正式版本。
* 细节优化。
```

### 文件说明
- host(修改hosts命令)
- mdserver(主功能)
- Screenshot(截图)


### 最新版本截图

[![菜单](/Screenshot/Screenshot_menu.png)](/Screenshot/Screenshot_menu.png)
[![界面](/Screenshot/Screenshot_3.png)](/Screenshot/Screenshot_3.png)



### 联系我
- e-mail:midoks@163.com

### Stargazers over time

[![Stargazers over time](https://starchart.cc/midoks/mdserver-mac.svg)](https://starchart.cc/midoks/mdserver-mac)

### License

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_shield)