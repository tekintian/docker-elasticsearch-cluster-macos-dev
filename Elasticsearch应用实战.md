# Elasticsearch应用实战


## 将数据导入到Elasticsearch

### 安装插件
es插件的安装很简单，将下载的插件加压到es容器的 /usr/share/elasticsearch/plugins 目录中即可

- IK分词器， pinyin插件安装

~~~sh
cd /usr/share/elasticsearch/plugins
##IK分词下载安装
wget -O ik-654.zip https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v6.5.4/elasticsearch-analysis-ik-6.5.4.zip
unzip -d ik ik-654.zip # 解压ik-654.zip到plugins/ik文件夹

wget -O pinyin-654.zip https://github.com/medcl/elasticsearch-analysis-pinyin/releases/download/v6.5.4/elasticsearch-analysis-pinyin-6.5.4.zip
unzip -d pinyin pinyin-654.zip # 解压pinyin-654.zip到plugins/pinyin文件夹

# 清理不需要的文件
rm -rf *.zip
~~~



- 测试:

~~~sh
POST {{url}}/_analyze
{
    "analyzer": "ik_max_word",
    "text": "我是中国人"
}
~~~



### 创建文档mapping

~~~sh
PUT http://192.168.2.8:9200/haoke/
{
    "settings": {
        "index": {
            "number_of_shards": 6,
            "number_of_replicas": 1,
            "analysis": {
                "analyzer": {
                    "pinyin_analyzer": {
                        "tokenizer": "my_pinyin"
                    }
                },
                "tokenizer": {
                    "my_pinyin": {
                        "type": "pinyin",
                        "keep_separate_first_letter": false,
                        "keep_full_pinyin": true,
                        "keep_original": true,
                        "limit_first_letter_length": 16,
                        "lowercase": true,
                        "remove_duplicated_term": true
                    }
                }
            }
        }
    },
    "mappings": {
        "house": {
            "dynamic": false,
            "properties": {
                "title": {
                    "type": "text",
                    "analyzer": "ik_max_word",
                    "fields": {
                        "pinyin": {
                            "type": "text",
                            "analyzer": "pinyin_analyzer"
                        }
                    }
                },
                "image": {
                    "type": "keyword",
                    "index": false
                },
                "orientation": {
                    "type": "keyword",
                    "index": false
                },
                "houseType": {
                    "type": "keyword",
                    "index": false
                },
                "rentMethod": {
                    "type": "keyword",
                    "index": false
                },
                "time": {
                    "type": "keyword",
                    "index": false
                },
                "rent": {
                    "type": "keyword",
                    "index": false
                },
                "floor": {
                    "type": "keyword",
                    "index": false
                }
            }
        }
    }
}


~~~



说明:

**dynamic**

 - dynamic 参数来控制字段的新增
 - true:默认值，表示允许选自动新增字段 
 - false:不允许自动新增字段，但是文档可以正常写入，但无法对字段进行查询等操作 
 - strict:严格模式，文档不能写入，报错

**index** 

index参数作用是控制当前字段是否被索引，默认为true，false表示不记录，即不可被搜索。



被设置为index为false的字段不能进行搜索操作。



### 插入测试数据:

~~~sh
POST {{url}}/haoke/house
{
    "image": "SH1692508563617873920.jpg",
    "orientation": "55.00㎡",
    "houseType": "2室1厅1卫",
    "rentMethod": "整租",
    "time": "随时可看",
    "title": "地铁口 整租·清涧二街坊 2室1厅 南 ",
    "rent": "5300",
    "floor": "低楼层/6层",
    "url": "https://sh.lianjia.com/zufang/SH1692508563617873920.html"
}
~~~



搜索测试

~~~sh
POST {{url}}/haoke/house/_search
{
    "query": {
        "match": {
            "title": {
                "query": "地铁"
            }
        }
    },
    "highlight": {
        "fields": {
            "title": {}
        }
    }
}
~~~



- java ES批量插入数据测试

~~~java
/**
     * Es批量插入数据
     *
     * @throws Exception
     */
    @Test
    public void testEsBulkSave() throws Exception {
        Request request = new Request("POST", "/haoke/house/_bulk");

        StringBuilder sb = new StringBuilder();
        String createStr = "{\"index\":{\"_index\":\"haoke\"," +
                "\"_type\":\"house\"}}";
        List<String> lines = FileUtils.readLines(new File("code/data.json"), 
                "UTF-8");

        int count = 0;
        for (String line : lines) {

            sb.append(createStr + "\n");
            sb.append(line + "\n");

            if (count >= 200) {

                request.setJsonEntity(sb.toString());
                this.restClient.performRequest(request);

                count = 0;
                sb = new StringBuilder();
            }

            count++;

        }

        if (!sb.toString().isEmpty()) {
            request.setJsonEntity(sb.toString());
            this.restClient.performRequest(request);
        }

    }

~~~



- 查询测试

~~~sh
POST {{url}}/haoke/house/_search
{
    "query": {
        "match": {
            "title": {
                "query": "君誉江畔"
            }
        }
    },
    "highlight": {
        "fields": {
            "title": {}
        }
    }
}
~~~



## 开发搜索接口

依赖 这里使用data ，通信端口 9300

~~~xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-data-elasticsearch</artifactId>
</dependency>
~~~



application.yml

~~~yml
spring:
  application: 
    name: docker-elasticsearch
  data: 
    elasticsearch: 
      cluster-name: docker-cluster
      cluster-nodes: 192.168.2.8:9300,192.168.2.8:9301,192.168.2.8:9302

~~~



- vo

**HouseData.java**

~~~java
package cn.tekin.es.vo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.elasticsearch.annotations.Document;
/**
 * @author tekintian@gmail.com
 * @version v0.0.1
 * @since v0.0.1 2022-10-16 17:37
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
@Document(indexName = "myindex", type = "house", createIndex = false)
public class HouseData {
    @Id
    private String id;
    private String title;
    private String rent;
    private String floor;
    private String image;
    private String orientation;
    private String houseType;
    private String rentMethod;
    private String time;
}
~~~



**SearchResult.java**

```java
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * @author tekintian@gmail.com
 * @version v0.0.1
 * @since v0.0.1 2022-10-16 17:37
 */
@Data
@AllArgsConstructor
@NoArgsConstructor
public class SearchResult {
    private Integer totalPage;
    private List<HouseData> list;
}

```



**SearchService.java**

~~~java
package cn.tekin.es.service;
import cn.tekin.es.mapper.MySearchMapper;
import cn.tekin.es.vo.HouseData;
import cn.tekin.es.vo.SearchResult;
import org.elasticsearch.index.query.MatchQueryBuilder;
import org.elasticsearch.index.query.Operator;
import org.elasticsearch.index.query.QueryBuilders;
import org.elasticsearch.search.fetch.subphase.highlight.HighlightBuilder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.elasticsearch.core.ElasticsearchTemplate;
import org.springframework.data.elasticsearch.core.aggregation.AggregatedPage;
import org.springframework.data.elasticsearch.core.query.NativeSearchQueryBuilder;
import org.springframework.data.elasticsearch.core.query.SearchQuery;

import org.springframework.stereotype.Service;
/**
 * @author tekintian@gmail.com
 * @version v0.0.1
 * @since v0.0.1 2022-10-16 17:40
 */
@Service
public class SearchService {
    @Autowired
    private ElasticsearchTemplate elasticsearchTemplate;
    public static final Integer ROWS = 10;
    public SearchResult search(String keyWord, Integer page) {
        //设置分页参数
        PageRequest pageRequest = PageRequest.of(page - 1, ROWS);

        //查询参数创建，这里以 title作为查询条件，多个词之间的关系 and
        MatchQueryBuilder query =
                QueryBuilders.matchQuery("title", keyWord).operator(Operator.AND);
        // 设置高亮
        HighlightBuilder.Field hlField = new HighlightBuilder.Field("title");
        //创建查询
        SearchQuery searchQuery = new NativeSearchQueryBuilder()
                .withQuery(query)
                .withPageable(pageRequest)
                .withHighlightFields(hlField)
                .build();


        //高亮mapper
        MySearchMapper searchMapper = new MySearchMapper();
        //页面聚合
        AggregatedPage<HouseData> housePage=
                this.elasticsearchTemplate.queryForPage(searchQuery, HouseData.class,searchMapper);

        return new SearchResult(housePage.getTotalPages(), housePage.getContent());
    }
}

~~~



**MySearchMapper.java**

```java
package cn.tekin.es.mapper;

import org.apache.commons.lang3.reflect.FieldUtils;
import org.elasticsearch.action.search.SearchResponse;
import org.elasticsearch.common.text.Text;
import org.elasticsearch.search.SearchHit;
import org.elasticsearch.search.fetch.subphase.highlight.HighlightField;
import org.springframework.cglib.core.ReflectUtils;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.core.SearchResultMapper;
import org.springframework.data.elasticsearch.core.aggregation.AggregatedPage;
import org.springframework.data.elasticsearch.core.aggregation.impl.AggregatedPageImpl;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * ES高亮搜索Mapper
 * @author tekintian@gmail.com
 * @version v0.0.1
 * @since v0.0.1 2022-10-16 18:19
 */
public class MySearchMapper implements SearchResultMapper {
    @Override
    public <T> AggregatedPage<T> mapResults(SearchResponse response,
                                            Class<T> clazz, Pageable pageable) {

        //如果数据为空
        if (response.getHits().totalHits == 0) {
            //返回空对象
            return new AggregatedPageImpl<>(Collections.emptyList(), pageable
                    , 0L);
        }
        //有数据
        List<T> list = new ArrayList<>();
        for (SearchHit searchHit : response.getHits()) {
            // 通过反射写入数据到对象中
            T obj = (T) ReflectUtils.newInstance(clazz);

            //获取ID数据并写入到对象中
            try {
                FieldUtils.writeField(obj, "id", searchHit.getId(), true);
            } catch (IllegalAccessException e) {
                e.printStackTrace();
            }

            //非高亮数据的写入操作
            for (Map.Entry<String, Object> entry :
                    searchHit.getSourceAsMap().entrySet()) {
                Field field = FieldUtils.getField(clazz, entry.getKey(), true);
                if (field == null) {
                    continue;
                }
                try {
                    FieldUtils.writeField(obj, entry.getKey(),
                            entry.getValue(), true);

                } catch (IllegalAccessException e) {
                    e.printStackTrace();
                }
            }

            //高亮字段处理
            for (Map.Entry<String, HighlightField> entry :
                    searchHit.getHighlightFields().entrySet()) {
                StringBuilder sb = new StringBuilder();
                Text[] fragments = entry.getValue().getFragments();
                for (Text fragment : fragments) {
                    sb.append(fragment);
                }

                //写入高亮内容
                try {
                    FieldUtils.writeField(obj, entry.getKey(), sb.toString(),
                            true);

                } catch (IllegalAccessException e) {
                    e.printStackTrace();
                }
            }
            list.add(obj);
        }

        return new AggregatedPageImpl<>(list, pageable, response.getHits().totalHits);
    }
}

```



**SearchController.java**

~~~java
package cn.tekin.es.constroller;

import cn.tekin.es.service.SearchService;
import cn.tekin.es.vo.SearchResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

/**
 * @author tekintian@gmail.com
 * @version v0.0.1
 * @since v0.0.1 2022-10-16 17:38
 */
@RequestMapping("/search")
@RestController
@CrossOrigin
public class SearchController {

    @Autowired
    private SearchService searchService;

    @GetMapping
    public SearchResult search(@RequestParam("keyWord") String keyWord,
                               @RequestParam(value = "page", defaultValue = "1")
                                       Integer page) {
        //防止取过多的数据造成ES资源浪费，所以这里设置了最多100页
        if (page > 100) {
            page = 1;
        }
        return this.searchService.search(keyWord, page);
    }
}

~~~





## API测试

http://127.0.0.1:8080/search?keyWord=%E6%B5%A6%E4%B8%9C&page=1





