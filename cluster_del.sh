#!/bin/bash
# @author tekintian@gmail.com
# rm old container
docker rm -f es-node00
docker rm -f es-node01
docker rm -f es-node02

#del the dsfile
rm -rf $PWD/plugins/.DS_Store

# 
# 清理容器留下的数据和日志
# 
rm -rf $PWD/node00/data
rm -rf $PWD/node00/logs

rm -rf $PWD/node01/data
rm -rf $PWD/node01/logs

rm -rf $PWD/node02/data
rm -rf $PWD/node02/logs

