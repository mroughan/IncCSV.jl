---
# Informational schema for loosely coordinated field notes.
# Nothing is mandatory; these descriptors document terms that some files use.
[OPTIONAL]
title = String
source = String
observer = PersonName
city = UTF8String
created = DateString: yyyy-mm-dd
method = FreeTextString
columns = section
columns.site = SiteIdentifier
columns.count = IntegerLikeString
columns.note = FreeTextString

[description]
observer = Person who recorded the observation
created = Collection date encoded as a string
method = Short description of collection method
columns = Optional per-column metadata section
columns.site = Site or location identifier
columns.count = Count column if present
columns.note = Free-text note column
---
