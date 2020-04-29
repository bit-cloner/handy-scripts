#!/bin/sh

# Storing the vallue of current date in a variable to be used in filename
now=$(date +"%d-%m-%Y")

# Compress contents of all the folders in this workspace
tar -zcvf /home/ec2-user/$now-c9-dump-$C9_PROJECT.tar.gz /home/ec2-user/environment

if [[ -d "/home/ec2-user" ]]
then
  # Compress contents of all the folders in this workspace
  tar -zcvf /home/ec2-user/$now-c9-dump-$C9_PROJECT.tar.gz /home/ec2-user/environment
  #Move compressed file to S3. Make sure aws crednetials are available to this script and aws cli installed
  aws s3 cp --storage-class GLACIER /home/ec2-user/$now-c9-dump-$C9_PROJECT.tar.gz s3://c9-code-dumps || true
  #Delete compressed file after upload to save space on workspace
  rm /home/ec2-user/$now-c9-dump-$C9_PROJECT.tar.gz
 else
  # Compress contents of all the folders in this workspace
  tar -zcvf /home/ubuntu/$now-c9-dump-$C9_PROJECT.tar.gz /home/ubuntu/environment
  #Move compressed file to S3. Make sure aws crednetials are available to this script and aws cli installed
  aws s3 cp --storage-class GLACIER /home/ubuntu/$now-c9-dump-$C9_PROJECT.tar.gz s3://c9-code-dumps || true
  #Delete compressed file after upload to save space on workspace
  rm /home/ubuntu/$now-c9-dump-$C9_PROJECT.tar.gz
fi






