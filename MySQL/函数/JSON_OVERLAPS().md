在MySQL中，`JSON_OVERLAPS`函数用于检查两个JSON类型的值是否存在交集。如果存在交集，则返回1，否则返回0。

`JSON_OVERLAPS`函数的语法如下：

```
JSON_OVERLAPS(json_doc1, json_doc2)
```

其中，`json_doc1`和`json_doc2`是两个JSON类型的值。

如果`json_doc1`和`json_doc2`之间存在交集，则返回1；否则返回0。

例如：

```sql
SELECT JSON_OVERLAPS('{"a": 1, "b": 2, "c": 3}', '{"d": 4, "e": 5, "f": 6}');
```

上面的查询将返回0，因为两个JSON对象没有交集。

而`NOT JSON_OVERLAPS`用于检查两个JSON类型的值是否不存在交集。如果不存在交集，则返回1，否则返回0。

例如：

```sql
SELECT NOT JSON_OVERLAPS('{"a": 1, "b": 2, "c": 3}', '{"d": 4, "e": 5, "f": 6}');
```

上面的查询将返回1，因为两个JSON对象没有交集。

总结：`JSON_OVERLAPS`用于检查两个JSON值是否存在交集，而`NOT JSON_OVERLAPS`用于检查两个JSON值是否不存在交集。这两个函数在实际应用中可以帮助我们筛选和处理包含JSON数据的表。



如下sql

```
SELECT c.name,c.cid,c.customerId,l.uin,l.sourcePrimaryTagId,l.sourceSecondaryTagId,l.publicTagIds,l.privateTagIds,l.touchStatus,c.follower,l.leadId,l.phone,l.belongModule,l.status,l.taskId,c.status as customerStatus,l.assignFollower,l.extend FROM tcc.tcc_lead l LEFT JOIN tcc.tcc_customer c  ON c.cid = l.cid and c.belongModule = l.belongModule WHERE l.sourceSecondaryTagId = '277' AND l.batchId IN ('2728','2226','1130','1779','1285') AND l.provinceCode IN ('31') AND NOT JSON_OVERLAPS('["ifc_partner_application","ifc_integrated_cooperaton","ifc_certification_equipment","ifc_tianlai_cooperation","ifc_new_meeting_room","ifc_retrofit_meeting_room"]', l.leadTags) AND l.belongModule = 10 AND l.status = 0 AND c.status = 0;
```

如果`l.leadTags`为`NULL`，那么`JSON_OVERLAPS`函数会返回`NULL`，而不是`0`或`1`，因此该记录将不会被包含在查询结果中。

如果你希望包含`l.leadTags`为`NULL`的记录，可以使用`COALESCE`函数将`NULL`值转换为一个非`NULL`值，例如：

```
SELECT c.name,c.cid,c.customerId,l.uin,l.sourcePrimaryTagId,l.sourceSecondaryTagId,l.publicTagIds,l.privateTagIds,l.touchStatus,c.follower,l.leadId,l.phone,l.belongModule,l.status,l.taskId,c.status as customerStatus,l.assignFollower,l.extend FROM tcc.tcc_lead l LEFT JOIN tcc.tcc_customer c  ON c.cid = l.cid and c.belongModule = l.belongModule WHERE l.sourceSecondaryTagId = '277' AND l.batchId IN ('2728','2226','1130','1779','1285') AND l.provinceCode IN ('31') AND NOT JSON_OVERLAPS('["ifc_partner_application","ifc_integrated_cooperaton","ifc_certification_equipment","ifc_tianlai_cooperation","ifc_new_meeting_room","ifc_retrofit_meeting_room"]', COALESCE(l.leadTags, '[]')) AND l.belongModule = 10 AND l.status = 0 AND c.status = 0;
```

在上面的查询中，如果`l.leadTags`为`NULL`，则使用`COALESCE`函数将其转换为一个空的JSON数组`'[]'`，这样就能够包含`l.leadTags`为`NULL`的记录了。