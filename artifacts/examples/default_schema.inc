---
# Default informational schema for common INC metadata.
# This schema is intentionally permissive: it documents common fields, but does
# not require them and does not reject project-specific metadata.
[schema]
allow_extra = true

[MAYBE]
# Global terms for finding or understanding a resource.
identifier = IdentifierString
title = String
authors = String
subject = String
publication_date = DateString
creation_date = DateString
description = String
publisher = String

# Long-term management of files.
preservation = section
preservation.language = LanguageString
preservation.source = String
preservation.version = VersionString
preservation.modification_dates = DateListString

# Decoding and rendering the file.
technical = section

# Intellectual property rights and access control.
rights = section
rights.copyright = String
rights.license = LicenseString
rights.rights_holder = String
rights.accessible_to = String

# Information about the file format and CSV parser hints.
structure = section
structure.delim = CharacterString
structure.comment = CharacterString
structure.missingstring = String
structure.dateformat = DateFormatString

# Parameters of code generating the data.
parameters = section

# Statistical qualities of the data, such as sample sizes.
statistical = section

# Data about the process used to generate the data.
process = section

[description]
identifier = Stable identifier for the resource
title = Human-readable title of the resource
authors = People or organisations responsible for authorship
subject = Topic, keywords, or classification terms
publication_date = Date the resource was published or released
creation_date = Date the resource was created
description = Free-text description of the resource
publisher = Person or organisation making the resource available
preservation = Long-term management metadata
preservation.language = Language of the resource metadata or content
preservation.source = Original source or provenance chain for the resource
preservation.version = Version label for the resource
preservation.modification_dates = Modification history encoded as a string
technical = Technical metadata for decoding or rendering the file
rights = Rights, licensing, and access metadata
rights.copyright = Copyright statement
rights.license = License name, SPDX identifier, or license URL
rights.rights_holder = Person or organisation holding rights
rights.accessible_to = Access-control audience or group
structure = CSV component structure and parser hints
structure.delim = Delimiter used by the CSV component
structure.comment = Comment marker used by the CSV component
structure.missingstring = Missing-value marker used by the CSV component
structure.dateformat = Date format hint for the CSV component
parameters = Parameters of code generating the data
statistical = Statistical qualities of the data
process = Process used to generate, transform, or collect the data
---
