#!/bin/sh
timestamp=$(date "+%d%m%Y-%H%M%S")
name="tanmaya"
s3_bucket_name="upgrad-tanmaya"

sudo apt update -y

result=$(dpkg -l | grep apache2)
if [ -z "$result" ]; then
	echo "Installing Apache2"
 	sudo apt install apache2 -y
else 
	echo "Äpchec2 already installed"
fi

apache2_state=$(systemctl --state=running | grep "apache2")
if [ -z $apache2_state ]; then
	service apache2 start
else
	echo "Apache2 service is running"
fi

apache2_service_enabled=$(systemctl is-enabled apache2.service)
echo $apache2_service_enabled
if [ $apache2_service_enabled = "disabled" ]; then
	echo "ënabling apache2 service"
	systemctl enable apache2.service
else
	echo "Äpche2 service is enabled"
fi


timestamp=$(date '+%d%m%Y-%H%M%S')
filename=${name}-httpd-logs-${timestamp}.tar
echo $filename

echo "Generating tar file"
tar -cvf /tmp/${filename} /var/log/apache2/*.log

echo "Installing AWS CLI"
sudo apt install awscli -y

echo "Copying tar file to aws s3"
aws s3 cp /tmp/${filename} s3://${s3_bucket_name}/${filename}

inventory_file=/var/www/html/inventory.html
if [ -f ${inventory_file} ]; then
	echo "${inventory_file} exists"
else
	echo "Creating inventory.html"
	touch ${inventory_file}
	echo "Log Type      Time Created      Type    Size" >>${inventory_file}
fi

filesize=$(ls -lh /tmp/${filename} | awk '{print $5}')
echo "httpd-logs    ${timestamp}   tar     ${filesize}" >> ${inventory_file}

cronfile=/etc/cron.d/automation
if [ -f ${cronfile} ] ; then
	echo "cron file exists"
else
	echo "creating cron file"
       	touch ${cronfile}
	echo "59 16 * * * root /root/Automation_Project/automation.sh" >> ${cronfile}
fi
