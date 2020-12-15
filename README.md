# OpenSSH7.4p1_Update
>背景：由于RedHat 7.1自带的openssl、openssh版本过低，安全扫描时被扫出很多漏洞，急需升级至最新版。
同时，以下安装包我都已经开源出来了，想要rpm包和源码包的也可以直接下载bin包然后解压获取，安装包获取链接见文末

[TOC]
## *环境*
*操作系统：Redhat7.1(Centos7.1同理)
升级前的版本：OpenSSH_6.6.1p1, OpenSSL 1.0.1e-fips 11 Feb 2013
计划升级的版本：OpenSSH_7.4p1, OpenSSL 1.0.2k-fips  26 Jan 2017*

## 一、RPM包升级
使用yum在线安装没什么可讲的，主要讲讲离线安装。离线安装主要的难点在于包的寻找，麻烦点可以网上一个一个下。我这边主要使用的是yumdownloader这么一个命令。**顺便提一句，网上很多文章为了保险起见先安装并启用Telnet服务，防止安装失败无法远程远端的服务器，我非常赞赏这种做法。不过我在升级过程中也发现，当前的ssh连接并不会中断，可以正常使用，为了保险起见使用Telnet服务或者直连服务器升级。由于我是直连服务器升级，所以没有安装启用Telnet这一步骤。**

### 1、安装yumdownloader
yumdownloader是什么：
yumdownloader is a program for downloading RPMs from Yum repositories
首先需要一个可以联网并正常使用yum的环境。
安装：
```yum install -y yum-utils```

### 2、下载openssh相关rpm包
```
yumdownloader --destdir /home/ openssh7.4p1
yumdownloader --destdir /home/ openssl1.0.2k
```

### 3、卸载备份
```shell
# 备份原先的配置文件
cp /etc/ssh/ssh_config /home/
cp /etc/ssh/sshd_config /home/
# 卸载原来的openssh和openssl，这步之后无法再连接服务器了
rpm -qa | grep openssl | xargs rpm -e --nodeps
rpm -qa | grep openssh | xargs rpm -e --nodeps
```

### 4、安装升级
进入到相应目录安装所有包即可
```rpm -ivh --force --nodeps /home/*.rpm```
安装完毕使用ssh -V查看一下版本号是否成功，成功后重启sshd服务
```service sshd restart```
再次连接服务器，若连接成功就OK了。

### 5、填坑之旅
原本我以为一切都完事大吉了，结果安装公司项目工程时发现了一个大BUG，yum命令无法使用了，使用yum时出现了以下报错：
```
Traceback (most recent call last):
  File "/usr/bin/yum", line 29, in 
    yummain.user_main(sys.argv[1:], exit_code=True)
  File "/usr/share/yum-cli/yummain.py", line 365, in user_main
    errcode = main(args)
  File "/usr/share/yum-cli/yummain.py", line 271, in main
    return_code = base.doTransaction()
  File "/usr/share/yum-cli/cli.py", line 773, in doTransaction
    resultobject = self.runTransaction(cb=cb)
  File "/usr/lib/python2.7/site-packages/yum/__init__.py", line 1736, in runTransaction
    if self.fssnap.available and ((self.conf.fssnap_automatic_pre or
  File "/usr/lib/python2.7/site-packages/yum/__init__.py", line 1126, in 
    fssnap = property(fget=lambda self: self._getFSsnap(),
  File "/usr/lib/python2.7/site-packages/yum/__init__.py", line 1062, in _getFSsnap
    devices=devices)
  File "/usr/lib/python2.7/site-packages/yum/fssnapshots.py", line 158, in __init__
    self._vgnames = _list_vg_names() if self.available else []
  File "/usr/lib/python2.7/site-packages/yum/fssnapshots.py", line 56, in _list_vg_names
    names = lvm.listVgNames()
lvm.LibLVMError: (0, '')
```
仔细观察发现是lvm模块的问题，rpm安装时确实安装了lvm2的相关安装包，我尝试着去掉lvm2的包后强制安装openssh，发现失败了。
原本我以为是调用的Python库出错了，yum使用的是Python2.7，是否是安装过后链接指向的Python版本有问题了，查看之后发现并没有异常，和正常系统是一致的
```
[root@localhost ~]# ll /usr/bin/python*
lrwxrwxrwx. 1 root root    7 7月  28 17:44 /usr/bin/python -> python2
lrwxrwxrwx. 1 root root    9 7月  28 17:44 /usr/bin/python2 -> python2.7
-rwxr-xr-x. 1 root root 7136 2月  11 2014 /usr/bin/python2.7
```
通过网上查找资料，发现碰到这个问题的同学都是使用了以下方式解决的
```
# 终端依次执行以下命令
yum clean metadata
yum clean all
yum makecache
yum update
# 下面这一步重启服务器特别重要
reboot
```
我尝试后发现确实可以通过以上方式解决这个问题，甚至不需要上面的四步，只需要重启服务器就可以解决，在bug.centos.org网站上提供的解决办法也是这个。但是！我们的系统不允许无故重启服务器，会导致业务中断。
在我寻求其他解决办法甚至采用源码编译升级安装方式之后，我发现错误打印指向的方向几乎都与库文件中Python2.7目录下yum目录下的python文件有关，并且最终的打印，指向的是LibLVMError类，随后打开__init__.py，找到最开始报错的行，发现调用的是fssnapshots，错误打印中同样包含了同名文件，继续深入，发现fssnapshots.py文件中已经包含了lvm包，按理说LibLVMError类应该存在于lvm这个包中。Google了一下，发现programtalk网站上的fssnapshots.py文件比系统中的更详细，并且明确包含了LibLVMError类，而且lvm包中也确实存在LibLVMError类，但是该网站上的[fssnapshots.py文件](python/11282/yum/yum/fssnapshots.py )中在明确import lvm包的情况下，又添加了下述代码
```python
if lvm is not None:
    from lvm import LibLVMError
    class _ResultError(LibLVMError):
        """Exception raised for LVM calls resulting in bad return values."""
        pass
else:
    LibLVMError = None
```
由于还存在其他添加的代码，于是我**将该源码拷贝下来替换掉系统中的/usr/lib/python2.7/site-packages/yum/fssnapshots.py文件**，yum安装测试，发现成功了，没有报错，正常使用，无需重启服务器，完美完成任务。
同时，我对比过升级完成，重启服务器前后的fssnapshots.py文件，发现没有变化（理论上也不应该有区别），至于重启服务器时重启哪些服务修复了该问题没有具体深究。
## 二、源码安装升级
### 1、下载源码包
我使用的版本是zlib-1.2.11.tar.gz、openssl-1.0.2k.tar.gz、openssh-7.4p1.tar.gz，openssl不要使用1.1.0版本的，编译openssh必定报错
```
wget http://zlib.net/zlib-1.2.11.tar.gz
wget https://www.openssl.org/source/openssl-1.0.2k.tar.gz
wget -c http://mirror.mcs.anl.gov/openssh/portable/openssh-7.4p1.tar.gz
```
也可以直接上官网下载。

### 2、安装必要的依赖包
```yum -y install gcc libcap libcap-devel glibc-devel pam-devel  krb5-devel  krb5-libs```
这些包大部分都能在Redhat7.1的光盘中找到，找不到的直接去[网易开源镜像网站对应版块](Index of /centos/7/os/x86_64/Packages)查找。找到后可以直接使用rpm *ivh安装所有包

### 3、编译安装zlib
RedHat 7.1如果没先编译安装最新版的zlib会导致openssh编译时失败报missing zilb的错.

```shell

tar -zxf zlib-1.2.11.tar.gz -C

cd /tmp/zlib-1.2.11

./configure --shared

make

make install

```

### 4、编译安装openssl

```

tar -zxf openssl-1.0.2k.tar.gz

cd openssl-1.0.2k/

./config --prefix=/usr --shared

make

make install

openssl version -a

```



### 5、编译安装openssh

```shell

# 修改ssh私钥权限为0600，RedHat 7.1如果没做这一步会导致升级失败并报错，日志会提示默认权限0640太大，因此需先手动改为0600

chmod 0600 /etc/ssh/ssh_host_ed25519_key

chmod 0600 /etc/ssh/ssh_host_ecdsa_key

chmod 0600 /etc/ssh/ssh_host_rsa_key



tar -zxf openssh-7.4p1.tar.gz

cd openssh-7.4p1/

# RedHat 7.1如果没做这一步，会导致升级完成后可以ssh连接但是无法用密码登录

\cp contrib/redhat/sshd.init /etc/init.d/sshd

\cp contrib/redhat/sshd.pam /etc/pam.d/sshd.pam



./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-zlib --with-ssl-dir=/usr --with-md5-passwords --mandir=/usr/share/man --with-kerberos5=/usr/lib64/libkrb5.so

make

make install



echo "PermitRootLogin yes">>/etc/ssh/sshd_config

echo "Ciphers aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr,3des-cbc,arcfour128,arcfour256,arcfour,blowfish-cbc,cast128-cbc">>/etc/ssh/sshd_config



ssh -V

service sshd restart

```



## One more thing

两种升级方式的安装流程的源码、rpm包、脚本等我都封装成bin包开源出来了，需要可自取
以上bin包只适用于以下版本的环境中
```
[root@localhost yum]# uname -a
Linux localhost.localdomain 3.10.0-229.el7.x86_64 #1 SMP Thu Jan 29 18:37:38 EST 2015 x86_64 x86_64 x86_64 GNU/Linux
```
源码编译没有什么需要特别注意的点，用rpm升级安装的方式更为保险，我推荐使用这个，同时思路大家可以借鉴一下，共同学习交流。
