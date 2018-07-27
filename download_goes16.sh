#!/bin/bash
 
#########################################
# LICENSE
#Copyright (C) 2012 Dr. Marcial Garbanzo Salas
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.
#########################################
 
#########################################
# AUTHOR
# This program was created at the University of Costa Rica (UCR)
# It is intended as a tool for meteorology students to obtain data from GOES16
# but it can be used by operational and research meteorology.
#########################################
 
#########################################
# Warning: This program can download a LARGE amount of information
# and this can cause problems with limited bandwidth networks or
# computers with low storage capabilities.
#########################################
 
#########################################
# CLEANING FROM PREVIOUS RUNS
#
rm DesiredData.txt
rm FullList.txt
#########################################
 
echo "GOES16 ABI data downloader"
 
#########################################
# CONFIGURATION
#
# YEAR OF INTEREST
YEARS='2018'
 
# DAYS OF THE YEAR
# Can use this link to find out: https://www.esrl.noaa.gov/gmd/grad/neubrew/Calendar.jsp
# Example: 275 for October 2nd, 2017
# NOTE: There is only about 60 days previous to the current date available
DAYS="204"
 
# CHANNELS
# Example: CHANNELS='C01 C02 C03 C04 C05 C06 C07 C08 C09 C10 C11 C12 C13 C14 C15 C16'
CHANNELS='C07'
 
# ABI PRODUCTS
# For a description look into:
# https://aws.amazon.com/public-datasets/goes/
# and
# http://edc.occ-data.org/goes16/getdata/
# Example: PRODUCTS='L1b-RadC L1b-RadF L1b-RadM L2-CMIPC L2-CMIPF L2-CMIPM L2-MCMIPC L2-MCMIPF L2-MCMIPM'
PRODUCTS='L2-CMIPC'
#########################################
 
#########################################
# Get list of remote files available
# PART 1. Obtain full list of files
#
for PRODUCT in $PRODUCTS; do
for YEAR in $YEARS; do
for DAY in $DAYS; do
 
aws s3 --no-sign-request ls --recursive noaa-goes16/ABI-$PRODUCT/$YEAR/$DAY/ | awk '{print $3";"$4}' >> FullList.txt
 
done
done
done
 
#
# PART 2. Select only desired channels
for CHANNEL in $CHANNELS; do
grep $CHANNEL FullList.txt >> DesiredData.txt
done
#########################################
 
#########################################
# DOWNLOAD
#
 
for x in $(cat DesiredData.txt);
do
SIZE=$(echo $x | cut -d";" -f1)
FULLNAME=$(echo $x | cut -d";" -f2)
NAME=$(echo $x | cut -d"/" -f5)
 
echo "Processing file $NAME of size $SIZE"
if [ -f $NAME ]; then
 echo "This file exists locally"
 LOCALSIZE=$(du -sb $NAME | awk '{ print $1 }')
 if [ $LOCALSIZE -ne $SIZE ]; then
 echo "The size of the file is not the same as the remote file. Downloading again..."
 aws s3 --no-sign-request cp s3://noaa-goes16/$FULLNAME ./
 else
 echo "The size of the file matches the remote file. Not downloading it again."
 fi
else
 echo "This file does not exists locally, downloading..."
 aws s3 --no-sign-request cp s3://noaa-goes16/$FULLNAME ./
fi
 
done
#########################################
 
echo Program ending.