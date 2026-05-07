---
title = Example metadata schema
version = 1

[MUST]
title = String
source = String
columns = section
columns.score = String

[MAYBE]
version = Int
offset = Int
city = String

[description]
title = Human-readable dataset title
source = Where the file came from
columns = Per-column metadata section
columns.score = Units or meaning of the score column
version = Schema or dataset version
offset = Integer offset used by examples
city = City name encoded as UTF-8 text
---
