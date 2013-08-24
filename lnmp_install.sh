#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# Blog:  http://blog.linuxeye.com
#
# Version: 0.2 21-Aug-2013 lj2007331 AT gmail.com
# Notes: LNMP for CentOS/RadHat 5+ and Ubuntu 12+ 
#
# This script's project home is:
#       https://github.com/lj2007331/lnmp

# Check if user is root
[ $(id -u) != "0" ] && echo "Error: You must be root to run this script, Please use root to install lnmp" && kill -9 $$

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

echo "#######################################################################"
echo "#            LNMP for CentOS/RadHat 5+ and Ubuntu 12+                 #"
echo "# For more information Please visit http://blog.linuxeye.com/31.html  #"
echo "#######################################################################"
echo ''

#get pwd
sed -i "s@^lnmp_dir.*@lnmp_dir=`pwd`@" options.conf


# get ipv4 
. functions/get_ipv4.sh

# Definition Directory
. ./options.conf
mkdir -p $home_dir/default $wwwlogs_dir $lnmp_dir/{src,conf}

# choice database 
if [ ! -d "$db_install_dir" ];then
        while :
        do
                read -p "Do you want to install MySQL or MariaDB ? ( MySQL / MariaDB ) " Choice_DB
                choice_db=`echo $Choice_DB | tr [A-Z] [a-z]`
                if [ "$choice_db" != 'mariadb' ] && [ "$choice_db" != 'mysql' ];then
                        echo -e "\033[31minput error! Please input 'MySQL' or 'MariaDB'\033[0m"
                else
                        while :
                        do
                                read -p "Please input the root password of $Choice_DB:" dbrootpwd
                                (( ${#dbrootpwd} >= 5 )) && sed -i "s@^dbrootpwd.*@dbrootpwd=$dbrootpwd@" options.conf && break || echo -e "\033[31m$Choice_DB root password least 5 characters! \033[0m"
                        done
                        break
                fi
        done
fi

# check Pureftpd
if [ ! -d "$pureftpd_install_dir" ];then
while :
do
        read -p "Do you want to install Pure-FTPd? (y/n)" FTP_yn
        if [ "$FTP_yn" != 'y' ] && [ "$FTP_yn" != 'n' ];then
                echo -e "\033[31minput error! Please input 'y' or 'n'\033[0m"
        else
        if [ "$FTP_yn" == 'y' ];then
                while :
                do
                        read -p "Please input the manager password of Pureftpd:" ftpmanagerpwd
                        (( ${#ftpmanagerpwd} >= 5 )) && sed -i "s@^ftpmanagerpwd.*@ftpmanagerpwd=$ftpmanagerpwd@" options.conf && break || echo -e "\033[31mFtp manager password least 5 characters! \033[0m"
                done
        fi
        break
        fi
done
fi

# check phpMyAdmin
if [ ! -d "$wwwroot/default/phpMyAdmin" ];then
while :
do
        read -p "Do you want to install phpMyAdmin? (y/n)" phpMyAdmin_yn
        if [ "$phpMyAdmin_yn" != 'y' ] && [ "$phpMyAdmin_yn" != 'n' ];then
                echo -e "\033[31minput error! Please input 'y' or 'n'\033[0m"
        else
                break
        fi
done
fi

# check redis
if [ ! -d "$redis_install_dir" ];then
	while :
	do
		read -p "Do you want to install Redis? (y/n)" redis_yn
		if [ "$redis_yn" != 'y' ] && [ "$redis_yn" != 'n' ];then
	                echo -e "\033[31minput error! Please input 'y' or 'n'\033[0m"
		else
			break
		fi
	done
fi

# check memcache
if [ ! -d "$memcached_install_dir" ];then
        while :
        do
                read -p "Do you want to install Memcache? (y/n)" memcache_yn
                if [ "$memcache_yn" != 'y' ] && [ "$memcache_yn" != 'n' ];then
                        echo -e "\033[31minput error! Please input 'y' or 'n'\033[0m"
                else
                        break
                fi
        done
fi

# check ngx_pagespeed
while :
do
        read -p "Do you want to install ngx_pagespeed? (y/n)" ngx_pagespeed_yn
        if [ "$ngx_pagespeed_yn" != 'y' ] && [ "$ngx_pagespeed_yn" != 'n' ];then
                echo -e "\033[31minput error! Please input 'y' or 'n'\033[0m"
        else
                break
        fi
done

chmod +x functions/*.sh init/* *.sh

# init
. functions/check_os.sh
OS_CentOS='init/init_CentOS.sh 2>&1 | tee -a lnmp_install.log \n
/bin/mv init/init_CentOS.sh init/init_CentOS.ed'
OS_Ubuntu='init/init_Ubuntu.sh 2>&1 | tee -a lnmp_install.log \n
/bin/mv init/init_Ubuntu.sh init/init_Ubuntu.ed'
OS_command

if [ "$choice_db" == 'mysql' ];then
	cd $lnmp_dir
	. functions/mysql.sh 
	Install_MySQL 2>&1 | tee -a $lnmp_dir/lnmp_install.log 
	db_install_dir=$mysql_install_dir
	sed -i "s@^db_install_dir.*@db_install_dir=$mysql_install_dir@" options.conf
	sed -i "s@^db_data_dir.*@db_data_dir=$mysql_data_dir@" options.conf
fi
if [ "$choice_db" == 'mariadb' ];then
	cd $lnmp_dir
	. functions/mariadb.sh
	Install_MariaDB 2>&1 | tee -a $lnmp_dir/lnmp_install.log 
	db_install_dir=$mariadb_install_dir
	sed -i "s@^db_install_dir.*@db_install_dir=$mariadb_install_dir@" options.conf
	sed -i "s@^db_data_dir.*@db_data_dir=$mariadb_data_dir@" options.conf
fi

if [ ! -d "$php_install_dir" ];then
	. functions/php.sh
	Install_PHP 2>&1 | tee -a $lnmp_dir/lnmp_install.log 
fi

if [ ! -d "$nginx_install_dir" ];then
	. functions/nginx.sh
	Install_Nginx 2>&1 | tee -a $lnmp_dir/lnmp_install.log 
	sed -i "s@/usr/local/nginx@$nginx_install_dir@g" vhost.sh
	sed -i "s@/home/wwwroot@$home_dir@g" vhost.sh
	sed -i "s@/home/wwwlogs@$wwwlogs_dir@g" vhost.sh
fi

if [ "$FTP_yn" == 'y' ];then
	. functions/pureftpd.sh
	Install_Pureftpd 2>&1 | tee -a $lnmp_dir/lnmp_install.log 
fi

if [ "$phpMyAdmin_yn" == 'y' ];then
	. functions/phpmyadmin.sh
	Install_phpMyAdmin 2>&1 | tee -a $lnmp_dir/lnmp_install.log
fi

if [ "$redis_yn" == 'y' ];then
	. functions/redis.sh
	Install_Redis 2>&1 | tee -a $lnmp_dir/lnmp_install.log
fi

if [ "$memcache_yn" == 'y' ];then
	. functions/memcache.sh
	Install_Memcache 2>&1 | tee -a $lnmp_dir/lnmp_install.log
fi

if [ ! -f "$home_dir/default/index.html" ];then
	. functions/test.sh
	TEST 2>&1 | tee -a $lnmp_dir/lnmp_install.log 
fi

if [ "$ngx_pagespeed_yn" == 'y' ];then
	. functions/ngx_pagespeed.sh
	Install_ngx_pagespeed 2>&1 | tee -a $lnmp_dir/lnmp_install.log
fi

echo "################Congratulations####################"
echo -e "\033[32mPlease restart the server and see if the services start up fine.\033[0m"
echo ''
echo "The path of some dirs:"
echo -e "`printf "%-32s" "Nginx dir":`\033[32m$nginx_install_dir\033[0m"
echo -e "`printf "%-32s" "PHP dir:"`\033[32m$php_install_dir\033[0m"
echo -e "`printf "%-32s" "$Choice_DB dir:"`\033[32m$db_install_dir\033[0m"
echo -e "`printf "%-32s" "$Choice_DB User:"`\033[32mroot\033[0m"
echo -e "`printf "%-32s" "$Choice_DB Password:"`\033[32m${dbrootpwd}\033[0m"
echo -e "`printf "%-32s" "Manager url:"`\033[32mhttp://$IP/\033[0m"
