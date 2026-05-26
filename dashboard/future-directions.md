# Future Directions Dashboard

重大方向说明不是普通 pending proposal，不进入每周快速晋升流程。真正实施前，应再拆成具体 proposal、设计文档、迁移计划或任务清单。

```dataview
TABLE file.mtime AS updated, type, status, not_directly_promotable
FROM "proposals/future-directions"
SORT file.mtime DESC
```
