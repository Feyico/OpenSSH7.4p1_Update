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

lines=
update_dir=`pwd`
dir_tmp=/tmp
echo "Extract bin files."
tail -n +$lines $0 >$dir_tmp/openssh_update_el7.zip
cd $dir_tmp
unzip -o openssh_update_el7.zip
echo "Bin file extracting completes."

openssh_update_dir=$dir_tmp/openssh_update
rpmfile=$dir_tmp/openssh_update/rpm

sshVer=$(ssh -V 2>&1 | sed 's/,.*$//g')
if [[ $sshVer == "OpenSSH_7.4p1" ]]; then
    echo "OpenSSH Ver is already update to 7.4p1"
    exit 0
fi

echo -e "backup config file..."
\cp /etc/ssh/sshd_config $openssh_update_dir/sshd_config_bak

echo -e "remove old version openssh and openssl..."

rpm -qa | grep openssl | xargs rpm -e --nodeps
rpm -qa | grep openssh | xargs rpm -e --nodeps

echo " "
echo "-------1.Compile zlib-------"
echo " "
cd $openssh_update_dir
echo "install some necessary rpm package..."
rpm -ivh $rpmfile/libcap-2.22-8.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/libcap-devel-2.22-8.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/pam-1.1.8-12.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/pam-devel-1.1.8-12.el7.x86_64.rpm --force --nodeps
tar -zxf zlib-1.2.11.tar.gz
cd zlib-1.2.11/
echo " "
echo "create coding files, please wait moment..."
./configure --shared >> /$update_dir/openssh_update.log
echo " "
echo "make and install, please wait moment..."
`make >> /$update_dir/openssh_update.log 2>&1` && make install >> /$update_dir/openssh_update.log 2>&1
echo " "
echo "-------1.zlib end-------"

echo " "
echo "-------2.Compile openssl-------"
echo " "

cd $openssh_update_dir
tar -zxf openssl-1.0.2k.tar.gz
cd openssl-1.0.2k/
echo "create coding files, please wait moment..."
./config --prefix=/usr --shared >> /$update_dir/openssh_update.log
echo " "
echo "make and install, please wait moment..."
make >> /$update_dir/openssh_update.log 2>&1
make install >> /$update_dir/openssh_update.log 2>&1

openssl version -a
echo " "
echo "-------2.openssl end-------"

echo " "
echo "-------3.Compile openssh-------"
echo " "

chmod 0600 /etc/ssh/ssh_host_ed25519_key
chmod 0600 /etc/ssh/ssh_host_ecdsa_key
chmod 0600 /etc/ssh/ssh_host_rsa_key

cd $openssh_update_dir
tar -zxf openssh-7.4p1.tar.gz
cd openssh-7.4p1/

echo "copy config files..."
\cp contrib/redhat/sshd.init /etc/init.d/sshd
\cp contrib/redhat/sshd.pam /etc/pam.d/sshd.pam

echo "install some necessary rpm package..."
rpm -ivh $rpmfile/pcre-8.32-14.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/pcre-devel-8.32-14.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/libcom_err-devel-1.42.9-7.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/libsepol-devel-2.1.9-3.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/libselinux-devel-2.2.2-6.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/libverto-devel-0.2.5-4.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/keyutils-libs-devel-1.5.8-3.el7.x86_64.rpm --force --nodeps
rpm -ivh $rpmfile/krb5-devel-1.12.2-14.el7.x86_64.rpm --force --nodeps

echo " "
echo "create coding files, please wait moment..."
./configure --prefix=/usr --sysconfdir=/etc/ssh --with-pam --with-zlib --with-ssl-dir=/usr --with-md5-passwords --mandir=/usr/share/man --with-kerberos5=/usr/lib64/libkrb5.so >> /$update_dir/openssh_update.log
echo " "
echo "make and install, please wait moment..."
make >> /$update_dir/openssh_update.log 2>&1
make install >> /$update_dir/openssh_update.log 2>&1
sshd -V

echo " "
echo "config sshd_config file..."
mv -f $openssh_update_dir/sshd_config_bak /etc/ssh/sshd_config 

echo "PermitRootLogin yes">>/etc/ssh/sshd_config
echo "Ciphers aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr,3des-cbc,arcfour128,arcfour256,arcfour,blowfish-cbc,cast128-cbc">>/etc/ssh/sshd_config

echo " "
echo "-------3.openssh end-------"

sshVer=$(ssh -V 2>&1 | sed 's/,.*$//g')
if [[ $sshVer == "OpenSSH_7.4p1" ]]; then
    echo -e "Update SUCCESS!"
    service sshd restart
else
    echo -e "Update Failed!! Please communit R & D personnel!!"
fi

exit 0
