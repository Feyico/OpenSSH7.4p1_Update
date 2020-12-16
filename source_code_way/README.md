# 目录文件简介

## updateOpenssh7.4p1_code_el7.bin

OpenSSH升级可执行文件，上传至RedHat7.1任意目录下
赋予权限

```chmod 777 updateOpenssh7.4p1_code_el7.bin```

直接执行

```./updateOpenssh7.4p1_code_el7.bin```

## opensshRpm.zip

存放rpm包和python文件的压缩包

## updateOpenssh.sh

执行升级的shell脚本

## createBin.sh

打包脚本，当前目录执行

```./createBin.sh```

即可打出可执行bin包

# 其他
1. updateOpenssh7.4p1_rpm_el7.bin是在Redhat7.1环境下通过createBin.sh脚本生成的可执行bin包，可以直接使用。 
2. 若需要自己生成bin包，可以将opensshRpm.zip、updateOpenssh.sh、createBin.sh三个文件放在同一目录下然后执行 
```./createBin.sh```
