FROM php:8.2-apache

# Install basic utilities
RUN apt-get update && apt-get install -y \
    vim \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Enable Apache mod_rewrite (if needed)
RUN a2enmod rewrite

# Copy application files to Apache document root
COPY index.html /var/www/html/
COPY vulnerable.php /var/www/html/
COPY safe.php /var/www/html/

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Expose port 80
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
