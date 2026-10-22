# Rapport — TP6 : Terraform

## 1. Démarche
Terraform 1.17.0 a été installé sur la VM de lab à partir du dépôt HashiCorp déjà configuré au TP5. Le premier projet
crée une image et un conteneur nginx sur le Docker local : `terraform plan` annonce 2 ressources à créer, `apply` les
crée, `terraform state list` les liste, et un second `apply` répond « No changes » (idempotence). La variable
`external_port` permet de changer le port sans modifier le code : `-var external_port=8002` remplace le conteneur.

Le provider Docker accepte un hôte `ssh://` : avec une clé SSH déployée sur `automatisation` et l'utilisateur `devops`
dans le groupe `docker`, le même type de configuration a créé `nginx_terraform_remote` sur cette autre machine (port 8090).

L'intégration enchaîne les trois outils : **Vagrant** crée deux VM, **Ansible** les configure (Docker, Terraform, copie
des fichiers) et **Terraform**, appelé par le module `community.general.terraform`, construit l'image du CV One Page
(nginx + HTML/CSS) puis crée le conteneur sur le port 8001 (vm1) ou 8002 (vm2). Le port est une variable Terraform,
alimentée par une variable Ansible définie par VM dans le Vagrantfile (`host_vars`).

Pour le défi, un reverse proxy nginx créé par Terraform sur la VM de lab sert de point d'entrée unique (port 8088) devant
les deux VM.

## 2. Comparaison des outils
| Outil | Rôle dans le lab | Approche |
|---|---|---|
| Vagrant | crée les VM | décrit des machines (Vagrantfile) |
| Ansible | configure les VM | décrit un état système, exécute des tâches en SSH |
| Terraform | crée les ressources (conteneurs) | décrit des ressources, garde un état et calcule un plan |

Terraform se distingue par son fichier d'état et par `plan`, qui montre à l'avance les créations, modifications (`~`)
et remplacements (`-/+`).

## 3. Difficultés et choix
- **Docker Hub** : l'image du CV est construite directement dans chaque VM par la ressource `docker_image` (bloc `build`),
  au lieu d'être poussée sur Docker Hub. Pour utiliser Docker Hub, il suffit de passer `image_name` à `<user>/cv-onepage:1.0`.
- **Groupe docker** : après `usermod -aG docker`, il faut se déconnecter puis se reconnecter pour que `docker ps`
  fonctionne sans `sudo`.
- **Ports** : `automatisation` ayant déjà de nombreux ports occupés, le conteneur distant utilise 8090. Les CV sont exposés
  au PC par des redirections Vagrant (9001, 9002) sur l'IP de la VM de lab.
- **Mémoire** : leçon du TP5, les VM de l'intégration n'ont que 1 Go (pas de Jenkins) et les VM du TP5 ont été arrêtées
  avec `vagrant halt` avant de commencer.
- **Reverse proxy** : lors du test, deux requêtes successives ont été servies par vm1 (`X-Upstream: 192.168.56.21:8001`).
  nginx fait un round-robin par processus de travail ; sur un petit nombre de requêtes, elles peuvent tomber sur le même
  serveur. Le proxy est fonctionnel ; l'alternance se voit sur une série plus longue de requêtes.
- **État Terraform** : `terraform.tfstate` contient le détail des ressources ; il n'est pas versionné (`.gitignore`).
