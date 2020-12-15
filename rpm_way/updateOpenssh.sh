#!/bin/bash
###
 # @Author: Feyico
 # @Date: 2020-12-15 08:00:00
 # @LastEditors: Feyico
 # @LastEditTime: 2020-12-15 21:10:41
 # @Description: 升级脚本
 # @FilePath: /OpenSSH7.4p1_Update/rpm_way/updateOpenssh.sh
### 

echo -e " "
echo -e "***********************************"
echo -e "***** UPDATE TO OPENSSH_V7.4 ******"
echo -e "***********************************"
echo -e "Copyright(C) 2020, Feyico"
echo -e " "

sshVer=$(ssh -V 2>&1 | sed 's/,.*$//g')

if [[ $sshVer == "OpenSSH_7.4p1" ]]; then
    echo "OpenSSH Ver is already update to 7.4p1"
    echo "Do you want to overlay installation? (y/n)"
    read input
    selected=${input:n}
    if [[ $selected != "y" ]]; then
        exit 0
    fi
fi

lines=
install_dir=`pwd`
bak_path=$install_dir/sshfile_bakcup

echo "Extract bin files."
tail -n +$lines $0 >opensshRpm.zip
unzip -o opensshRpm.zip
echo "Bin file extracting completes."

echo "backup some files..."

if [[ ! -d $install_dir/sshfile_bakcup ]]; then
    mkdir $install_dir/sshfile_bakcup
fi

if [[ -f /usr/lib/python2.7/site-packages/yum/fssnapshots.py ]]; then
    \cp /usr/lib/python2.7/site-packages/yum/fssnapshots.py $bak_path/fssnapshots_bak.py
fi

if [[ -f /etc/ssh/sshd_config ]]; then
    \cp /etc/ssh/sshd_config $bak_path/sshd_config_bak
fi

echo -e "remove old version openssh and openssl..."

rpm -qa | grep openssl | xargs rpm -e --nodeps
rpm -qa | grep openssh | xargs rpm -e --nodeps

cd opensshRpm

rpm -ivh *.rpm --force --nodeps

echo "config files..."
\cp ./fssnapshots.py /usr/lib/python2.7/site-packages/yum/

echo "recover sshd_config..."
if [[ -f $bak_path/sshd_config_bak ]]; then
    \cp $bak_path/sshd_config_bak /etc/ssh/
fi

sshVer=$(ssh -V 2>&1 | sed 's/,.*$//g')
if [[ $sshVer == "OpenSSH_7.4p1" ]]; then
    echo -e "Update SUCCESS!"
    service sshd restart
else
    echo -e "Update Failed!!"
fi

cd ..
rm -rf opensshRpm*

exit 0
