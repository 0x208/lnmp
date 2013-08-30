#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# Blog:  http://blog.linuxeye.com

Install_PHP-5-4()
{
cd $lnmp_dir/src
. ../functions/download.sh 
. ../functions/check_os.sh
. ../options.conf

src_url=http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz && Download_src
src_url=http://downloads.sourceforge.net/project/mcrypt/Libmcrypt/2.5.8/libmcrypt-2.5.8.tar.gz && Download_src
src_url=http://downloads.sourceforge.net/project/mhash/mhash/0.9.9.9/mhash-0.9.9.9.tar.gz && Download_src
src_url=http://www.imagemagick.org/download/ImageMagick-6.8.6-9.tar.gz && Download_src
src_url=http://downloads.sourceforge.net/project/mcrypt/MCrypt/2.6.8/mcrypt-2.6.8.tar.gz && Download_src
src_url=http://kr1.php.net/distributions/php-5.4.19.tar.gz && Download_src
src_url=http://pecl.php.net/get/imagick-3.1.0RC2.tgz && Download_src
src_url=http://pecl.php.net/get/pecl_http-1.7.6.tgz && Download_src

tar xzf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local
[ ! -z "`cat /etc/issue | grep 'Ubuntu 13'`" ] && sed -i 's@_GL_WARN_ON_USE (gets@//_GL_WARN_ON_USE (gets@' srclib/stdio.h 
make && make install
cd ../

tar xzf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure
make && make install
ldconfig
cd libltdl/
./configure --enable-ltdl-install
make && make install
cd ../../

tar xzf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9
./configure
make && make install
cd ../

tar xzf ImageMagick-6.8.6-9.tar.gz
cd ImageMagick-6.8.6-9
./configure
make && make install
cd ../

# linked library
cat > /etc/ld.so.conf.d/local.conf <<EOF
/usr/local/lib
EOF
cat > /etc/ld.so.conf.d/mysql.conf <<EOF
$db_install_dir/lib
EOF
ldconfig
ln -s /usr/local/include/ImageMagick-6 /usr/local/include/ImageMagick
OS_CentOS='ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config \n
ln -s $db_install_dir/include/* /usr/local/include/ \n
if [ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 64 ];then \n
        ln -s /lib64/libpcre.so.0.0.1 /lib64/libpcre.so.1 \n
        ln -s /usr/lib64/libldap* /usr/lib \n
else \n
        ln -s /lib/libpcre.so.0.0.1 /lib/libpcre.so.1 \n
fi'
OS_Ubuntu='if [ `getconf WORD_BIT` == 32 ] && [ `getconf LONG_BIT` == 64 ];then \n
        ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/ \n
	ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/ \n
else \n
        ln -s /usr/lib/i386-linux-gnu/libldap.so /usr/lib/ \n
        ln -s /usr/lib/i386-linux-gnu/liblber.so /usr/lib/ \n
fi'
OS_command

tar xzf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8
ldconfig
./configure
make && make install
cd ../

tar xzf php-5.4.19.tar.gz
useradd -M -s /sbin/nologin www
cd php-5.4.19
./configure  --prefix=$php_install_dir --with-config-file-path=$php_install_dir/etc \
--with-fpm-user=www --with-fpm-group=www --enable-fpm --with-mysql=$db_install_dir \
--with-mysqli=$db_install_dir/bin/mysql_config --with-pdo-mysql --disable-fileinfo \
--with-iconv-dir=/usr/local --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib \
--with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-exif \
--enable-sysvsem --enable-inline-optimization --with-curl --with-kerberos --enable-mbregex \
--enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-xsl --with-openssl \
--with-mhash --enable-pcntl --enable-sockets --with-ldap --with-ldap-sasl --with-xmlrpc \
--enable-ftp --with-gettext --enable-zip --enable-soap --disable-ipv6 --disable-debug
make ZEND_EXTRA_LIBS='-liconv'
make install

if [ -d "$php_install_dir" ];then
        echo -e "\033[32mPHP install successfully! \033[0m"
else
        echo -e "\033[31mPHP install failed, Please Contact the author! \033[0m"
        kill -9 $$
fi

# wget -c http://pear.php.net/go-pear.phar
# $php_install_dir/bin/php go-pear.phar

/bin/cp php.ini-production $php_install_dir/etc/php.ini

# php-fpm Init Script
/bin/cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
chmod +x /etc/init.d/php-fpm
OS_CentOS='chkconfig --add php-fpm \n
chkconfig php-fpm on'
OS_Ubuntu='update-rc.d php-fpm defaults'
OS_command
cd ../

tar xzf imagick-3.1.0RC2.tgz
cd imagick-3.1.0RC2
make clean
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig
$php_install_dir/bin/phpize
./configure --with-php-config=$php_install_dir/bin/php-config
make && make install
cd ../

# Support HTTP request curls
tar xzf pecl_http-1.7.6.tgz
cd pecl_http-1.7.6
make clean
$php_install_dir/bin/phpize
./configure --with-php-config=$php_install_dir/bin/php-config
make && make install

# Modify php.ini
sed -i "s@extension_dir = \"ext\"@extension_dir = \"ext\"\nextension_dir = \"$php_install_dir/lib/php/extensions/`ls $php_install_dir/lib/php/extensions/`\"\nextension = \"imagick.so\"\nextension = \"http.so\"@" $php_install_dir/etc/php.ini
sed -i 's@^output_buffering =@output_buffering = On\noutput_buffering =@' $php_install_dir/etc/php.ini
sed -i 's@^;cgi.fix_pathinfo.*@cgi.fix_pathinfo=0@' $php_install_dir/etc/php.ini
sed -i 's@^short_open_tag = Off@short_open_tag = On@' $php_install_dir/etc/php.ini
sed -i 's@^expose_php = On@expose_php = Off@' $php_install_dir/etc/php.ini
sed -i 's@^request_order.*@request_order = "CGP"@' $php_install_dir/etc/php.ini
sed -i 's@^;date.timezone.*@date.timezone = Asia/Shanghai@' $php_install_dir/etc/php.ini
sed -i 's@^post_max_size.*@post_max_size = 50M@' $php_install_dir/etc/php.ini
sed -i 's@^upload_max_filesize.*@upload_max_filesize = 50M@' $php_install_dir/etc/php.ini
sed -i 's@^;upload_tmp_dir.*@upload_tmp_dir = /tmp@' $php_install_dir/etc/php.ini
sed -i 's@^max_execution_time.*@max_execution_time = 300@' $php_install_dir/etc/php.ini
sed -i 's@^disable_functions.*@disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket@' $php_install_dir/etc/php.ini
sed -i 's@^session.cookie_httponly.*@session.cookie_httponly = 1@' $php_install_dir/etc/php.ini
sed -i 's@^pdo_mysql.default_socket.*@pdo_mysql.default_socket = /tmp/mysql.sock@' $php_install_dir/etc/php.ini
sed -i 's@#sendmail_path.*@#sendmail_path = /usr/sbin/sendmail -t@' $php_install_dir/etc/php.ini

cat > $php_install_dir/etc/php-fpm.conf <<EOF
;;;;;;;;;;;;;;;;;;;;;
; FPM Configuration ;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;
; Global Options ;
;;;;;;;;;;;;;;;;;;

[global]
pid = run/php-fpm.pid
error_log = log/php-fpm.log
log_level = notice

emergency_restart_threshold = 30
emergency_restart_interval = 1m
process_control_timeout = 5s
daemonize = yes

;;;;;;;;;;;;;;;;;;;;
; Pool Definitions ;
;;;;;;;;;;;;;;;;;;;;

[www]

listen = 127.0.0.1:9000
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www

pm = dynamic
pm.max_children = 32
pm.start_servers = 4
pm.min_spare_servers = 4
pm.max_spare_servers = 16
pm.max_requests = 512

request_terminate_timeout = 0
request_slowlog_timeout = 0

slowlog = log/slow.log
rlimit_files = 51200
rlimit_core = 0

catch_workers_output = yes
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
EOF
service php-fpm start
cd ../../
}
