FROM composer:1.8 AS composer-build

# If you plan to require packages from a private vcs/packagist,
# you'll need the private key during builds. Here's the safe 
# way to to accomplish this:
# 
# ARG SSH_PRIVATE_KEY
# ARG KNOWN_HOSTS
# RUN mkdir /root/.ssh/ && \
#     echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && \
#     echo "${KNOWN_HOSTS}" > /root/.ssh/known_hosts && \
#     chmod 600 /root/.ssh/id_rsa
# 
# Note: this method is only safe when using it in a multistage-
#       Dockerfile, otherwise traces of ARG are left in the image.


WORKDIR /app
COPY composer.lock .
COPY composer.json .
RUN composer install



FROM typoheads/typo3-apache-php:7.2

# Copy build files, configuration files
COPY --from=composer-build /app .
COPY docker/typo3/AdditionalConfiguration.php ./public/typo3conf/
COPY docker/typo3/LocalConfiguration.php ./public/typo3conf/
COPY docker/typo3/.htaccess ./public/


# Fixes
RUN chown -R www-data:. public/ var/ && \
    rm -f ./public/typo3/install.php