#!/bin/bash
# \file dailyFetchLogErrors.sh
# \brief        Counts the number of errors PER DAY in CKAN harvester fetch_consumer.log and present.
# \copyright    Copyright (c) 2018, Utrecht University. All rights reserved.


#counts lines containing ERROR per day
sudo -u ckan grep "ERROR" /var/log/ckan/std/fetch_consumer.log | cut -c 1-10 | uniq -c
