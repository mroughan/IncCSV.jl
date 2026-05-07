---
title = Recovery simulation
source = cluster batch 8
model = queue-v1
run_id = recovery-003
scenario = recovery
version = 2
[columns]
time = discrete time step
value = queue length
status = label
---
time,value,status
0,7,high
1,4,falling
2,2,stable
