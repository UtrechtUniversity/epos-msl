#!/bin/bash
# \file         dailyFetchLogErrors.sh
# \brief        Counts the number of errors PER DAY in CKAN harvester fetch_consumer.log and present.
# \copyright    Copyright (c) 2019, Utrecht University. All rights reserved.

#counts lines containing ERROR per day
sudo -u ckan grep "$(date +"%F")" /var/log/ckan/std/fetch_consumer.log | grep -c "ERROR"
