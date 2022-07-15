#!/bin/bash
# \file         dailyFetchLogErrors.sh
# \brief        Counts the number of errors PER DAY in CKAN uwsgi logs
# \copyright    Copyright (c) 2019, Utrecht University. All rights reserved.

#counts lines containing ERROR per day
sudo -u ckan grep "$(date +"%F")" /var/log/ckan/ckan-uwsgi.stderr.log | grep -c "ERROR"
