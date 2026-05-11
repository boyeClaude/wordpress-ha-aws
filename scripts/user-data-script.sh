#!/bin/bash
# 1. Mise à jour et installation des dépendances
dnf update -y
dnf install -y httpd php php-mysqlnd php-gd php-xml mariadb105 jq


# Démarrage d'Apache
systemctl enable httpd
systemctl start httpd


# 2. Récupération dynamique des secrets depuis Secrets Manager
REGION="us-east-1"
SECRET_NAME="WP-DB-Secret"

STR_SECRET=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)

DB_USER=$(echo $STR_SECRET | jq -r .username)
DB_PASS=$(echo $STR_SECRET | jq -r .password)
DB_NAME=$(echo $STR_SECRET | jq -r .dbname)

# 3. Point de connexion vers la base de données
# REMPLACE PAR TON ENDPOINT RDS RÉEL CI-DESSOUS :
DB_HOST="wordpressdb.c2h0e8iuorj8.us-east-1.rds.amazonaws.com"

# 4. Téléchargement et préparation de WordPress
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -r wordpress/* .
rm -rf wordpress latest.tar.gz

# --- LA MODIFICATION CRUCIALE ICI ---
# Au lieu de sed, on crée le fichier de zéro pour éviter les erreurs de caractères spéciaux
cat <<EOF > /var/www/html/wp-config.php
<?php
define( 'DB_NAME', '$DB_NAME' );
define( 'DB_USER', '$DB_USER' );
define( 'DB_PASSWORD', '$DB_PASS' );
define( 'DB_HOST', '$DB_HOST' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}
require_once ABSPATH . 'wp-settings.php';
EOF