---
title = Example metadata schema
version = 1

[MUST]
title = String
source = String
columns = section
columns.score = String

[OPTIONAL]
version = Int
offset = Int
city = String
empty_field = String

[MUST_NOT]
password = String

[description]
title = Human-readable dataset title
source = Where the file came from
columns = Per-column metadata section
columns.score = Units or meaning of the score column
version = Schema or dataset version
offset = Integer offset used by examples
city = City name encoded as UTF-8 text
empty_field = Empty string metadata value used by examples
password = Secrets must not be stored as file metadata
---
