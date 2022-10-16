#!/bin/bash
# @author tekintian@gmail.com
# rm old container
docker rm -f elasticsearch6

#del the dsfile
#rm -rf $PWD/plugins/.DS_Store

# 启动elasticsearch
docker run -itd --name elasticsearch6 -p 9200:9200 -p 9300:9300 \
	-v $PWD/single/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml \
	-v $PWD/single/jvm.options:/usr/share/elasticsearch/config/jvm.options \
	-v $PWD/single/data:/usr/share/elasticsearch/data \
	-v $PWD/single/logs:/usr/share/elasticsearch/logs \
	-v $PWD/plugins:/usr/share/elasticsearch/plugins \
	-v $PWD/config/ingest-geoip:/usr/share/elasticsearch/config/ingest-geoip \
	-e "discovery.type=single-node" \
	elasticsearch:6.5.4

# check the es logs
# docker logs -f elasticsearch6
# check es health 
# http://127.0.0.1:9200/_cluster/health

