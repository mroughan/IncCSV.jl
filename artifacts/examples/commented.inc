---
# Full-line metadata comments should be ignored.
title = commented data # Inline metadata comments should be ignored.
source = package artifact ; Semicolon metadata comments should also be ignored.
version = 2 # Positive integers should be inferred.
offset = -5 ; Negative integers should be inferred.
string_number = "123" # Quoted integer-like values stay strings.
[columns] # Section comments should be ignored.
score = points
---
name,score
# CSV comments are handled by CSV.jl when comment="#" is passed.
Ada,21
# Comments can appear between data rows.
Babbage,12
Church,14
Dijkstra,15
