FROM mysql:8

# Tout script .sql placé dans ce dossier est exécuté au premier démarrage (base vide)
COPY init.sql /docker-entrypoint-initdb.d/init.sql
