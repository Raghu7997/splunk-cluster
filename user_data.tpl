#!/bin/bash -v
set -x
exec 1> /var/tmp/mylog 2>&1
~/.local/bin/aws configure set default.region ap-south-1

yum update -y
yum install -y sysstat wget curl aws-cli dos2unix jq
cd /home/ec2-user

#======Installation of Splunk=====================
yum install -y telnet htop

# Install Splunk
tgz=splunk-8.0.0-1357bef0a7f6-Linux-x86_64.tgz #define requiered splunk version
wget -O $tgz 'https://www.splunk.com/page/download_track?file=8.0.0/linux/splunk-8.0.0-1357bef0a7f6-Linux-x86_64.tgz&ac=&wget=true&name=wget&platform=Linux&architecture=x86_64&version=8.0.0&product=splunk&typed=release'
tar xvzf $tgz
mkdir -p /opt
cp -R splunk /opt/

#retrive secrets from aws secret manager.
response=$(~/.local/bin/aws secretsmanager get-secret-value --secret-id splunk-admin-secrets)
username=$(echo $response | jq '.SecretString | fromjson'.username | sed 's/"//g')
password=$(echo $response | jq '.SecretString | fromjson'.password | sed 's/"//g')

# Add admin User
touch /opt/splunk/etc/system/local/user-seed.conf
echo -e "[user_info]\nUSERNAME = $username\nPASSWORD = $password" > /opt/splunk/etc/system/local/user-seed.conf


# Create local config files
sudo -u splunk mkdir -p /opt/splunk/etc/system/local
cat <<EOF | sudo -u splunk tee /opt/splunk/etc/system/local/deploymentclient.conf
${deploymentclient_conf_content}
EOF
cat <<EOF | sudo -u splunk tee /opt/splunk/etc/system/local/web.conf
${web_conf_content}
EOF
cat <<EOF | sudo -u splunk tee /opt/splunk/etc/system/local/server.conf
${server_conf_content}
EOF
cat <<EOF | sudo -u splunk tee /opt/splunk/etc/system/local/serverclass.conf
${serverclass_conf_content}
EOF

# Update hostname
hostname splunk-${role}-`hostname`
echo `hostname` > /etc/hostname
sed -i 's/localhost$/localhost '`hostname`'/' /etc/hosts

# Start service and Enable autostart
sudo -u splunk /opt/splunk/bin/splunk enable boot-start -user splunk --accept-license
sudo -u splunk /opt/splunk/bin/splunk start --accept-license

