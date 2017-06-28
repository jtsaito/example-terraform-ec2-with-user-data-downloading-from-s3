#!/bin/bash
apt-get -y install awscli

sudo -u ubuntu aws s3 cp s3://babbel-jts-test-user-data-2/authorized_keys /home/ubuntu/.ssh/authorized_keys_2
sudo -u ubuntu chmod 600 /home/ubuntu/.ssh/authorized_keys_2
