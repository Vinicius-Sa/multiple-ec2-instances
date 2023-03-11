provider "aws" {
  region = "us-east-1"
}

terraform {

  required_version = "~> 1.2.6"

  required_providers {
    aws  = "~> 3.74.3"
  }

  backend "s3" {
    bucket = "../.."
    key    = "../.."
    region = "us-east-1"
  }
}

################################################################################
# LOCALS. METADA MySql | Web-server  SCRIPT 
################################################################################

locals {
  resource  = "${var.project}-${var.service_name}-${var.environment}"
  log_prefix  = "logs/${var.environment}"
  environment = var.environment
  metadata ={
    mysql = {
      <<eot
#!/bin/bash
TOMURL="https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.37/bin/apache-tomcat-8.5.37.tar.gz"
yum install java-1.8.0-openjdk -y
yum install git maven wget -y
cd /tmp/
wget $TOMURL -O tomcatbin.tar.gz
EXTOUT=`tar xzvf tomcatbin.tar.gz`
TOMDIR=`echo $EXTOUT | cut -d '/' -f1`
useradd --shell /sbin/nologin tomcat
rsync -avzh /tmp/$TOMDIR/ /usr/local/tomcat8/
chown -R tomcat.tomcat /usr/local/tomcat8

rm -rf /etc/systemd/system/tomcat.service

cat <<EOT>> /etc/systemd/system/tomcat.service
[Unit]
Description=Tomcat
After=network.target

[Service]
User=tomcat
WorkingDirectory=/usr/local/tomcat8
Environment=JRE_HOME=/usr/lib/jvm/jre
Environment=JAVA_HOME=/usr/lib/jvm/jre
Environment=CATALINA_HOME=/usr/local/tomcat8
Environment=CATALINE_BASE=/usr/local/tomcat8
ExecStart=/usr/local/tomcat8/bin/catalina.sh run
ExecStop=/usr/local/tomcat8/bin/shutdown.sh
SyslogIdentifier=tomcat-%i

[Install]
WantedBy=multi-user.target
EOT
    }

systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat

git clone -b vp-rem <git.repo>
cd viniciussa-repo
mvn install
systemctl stop tomcat
sleep 120
rm -rf /usr/local/tomcat8/webapps/ROOT*
cp target/viniciussa-v2.war /usr/local/tomcat8/webapps/ROOT.war
systemctl start tomcat
sleep 300
cp /viniciussa-vm-data/application.properties /usr/local/tomcat8/webapps/ROOT/WEB-INF/classes/application.properties
systemctl restart tomcat8

eot
    }
    mysql = {
      <<EOT
#!/bin/bash
DATABASE_PASS='admin123'
sudo yum update -y
sudo yum install epel-release -y
sudo yum install git zip unzip -y
sudo yum install mariadb-server -y


# starting & enabling mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
cd /tmp/
git clone -b vp-rem <git.repo>
#restore the dump file for the application
sudo mysqladmin -u root password "$DATABASE_PASS"
sudo mysql -u root -p"$DATABASE_PASS" -e "UPDATE mysql.user SET Password=PASSWORD('$DATABASE_PASS') WHERE User='root'"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"
sudo mysql -u root -p"$DATABASE_PASS" -e "create database accounts"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'localhost' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "grant all privileges on accounts.* TO 'admin'@'%' identified by 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" accounts < /tmp/viniciussa-repo/src/main/resources/db_backup.sql
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Restart mariadb-server
sudo systemctl restart mariadb


#starting the firewall and allowing the mariadb to access from port no. 3306
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --zone=public --add-port=3306/tcp --permanent
sudo firewall-cmd --reload
sudo systemctl restart mariadb

EOT
    }

  }
  multiple_instances = {
    web = {
      instance_type     = var.instance_type
      availability_zone = element(module.network.aws_all_subnets_az, 0)
      subnet_id         = element(module.network.aws_all_subnets_id_private, 0)
      root_block_device = [
        {
          encrypted   = true
          volume_type = var.volume_type
          throughput  = var.throughput
          volume_size = var.volume_size
          tags = {
            Name = "my-root-block"
          }
        }
      ]
    }
    bastion = {
      instance_type     = var.instance_type
      availability_zone = element(module.network.aws_all_subnets_az, 1)
      subnet_id         = element(module.network.aws_all_subnets_id_private, 1)
      root_block_device = [
        {
          encrypted   = true
          volume_type = var.volume_type
          volume_size = var.volume_size
        }
      ]
    }
  }
  tags = {
    Name        = local.resource
    project     = var.project
    service     = var.service_name
    environment = var.environment
  }
}

################################################################################
# MULTIPLE EC2 INSTANCES 
################################################################################

module "ec2_multiple" {
  source = "./modules/ec2"

  for_each = local.multiple_instances

  user_data_base64            = base64encode(local.user_data)
  user_data_replace_on_change = true

  instance_type          = each.value.instance_type
  availability_zone      = each.value.availability_zone
  subnet_id              = each.value.subnet_id
  vpc_security_group_ids = module.network.all_sg
  associate_public_ip_address = var.associate_public_ip_address
  key_name = var.key_name

  tags = local.tags
}
