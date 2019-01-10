#!/bin/bash
# \file         dailyGatherLogErrors.sh
# \brief        Counts the number of errors PER DAY in CKAN harvester gather_consumer.log and present.
# \copyright    Copyright (c) 2018, Utrecht University. All rights reserved.


#counts lines containing ERROR per day
sudo -u ckan grep "ERROR" /var/log/ckan/std/gather_consumer.log | cut -c 1-10 | uniq -c
