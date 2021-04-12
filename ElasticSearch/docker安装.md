### 安装



```css
docker run -it --name elasticsearch -d -p 9200:9200 -p 9300:9300 -p 5601:5601 elasticsearch

docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -p 5601:5601  -e "discovery.type=single-node" elasticsearch:latest
```

> 官方的镜像的网络设置是允许外部访问的即`network.host=0.0.0.0`

> 如果要制定es配置可用通过-E{param=value}指定，或者通过`-v "$PWD/config":/usr/share/elasticsearch/config` 映射配置文件地址

> -p 5601:5601 是kibana的端口地址 (我这里kibana的container共用elasticsearch的网络，所以这样设置)

