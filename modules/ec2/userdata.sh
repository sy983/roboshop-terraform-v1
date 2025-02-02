#!/bin/sh
pip3.11 install ansible hvac
ansible-pull -i localhost, -U https://github.com/sy983/roboshop-ansible.git-v1.git main.yml -e env="$(env)" -e role_name="$(role_name)" -e vault_token="$(vault_token)" 2>&1| tee /opt/userdata.log