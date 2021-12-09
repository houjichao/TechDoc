#### 一、 mvn -U 说明

-U,--update-snapshots Forces a check for missing releases
and updated snapshots on remote repositories

意思是：强制刷新本地仓库不存在release版和所有的snapshots版本。

对于release版本，本地已经存在，则不会重复下载
对于snapshots版本，不管本地是否存在，都会强制刷新，但是刷新并不意味着把jar重新下载一遍。
只下载几个比较小的文件，通过这几个小文件确定本地和远程仓库的版本是否一致，再决定是否下载

#### 二、使用举例

mvn clean install -e -U   -e详细异常,-U强制更新
