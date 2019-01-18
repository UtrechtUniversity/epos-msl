#!/bin/bash
# \file         dailyGatherLogErrors.sh
# \brief        Counts the number of errors PER DAY in CKAN harvester gather_consumer.log and present.
# \copyright    Copyright (c) 2019, Utrecht University. All rights reserved.

#counts lines containing ERROR per day
sudo -u ckan grep "$(date +"%F")" /var/log/ckan/std/gather_consumer.log | grep -c "ERROR"
