### mdserver(mac版) FQ
```
mysql 
用户名 root 密码 root
mongoldb
redis
都是默认端口

如果你想自己调试,可以看我的记录:

目录:re2c-0.13.5

cd re2c-0.13.5
./configure && make && make install

安装brew工具
curl -LsSf http://github.com/mxcl/homebrew/tarball/master | sudo tar xvz -C/usr/local --strip 1

brew install openssl
brew install pkg-config
brew install ImageMagick
brew install gettext
brew install icu4c
brew install Graphviz   —-生成xhprof分析时有关
brew install libtool


在安装php imagick扩展遇到很多问题
最终的解决方法:
brew install Imagemagick
sudo brew link imagemagick
在(http://www.imagemagick.org/script/binary-releases.php#macosx)
上下载二进制文件放在cmd目录下
最终编译成功


xhprof使用 在test下
在停止时会对session和xhprof内容清空

wget http://fastdl.mongodb.org/osx/mongodb-osx-ssl-x86_64-3.2.7.tgz

#程序调试
http://localhost:8888/tz.php?mdd=ok
当$GET[‘mdd’]=ok时,会使用xhprof进行分析[php55支持,php70,php71 md_xhprof]
```