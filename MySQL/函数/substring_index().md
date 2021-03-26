### 一.substring_index()函数

1. 格式

   ```
   SUBSTRING_INDEX(str, delimiter, number)
   ```

2. 详细解释

   ```tsx
   返回从字符串 str 的第 number 个出现的分隔符 即delimiter 之后的字符串。
   如果 number 是正数，则返回从str左边开始计数的第 number 个delimiter（不包含delimiter）左边的字符串。
   如果 number 是负数，则返回从str右边开始计数的第(number 的绝对值)个delimiter（不包含delimiter）右边的字符串。
   ```

3. demo

   ```
   SELECT SUBSTRING_INDEX('a*b','*',1) -- 结果a
   SELECT SUBSTRING_INDEX('a*b','*',-1)    -- 结果b
   SELECT SUBSTRING_INDEX(SUBSTRING_INDEX('a*b*c*d*e','*',3),'*',-1)    -- 结果c。SUBSTRING_INDEX('a*b*c*d*e','*',3)的结果是a*b*c
   ```

4. Group_concat和substring_index()结合使用

   ```
   CREATE TABLE `index_his_value` (
     `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '主键，自增',
     `object_id` char(34) NOT NULL DEFAULT '' COMMENT '任务标志',
     `index_id` char(34) NOT NULL DEFAULT '' COMMENT '指标标志',
     `value` double NOT NULL DEFAULT '0' COMMENT '历史指标值',
     `create_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '值生成时间',
     PRIMARY KEY (`id`),
     KEY `idx_id` (`object_id`,`index_id`)
   ) ENGINE=InnoDB AUTO_INCREMENT=1996409 DEFAULT CHARSET=utf8 COMMENT='指标历史数据表';
   
   <select id="queryLatestHistory" resultMap="queryLatestHistory">
           select
               index_id, object_id, max(create_at) create_at,
               substring_index(group_concat(`value` order by create_at desc), ",", 1) `value`
           from index_his_value
           <where>
               <foreach collection="list" item="result" open="(" close=")" separator="or">
                   (index_id = #{result.indexId} and object_id = #{result.objectId})
               </foreach>
           </where>
           group by index_id, object_id
       </select>
   ```

   