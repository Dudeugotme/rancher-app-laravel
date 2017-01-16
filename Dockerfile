FROM ubuntu:14.04

MAINTAINER Abhijeet Kamble <abhijeet.kamble619@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update
RUN apt-get install software-properties-common -y
RUN add-apt-repository ppa:webupd8team/java -y
RUN apt-get update
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections
RUN apt-get install oracle-java8-installer -y
RUN apt-get install oracle-java8-set-default



RUN apt-get update && \
    apt-get install -y python-software-properties software-properties-common --force-yes
RUN apt-get update 
RUN add-apt-repository ppa:ondrej/php -y 
RUN add-apt-repository -y ppa:gluster/glusterfs-3.5 && \
    apt-get update && \
    apt-get install -y nginx php php5-fpm php5-mysql php-apc supervisor glusterfs-client curl haproxy pwgen unzip mysql-client dnsutils git --force-yes


RUN curl -sS https://getcomposer.org/installer | php
COPY composer.phar /usr/local/bin/composer

RUN apt-get -y install php5-xsl  mcrypt php5-mcrypt --force-yes
RUN php5enmod mcrypt

COPY Dockerfile /usr/
COPY auth.json /root/.composer/
COPY auth.json /home/jenkins/.composer/
COPY auth.json /home/ajinkyab/.composer/
RUN chmod -R 755 /root/.composer/auth.json 

ENV WORDPRESS_VERSION 4.2.2
ENV WORDPRESS_NAME alm_task_manager
ENV GLUSTER_VOL ranchervol
ENV GLUSTER_VOL_PATH /var/www
ENV HTTP_PORT 80
ENV HTTP_DOCUMENTROOT /var/www/alm_task_manager/public
ENV PHP_SESSION_PATH ${GLUSTER_VOL_PATH}/phpsessions
ENV DEBUG 0

ENV DB_USER root
ENV DB_PASSWORD root
ENV WP_DB_NAME rainbow
ENV DB_HOST db
ENV GLUSTER_HOST storage

RUN mkdir -p /var/log/supervisor ${GLUSTER_VOL_PATH}
WORKDIR ${GLUSTER_VOL_PATH}

RUN mkdir -p /usr/local/bin
ADD ./bin /usr/local/bin
RUN chmod +x /usr/local/bin/*.sh
ADD ./etc/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
ADD ./etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
ADD ./etc/nginx/sites-enabled/wordpress /etc/nginx/sites-enabled/wordpress

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm -f /etc/nginx/sites-enabled/default

# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf

# HAProxy
RUN perl -p -i -e "s/ENABLED=0/ENABLED=1/g" /etc/default/haproxy

CMD ["/usr/local/bin/run.sh"]
