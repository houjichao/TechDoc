```
UPDATE topic_template SET deleted = ABS(deleted -1);

UPDATE topic_template SET deleted = (deleted ^ 1);
```