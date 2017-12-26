FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get upgrade -y 
RUN apt-get install -y openssh-server \
curl \
nano \
git \
zip \
unzip \
wget \
pv \
git-core bash-completion \
python-software-properties \
software-properties-common 

RUN apt-get install -y language-pack-en-base

# NEEDED IF WE WANT APACHE2 FROM ONDREJ (LC_ALL NEEDS TO STAY ON THE SAME LINE!!!)
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/apache2

#NEEDED FOR PHP7.1 (LC_ALL NEEDS TO STAY ON THE SAME LINE!!!)
RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php


# REFRESH PACKAGES
RUN apt-get update -y

#INSTALL APACHE2
RUN apt-get install -y apache2 

RUN a2enmod rewrite 
RUN a2enmod headers



# INSTALL PHP 7.1
RUN apt-get install -y --allow-unauthenticated \
php7.1 \
php7.1-xml \
php7.1-mbstring \
php7.1-zip \
php7.1-mysql \
php7.1-phpdbg \
php7.1-sqlite3 \
php7.1-json \
php7.1-xmlrpc \
php7.1-curl \
php7.1-ldap \
php7.1-bz2 \
php7.1-cgi \
php7.1-cli \
php7.1-dev \
php7.1-intl \
php7.1-common \
php7.1-bcmath \
php7.1-soap \
php7.1-mcrypt \
php7.1-gd \
php7.1-xdebug



# php7.1-phantomjs \
# php7.1-fop \
# php7.1-imap
# php7.1-fpm \
# php7.1-recode \
# php7.1-odbc \
# php7.1-dba \


EXPOSE 80


#COMPOSER GLOBAL
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
php composer-setup.php && \
php -r "unlink('composer-setup.php');" && \
mv composer.phar /usr/local/bin/composer && \
echo 'export PATH="$HOME/.composer/vendor/bin:$PATH"' >> ~/.bashrc

# ADD GIT COMPLETION IN BASH RC
RUN echo '#GIT AUTOCOMPLETION' >> ~/.bashrc && \
echo 'source /usr/share/bash-completion/completions/git' >> ~/.bashrc


#AWS CLI
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
unzip awscli-bundle.zip && \
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws && \
aws --version


#SOME CONFIGURATION FOR BASHRC AND ADDING ENTRYPOINT SCRIPT
COPY ./start_files/ubuntu/bashrc /root/.bashrc
COPY ./start_files/ubuntu/start_services.sh /root/

#CREATE THE .ssh FOLDER
RUN mkdir ~/.ssh


RUN mkdir -p /etc/php/7.1/apache2/conf.d


RUN apt-get install libapache2-mod-php7.1

# APACHE WEB SERVER CONF E MODS
COPY ./start_files/apache/conf/ /etc/apache2/conf-enabled/
COPY ./start_files/apache/mods/ /etc/apache2/mods-enabled/
RUN mkdir /var/www/html/public
COPY ./start_files/apache/www_html_default/ /var/www/html/public/
RUN rm /var/www/html/index.html
COPY ./start_files/apache/vhosts/ /etc/apache2/sites-enabled/

#PHP7 CONF
COPY ./start_files/php/ini/xdebug.ini /etc/php/7.1/mods-available/xdebug.ini 
#xdebug file simlinks already exists... no need to create them....
#RUN ln -s  /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/cli/conf.d/20-xdebug.ini 
#RUN ln -s  /etc/php/7.1/mods-available/xdebug.ini /etc/php/7.1/apache2/conf.d/20-xdebug.ini 
            
#COPY ./start_files/php/ini/error_log.ini /etc/php/7.1/mods-available/error_log.ini 
RUN ln -s  /etc/php/7.1/mods-available/error_log.ini /etc/php/7.1/cli/conf.d/05-error_log.ini 
RUN ln -s  /etc/php/7.1/mods-available/error_log.ini /etc/php/7.1/apache2/conf.d/05-error_log.ini 

#PHP: HAVE THE SESSION FOLDER WRITABLE BY EVERYONE SO THAT WE DO NOT HAVE PERMISSION ISSUES
RUN chmod -R 777 /var/lib/php/sessions

#PHP MEMORY LIMIT
COPY ./start_files/php/ini/memory_limit.ini /etc/php/7.1/mods-available/memory_limit.ini 
RUN ln -s  /etc/php/7.1/mods-available/memory_limit.ini /etc/php/7.1/cli/conf.d/10-memory_limit.ini 
RUN ln -s  /etc/php/7.1/mods-available/memory_limit.ini /etc/php/7.1/apache2/conf.d/10-memory_limit.ini 

#PHP UPLOAD LIMIT
COPY ./start_files/php/ini/upload_size_limit.ini /etc/php/7.1/mods-available/upload_size_limit.ini 
RUN ln -s  /etc/php/7.1/mods-available/upload_size_limit.ini /etc/php/7.1/cli/conf.d/10-upload_size_limit.ini 
RUN ln -s  /etc/php/7.1/mods-available/upload_size_limit.ini /etc/php/7.1/apache2/conf.d/10-upload_size_limit.ini 


RUN apt-get install -y php-mongodb iputils-ping
RUN apt-get install -y screen
COPY ./start_files/ubuntu/screenrc /root/.screenrc

RUN apt-get install ssmtp -y
RUN echo "# configure ssmtp as a sendmail dummy wrapper" >> /etc/php/7.1/mods-available/sendmail.ini
RUN echo "# you can configure /etc/ssmtp/ssmtp.conf for the smtp server or mailcatcher" >> /etc/php/7.1/mods-available/sendmail.ini

RUN echo "sendmail_path = /usr/sbin/ssmtp -t" > /etc/php/7.1/mods-available/sendmail.ini
RUN phpenmod sendmail

# Default command	
CMD ["sh", "/root/start_services.sh"]
