#!/bin/bash
# @author tekintian@gmail.com
# rm old container
docker rm -f es-node00
docker rm -f es-node01
docker rm -f es-node02

#del the dsfile
rm -rf $PWD/plugins/.DS_Store

# http://192.168.2.8:9200/_cluster/health
# -p 9200:9200 -p 9300:9300 
# 如果本地磁盘空间使用已经超过85%，/usr/share/elasticsearch/data加载到本地需要重新设置磁盘使用策略，否则数据不可写
# 详见es磁盘分配策略 https://www.elastic.co/guide/en/elasticsearch/reference/6.5/disk-allocator.html
# $PWD/plugins  config 为集群中所有的节点共享的数据
# plugins 为插件
# config/ingest-geoip 这个是geoip数据库，最新的数据库可以从这里下载 https://github.com/P3TERX/GeoLite.mmdb/
# 默认的数据库路径 /usr/share/elasticsearch/config/ingest-geoip
# 
docker run -itd --name es-node00 -p 9200:9200 -p 9300:9300 \
    -v $PWD/node00/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
    -v $PWD/node00/jvm.options:/usr/share/elasticsearch/config/jvm.options \
    -v $PWD/node00/data:/usr/share/elasticsearch/data \
    -v $PWD/node00/logs:/usr/share/elasticsearch/logs \
    -v $PWD/plugins:/usr/share/elasticsearch/plugins \
    -v $PWD/config/ingest-geoip:/usr/share/elasticsearch/config/ingest-geoip \
    elasticsearch:6.5.4

## 关于插件，es6默认加载了 geoip和 user-agent插件，这2个插件如果本地没有，需要先启动es-node00容器，然后执行下面的命令从容器从拷贝出来
# docker cp -a es-node00:/usr/share/elasticsearch/plugins plugins
## IK分词下载安装
# wget -O ik-654.zip https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.5.4/elasticsearch-analysis-ik-6.5.4.zip
# unzip -d plugins/ik ik-654.zip

docker run -itd --name es-node01  -p 9201:9201 -p 9301:9300  \
    -v $PWD/node01/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
    -v $PWD/node01/jvm.options:/usr/share/elasticsearch/config/jvm.options \
    -v $PWD/node01/data:/usr/share/elasticsearch/data \
    -v $PWD/node01/logs:/usr/share/elasticsearch/logs \
    -v $PWD/plugins:/usr/share/elasticsearch/plugins \
    -v $PWD/config/ingest-geoip:/usr/share/elasticsearch/config/ingest-geoip \
    elasticsearch:6.5.4


docker run -itd --name es-node02  -p 9202:9202 -p 9302:9300  \
    -v $PWD/node02/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
    -v $PWD/node02/jvm.options:/usr/share/elasticsearch/config/jvm.options \
    -v $PWD/node02/data:/usr/share/elasticsearch/data \
    -v $PWD/node02/logs:/usr/share/elasticsearch/logs \
    -v $PWD/plugins:/usr/share/elasticsearch/plugins \
    -v $PWD/config/ingest-geoip:/usr/share/elasticsearch/config/ingest-geoip \
    elasticsearch:6.5.4

# docker logs -f es-node00
# docker logs -f es-node01
# docker logs -f es-node02
