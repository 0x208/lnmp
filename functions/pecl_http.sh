#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# Blog:  http://blog.linuxeye.com

Install_pecl_http()
{
cd $lnmp_dir/src
. ../functions/download.sh
. ../options.conf

src_url=http://pecl.php.net/get/pecl_http-1.7.6.tgz && Download_src
tar xzf pecl_http-1.7.6.tgz
cd pecl_http-1.7.6
make clean
$php_install_dir/bin/phpize
./configure --with-php-config=$php_install_dir/bin/php-config
make && make install
if [ -f "$php_install_dir/lib/php/extensions/`ls $php_install_dir/lib/php/extensions`/http.so" ];then
        sed -i 's@^extension_dir\(.*\)@extension_dir\1\nextension = "http.so"@' $php_install_dir/etc/php.ini
        service php-fpm restart
else
        echo -e "\033[31mPHP pecl_http module install failed, Please contact the author! \033[0m"
fi
cd ../../
}
