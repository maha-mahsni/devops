#!/bin/bash
# Cree /opt/gestion-projets/.env (configuration + mots de passe), lisible par Jenkins.
# A lancer une seule fois dans la VM : bash /vagrant/devops/scripts/init-env.sh
set -e
ENV_DIR=/opt/gestion-projets
ENV_FILE=$ENV_DIR/.env

if [ -f "$ENV_FILE" ]; then
  echo "$ENV_FILE existe deja. Supprime-le d'abord pour le recreer : sudo rm $ENV_FILE"
  exit 1
fi

read -r -p "Ton nom d'utilisateur Docker Hub : " DH_USER
read -r -p "Ta classe (ex : 5SIM1) : " CLASSE
DH_USER=$(echo "$DH_USER" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
CLASSE=$(echo "$CLASSE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
gen() { openssl rand -hex 12; }

sudo mkdir -p "$ENV_DIR"
sudo tee "$ENV_FILE" > /dev/null <<CONF
DOCKERHUB_USER=$DH_USER
IMAGE_PREFIX=kasdaouiahmed-$CLASSE-gestionprojets
TAG=latest
MYSQL_ROOT_PASSWORD=$(gen)
MYSQL_DATABASE=devops_db
MYSQL_USER=devops
MYSQL_PASSWORD=$(gen)
GRAFANA_ADMIN_PASSWORD=$(gen)
CONF
sudo chown jenkins:docker "$ENV_FILE"
sudo chmod 640 "$ENV_FILE"

echo
echo "Fichier cree : $ENV_FILE"
sudo cat "$ENV_FILE"
echo
echo "Images : $DH_USER/kasdaouiahmed-$CLASSE-gestionprojets-backend et -frontend"
echo "Note le mot de passe GRAFANA_ADMIN_PASSWORD : il sert a te connecter a Grafana (utilisateur admin)."
