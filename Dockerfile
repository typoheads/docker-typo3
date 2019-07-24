FROM composer:1.8 AS composer-build

# If you plan to require packages from a private vcs or packagist,
# you'll need the private key during builds. Here's the safe 
# way to to accomplish this:
# 
# ARG SSH_PRIVATE_KEY
# RUN mkdir /root/.ssh/ && \
#     echo "${SSH_PRIVATE_KEY}" > /root/.ssh/id_rsa && \
#     chmod 600 /root/.ssh/id_rsa && \
#     ssh-keyscan -H -p <PORT> <GIT_DOMAIN> >> ~/.ssh/known_hosts
# 
# Note: this method is safe only when using it in a multistage-
#       Dockerfile, otherwise traces of ARG will be left in the image.


WORKDIR /app
COPY composer.* ./
RUN composer install --no-dev



FROM typoheads/typo3-apache-php:7.2

# Copy build files, configuration files
COPY --from=composer-build /app .

# Fix permissions
RUN chown -R www-data:www-data public/ var/
