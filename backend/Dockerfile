FROM php:8.2-apache

# Install PDO MySQL extension
RUN docker-php-ext-install pdo pdo_mysql

# Enable apache mod_rewrite if needed
RUN a2enmod rewrite

# Change Apache default port from 80 to 7000
RUN sed -i 's/80/7000/g' /etc/apache2/ports.conf /etc/apache2/sites-available/000-default.conf

EXPOSE 7000
