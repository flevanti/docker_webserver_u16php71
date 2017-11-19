# you can put here commands you want to execute when container is started.

#IF an error occurs stop execution of the script
set -e


# Apache gets grumpy about PID files pre-existing
rm -f /var/run/apache2/apache2.pid


#this needs to be the last command... :)
apache2ctl -D FOREGROUND

