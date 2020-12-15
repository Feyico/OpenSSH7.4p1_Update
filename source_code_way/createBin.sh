#!/bin/bash
###
 # @Author: Feyico
 # @Date: 2020-12-15 08:00:00
 # @LastEditors: Feyico
 # @LastEditTime: 2020-12-15 21:20:42
 # @Description: 打包脚本
 # @FilePath: /OpenSSH7.4p1_Update/source_code_way/createBin.sh
### 

echo "Bin files generated."
mylines=`cat updateOpenssh.sh | wc -l`
mylines=$(expr $mylines + 1)
# echo $mylines
sed 's/^lines=/lines='"$mylines"'/' updateOpenssh.sh > updateOpenssh_new.sh

cat ./updateOpenssh_new.sh ./openssh_update_el7.zip >updateOpenssh7.4p1_code_el7.bin
echo "Bin file generation succeeds."
chmod a+x updateOpenssh7.4p1_code_el7.bin
rm -rf updateOpenssh_new.sh
