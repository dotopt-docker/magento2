FROM php:7.2.13-apache-stretch

LABEL maintainer="wuxingzhong <wuxingzhong@sunniwell.net>"
LABEL Name=magento2 Version=2.3.0
LABEL phpVersion="7.2.13"

ENV  MAGENTO_VERSION 2.3.0
ENV  MAGENTO_DIR /var/www/html
ENV COMPOSER_HOME=/home/www-data/.composer/

RUN mkdir -p /home/www-data/.composer/ \
    && chown -R www-data:www-data /home/www-data \
    && curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer 

COPY ./auth.json ${COMPOSER_HOME}

RUN set -x  \
    && sed  -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list \
	&& apt-get update \
	&& RUN_DEPS=" \
		unzip         \
        libpng-dev    \
        libmcrypt4     \
        libjpeg-turbo8 \
        libicu-dev     \
        libxslt1-dev   \
	" \
    && BUILD_DEPS=" \
        libpng12-dev \
        libmcrypt-dev \
        libcurl3-dev  \
        libfreetype6-dev \
        libjpeg-turbo8-dev \
    " \
	&& apt-get install --no-install-recommends --no-install-suggests -y $RUN_DEPS $BUILD_DEPS  \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install pdo_mysql bcmath  gd  mbstring  zip  intl  xsl  soap \
    && apt-get purge --auto-remove -y $BUILD_DEPS 

RUN chsh -s /bin/bash www-data \
    && su www-data -c "umask 007 && composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition $INSTALL_DIR $MAGENTO_VERSION" \
    && chsh -s /bin/nologin www-data \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \