-- Exécuté au premier démarrage de MySQL : crée la base des logs et donne les droits à l'utilisateur applicatif
CREATE DATABASE IF NOT EXISTS logsdb;
GRANT ALL PRIVILEGES ON logsdb.* TO 'dogs'@'%';
FLUSH PRIVILEGES;
