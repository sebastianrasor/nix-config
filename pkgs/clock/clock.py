#!/usr/bin/env python3

import time

def print_time(hour, minute):
    pm = hour >= 12
    if hour > 12:
        hour -= 12
    elif hour == 0:
        hour = 12

    print(f"{hour}:{minute:02} {'PM' if pm else 'AM'}", flush=True)

local_time = time.localtime()
print_time(local_time.tm_hour, local_time.tm_min)

while True:
    local_time = time.localtime()
    hour = local_time.tm_hour
    minute = local_time.tm_min + 1
    time.sleep((60_000_000_000 - (time.time_ns() % 60_000_000_000)) / 1_000_000_000)
    print_time(hour, minute)
    time.sleep(15)
