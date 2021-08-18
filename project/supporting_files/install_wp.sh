#!/bin/bash
echo "<?php">> /app/wordpress/wp-config.php; 
echo "define( 'DB_NAME', '$WP_DB' );">> /app/wordpress/wp-config.php; 
echo "define( 'DB_USER', '$WP_USER' );">> /app/wordpress/wp-config.php; 
echo "define( 'DB_PASSWORD', '$WP_PWD' );">> /app/wordpress/wp-config.php; 
echo "define( 'DB_HOST', 'localhost' );">> /app/wordpress/wp-config.php; 
echo "define( 'DB_CHARSET', 'utf8mb4' );">> /app/wordpress/wp-config.php; 
echo "define( 'DB_COLLATE', '' );">> /app/wordpress/wp-config.php; 
curl https://api.wordpress.org/secret-key/1.1/salt/>> /app/wordpress/wp-config.php; 
echo "\$table_prefix = '$WP_TBP""_';">> /app/wordpress/wp-config.php; 
echo "define( 'WP_DEBUG', $WP_DEBUG );">> /app/wordpress/wp-config.php; 

echo '/** Absolute path to the WordPress directory. */'>> /app/wordpress/wp-config.php;
echo "if ( ! defined( 'ABSPATH' ) ) {">> /app/wordpress/wp-config.php;
echo "	define( 'ABSPATH', __DIR__ . '/' );">> /app/wordpress/wp-config.php;
echo '}'>> /app/wordpress/wp-config.php;
echo ''>> /app/wordpress/wp-config.php;
echo '/** Sets up WordPress vars and included files. */'>> /app/wordpress/wp-config.php;
echo "require_once ABSPATH . 'wp-settings.php';">> /app/wordpress/wp-config.php;