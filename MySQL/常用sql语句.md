### MYSQL查询结果自增序号列

SELECT @num:=@num+1 AS 序号, a.* FROM t_user a ,(SELECT @num:=0) r;

      REPLACE INTO `exponent_calc_model` (
      `id`,
      `biz_id`,
      `created_by`,
      `create_time`,
      `updated_by`,
      `update_time`,
      `biz_type`,
      `calc_standard`,
      `calc_rule`,
      `calc_formula`,
      `calc_relations`)
    
      SELECT @num:=@num+1 as id ,a.ID as biz_id ,user_name as created_by ,update_at as create_time,user_name as updated_by ,
      update_at as update_time,3 as biz_type, 1 as calc_standard, 1 as calc_rule, '' as calc_formula, '' as calc_relations
      FROM tb_object a , (SELECT @num:=19999999999999) as b where a.parent_object_id != '0' and a.deleted = 0;
### 查询uuid

```
SELECT REPLACE(UUID(), '-', '');
```

```
SELECT
	b.id AS id,
	a.ID AS biz_id,
	user_name AS created_by,
	update_at AS create_time,
	user_name AS updated_by,
	update_at AS update_time,
	3 AS biz_type,
	1 AS calc_standard,
	1 AS calc_rule,
	'' AS calc_formula,
	'' AS calc_relations 
FROM
	tb_object a,
	( SELECT REPLACE ( UUID(), '-', '' ) AS id ) AS b 
WHERE
	a.parent_object_id != '0' 
	AND a.deleted = 0;
```

