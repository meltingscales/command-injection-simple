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

# Configure Apache for Cloud Run (port 8080)
RUN sed -i 's/80/8080/g' /etc/apache2/sites-available/000-default.conf /etc/apache2/ports.conf

# Expose port 8080
EXPOSE 8080

# Start Apache in foreground
CMD ["apache2-foreground"]
