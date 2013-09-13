#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# Blog:  http://blog.linuxeye.com

Install_ngx_pagespeed()
{
cd $lnmp_dir/src
. ../functions/download.sh 
. ../options.conf

rm -rf ngx_pagespeed*
src_url=https://dl.google.com/dl/page-speed/psol/1.6.29.5.tar.gz && Download_src
[ -s "release-1.6.29.5-beta.zip" ] && echo "release-1.6.29.5-beta.zip found" || wget -c --no-check-certificate -O ngx_pagespeed-master.zip https://github.com/pagespeed/ngx_pagespeed/archive/master.zip 

unzip -q ngx_pagespeed-master.zip 
/bin/mv ngx_pagespeed-master ngx_pagespeed-release-1.6.29.5-beta
tar xzf 1.6.29.5.tar.gz -C ngx_pagespeed-release-1.6.29.5-beta

if [ "$Web_server" == '1' ];then
	cd nginx-1.4.2
	make clean

	if [ "$je_tc_malloc" == '1' ];then
		malloc_module="--with-ld-opt='-ljemalloc'"
	elif [ "$je_tc_malloc" == '2' ];then
	        malloc_module='--with-google_perftools_module'
	fi

	if [ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 64 ] ;then
		./configure --prefix=$web_install_dir --user=www --group=www --with-http_stub_status_module --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --add-module=../ngx_pagespeed-release-1.6.29.5-beta --with-cc-opt='-DLINUX=2 -D_REENTRANT -D_LARGEFILE64_SOURCE -pthread' $malloc_module
	else
		./configure --prefix=$web_install_dir --user=www --group=www --with-http_stub_status_module --with-http_ssl_module --with-http_flv_module --with-http_gzip_static_module --add-module=../ngx_pagespeed-release-1.6.29.5-beta --with-cc-opt='-DLINUX=2 -D_REENTRANT -D_LARGEFILE64_SOURCE -march=i686 -pthread' $malloc_module
	fi

	make
	if [ -f "objs/nginx" ];then
		/bin/mv $web_install_dir/sbin/nginx $web_install_dir/sbin/nginx$(date +%m%d)
		/bin/cp objs/nginx $web_install_dir/sbin/nginx
		mkdir /var/ngx_pagespeed_cache
		chown -R www.www /var/ngx_pagespeed_cache
		kill -USR2 `cat /var/run/nginx.pid`
		kill -QUIT `cat /var/run/nginx.pid.oldbin`
		echo -e "\033[32minstall ngx_pagespeed module successfully! \033[0m"
	else
		echo -e "\033[31minstall ngx_pagespeed failed\033[0m"
	fi
	cd ../
elif [ "$Web_server" == '2' ];then
	$web_install_dir/sbin/dso_tool --add-module=$lnmp_dir/src/ngx_pagespeed-release-1.6.29.5-beta
	if [ -f "$web_install_dir/modules/ngx_pagespeed.so" ];then
		sed -i "s@^dso\(.*\)@dso\1\n\tload ngx_pagespeed.so;@" $web_install_dir/conf/nginx.conf
		mkdir /var/ngx_pagespeed_cache
		chown -R www.www /var/ngx_pagespeed_cache
		kill -HUP `cat /var/run/nginx.pid`
	fi
fi
cd ..
}
