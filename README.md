## mdserver(mac版) 5.0

Mac上高度可定制的PHP开发环境,集成必要的扩展,方便使用。
(pkg安装方式),安装方便,是你Mac上的PHP开发利器。


- 支持80端口。
- OpenResty(1.21.4.3)支持Lua开发。
- Redis(7.2.2),MongoDB(5.0.0),Memcached(1.6.22)。
- MySQL多版本兼容。
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
php[55,56,71,72,73,74,80,81,82,83]
[redis,memecached,mongo,memcached,yaf,swoole,xhprof,...]
```

- ***MYSQL版本集成***

```
MySQL[50,51,55,56,57,80]
```

### ***phpMyAdmin***

根据选中php版本，自动识别打开版本。需要试用mysql默认以外的版本，需要修改phpMyAdmin相应配置问题。

- 已经通过配置读取
- mysql的用户和密码(root)。
- 默认只有mysql80,其他要通过脚本安装(点击安装),菜单上。

```
默认mysql80 , 端口:3306 | http://localhost:8888/phpMyAdmin/3306
默认mysql57 , 端口:3357 | http://localhost:8888/phpMyAdmin/3357
默认mysql56 , 端口:3356 | http://localhost:8888/phpMyAdmin/3356
默认mysql51 , 端口:3351 | http://localhost:8888/phpMyAdmin/3351

```

### 下载链接

- 5.0[500+MB] - [官方下载](https://github.com/midoks/mdserver-mac/releases/download/5.0/mdserver5.0.arm64.mpkg.zip)

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
菜单[CMD]->brew->install(解决大部分的依赖问题)
菜单[CMD]->php-ext-init->install(解决大部分的依赖问题)

```

### 安装失败

- 安装失败是获取权限脚本没有执行成功,执行下面命令即可:

```
sudo sh /Applications/mdserver/install.sh
```

### 版本版本

- 5.0

```
* mac m2编译(arm64)架构。
* 重新调整php扩展管理方式,减少维护成本。
* 加入PHP83版本。
* 调整了phpmysqladmin访问方式。
```

### 文件目录说明
- host(修改hosts命令)
- mdserver(主功能)
- Screenshot(截图)

### 命令操作说明

- 依赖库(举例)

```
cd /Applications/mdserver/bin/reinstall/cmd/base && bash cmd_pcre.sh
cd /Applications/mdserver/bin/reinstall/cmd/base && bash cmd_zlib.sh
cd /Applications/mdserver/bin/reinstall/cmd/base && bash cmd_gettext.sh
cd /Applications/mdserver/bin/reinstall/cmd/base && bash cmd_openssl.sh
```

- PHP扩展(举例)

```
cd /Applications/mdserver/bin/reinstall/extensions/mbstring && bash install.sh 55
cd /Applications/mdserver/bin/reinstall/extensions/openssl && bash install.sh 71
```

依次类推,方便遇到问题,自己好调试。


### 一般不要动
- 存放超级命令,修改host相关 | /Library/Application\ Support/mdserver 
- 保持host配置相关 | ~/Library/Application\ Support/com.midoks.mdserver/server.plist


### 最新版本截图

[![菜单](/Screenshot/Screenshot_menu.png)](/Screenshot/Screenshot_menu.png)
[![界面](/Screenshot/Screenshot_3.png)](/Screenshot/Screenshot_3.png)



### 联系我
- email:midoks@163.com

### Stargazers over time

[![Stargazers over time](https://starchart.cc/midoks/mdserver-mac.svg)](https://starchart.cc/midoks/mdserver-mac)

### License

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fmidoks%2Fmdserver-mac?ref=badge_shield)