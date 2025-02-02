FROM ubuntu:22.04

# Set non-interactive mode
ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=8.3

# MySQL environment variables
ENV MYSQL_ROOT_PASSWORD="j^3QWy%Kn0MJNiRC"
ENV MYSQL_DATABASE=chandanlohar
ENV MYSQL_USER=chandan
ENV MYSQL_PASSWORD="*S4Kx*ZDamRn1Tmp"

# Set Working Directory
WORKDIR /var/www/html

# Copy application files and configure Nginx
COPY /app .

# Install Nginx and PHP packages
RUN apt update \
    # Installing Nginx Server 
    && apt install -y nginx \
    # Installing PHP version and its dependencies
    && apt install software-properties-common -y \
    && add-apt-repository ppa:ondrej/php -y \
    && apt install -y \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    mysql-server \
    php-mysql \
    composer \
    git \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Create directory for MySQL initialization scripts
RUN mkdir -p /docker-entrypoint-initdb.d
# Create MySQL initialization script
RUN echo "#!/bin/bash\n\
mysql -u root -p\${MYSQL_ROOT_PASSWORD} << EOF\n\
CREATE DATABASE IF NOT EXISTS \${MYSQL_DATABASE};\n\
CREATE USER IF NOT EXISTS '\${MYSQL_USER}'@'localhost' IDENTIFIED BY '\${MYSQL_PASSWORD}';\n\
GRANT ALL PRIVILEGES ON \${MYSQL_DATABASE}.* TO '\${MYSQL_USER}'@'localhost';\n\
FLUSH PRIVILEGES;\n\
EOF" > /docker-entrypoint-initdb.d/init-db.sh
# Make the script executable
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh
# Configure MySQL
RUN mkdir -p /var/run/mysqld \
&& chown mysql:mysql /var/run/mysqld \
&& echo "[mysqld]\nskip-host-cache\nskip-name-resolve\nbind-address=0.0.0.0" > /etc/mysql/conf.d/docker.cnf

# Update Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/public \
    && chmod -R 775 /var/www/html/bootstrap

# Setting up nginx host file  
COPY nginx/default.conf /etc/nginx/sites-available/default
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

# Opening ports, 80 for Http, 443 for SSH, 3306 for MySQL
EXPOSE 80 443 3306

# Create startup script
RUN echo "#!/bin/bash\n\
service mysql start\n\
/docker-entrypoint-initdb.d/init-db.sh\n\
service php\${PHP_VERSION}-fpm start\n\
nginx -g 'daemon off;'" > /startup.sh
# Make startup script executable
RUN chmod +x /startup.sh
# Start services
CMD ["/startup.sh"]