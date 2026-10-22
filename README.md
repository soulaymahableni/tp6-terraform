# TP6 — Infrastructure as Code avec Terraform (et intégration Vagrant + Ansible)

Terraform décrit l'infrastructure en HCL, compare cet état souhaité au fichier d'état (`terraform.tfstate`) et calcule
les actions nécessaires. Ici, le provider `kreuzwerker/docker` pilote Docker en local, puis à distance via SSH, et enfin
dans des VM créées par Vagrant et provisionnées par Ansible.

## Environnement

| Machine | IP | Rôle |
|---|---|---|
| `vagrant-lab` | 192.168.190.157 | VM de lab : VirtualBox, Vagrant, Ansible, Docker, Terraform 1.17.0 |
| `automatisation` | 192.168.190.141 | « devopslab » : Docker distant joint en SSH (utilisateur `devops`) |
| `vm1` / `vm2` | 192.168.56.21 / .22 | VM Vagrant (bento/ubuntu-24.04) de l'intégration |

![terraform version](captures/terraform-version.png)

## Structure

```
docker-nginx/       Partie 5 : nginx sur le Docker local, port paramétré par une variable
docker-remote/      Partie 5.3 : nginx sur le Docker distant de devopslab via ssh://
integration/
├── Vagrantfile     2 VM (vm1, vm2) + provisioner ansible (cv_port 8001 / 8002)
├── playbook.yml    installe Docker + Terraform, copie le CV et lance Terraform (module community.general.terraform)
├── cv/             CV One Page (HTML5 / CSS3) + Dockerfile basé sur nginx:alpine
├── terraform/      construit l'image du CV et crée le conteneur sur le port var.external_port
└── proxy/          défi : reverse proxy nginx (Terraform) devant vm1 et vm2
```

## Partie 1 — Terraform et Docker local (`docker-nginx/`)

```bash
terraform init
terraform fmt && terraform validate
terraform plan        # Plan: 2 to add
terraform apply       # Apply complete! Resources: 2 added
docker ps && curl http://localhost:8001
terraform state list
terraform apply       # No changes (idempotence)
```

![terraform plan](captures/terraform-plan.png)

![terraform apply](captures/terraform-apply.png)

### Variables

`variables.tf` déclare `external_port` (défaut 8001), utilisé dans `main.tf` (`external = var.external_port`) :

```bash
terraform apply -var external_port=8002   # le conteneur est remplacé (1 added, 1 destroyed)
```

![Variables](captures/terraform-variables.png)

## Partie 2 — Docker distant via SSH (`docker-remote/`)

```hcl
provider "docker" {
  host = "ssh://devops@192.168.190.141:22"
}
```

Prérequis : clé SSH de la VM de lab copiée sur devopslab (`ssh-copy-id`) et `devops` membre du groupe `docker`
(`ssh devops@192.168.190.141 docker ps` sans mot de passe).

![Docker distant](captures/terraform-remote.png)

## Partie 3 — Intégration Vagrant + Ansible + Terraform (`integration/`)

1. **Vagrant** crée `vm1` et `vm2` (1 Go de RAM chacune, réseau privé).
2. Le provisioner **Ansible** installe Docker et Terraform (dépôt HashiCorp), copie `cv/` et `terraform/` dans `/opt/cv-app`.
3. **Terraform** (lancé par le module `community.general.terraform`) construit l'image du CV à partir du Dockerfile et crée le
   conteneur `cv-onepage` sur le port **8001** (vm1) ou **8002** (vm2), grâce à `host_vars` dans le Vagrantfile.

```bash
cd integration
vagrant up
vagrant status
curl http://192.168.56.21:8001     # vm1
curl http://192.168.56.22:8002     # vm2
```

Accès depuis le PC par les ports redirigés de la VM de lab : `http://192.168.190.157:9001` (vm1) et `:9002` (vm2).

![Intégration CV](captures/integration-cv.png)

## Défi — Reverse proxy nginx (`integration/proxy/`)

Terraform crée sur la VM de lab un conteneur `nginx:alpine` en réseau hôte, configuré avec un `upstream` vers
`192.168.56.21:8001` et `192.168.56.22:8002` : un point d'entrée unique sur le port **8088**. L'en-tête `X-Upstream`
indique quelle VM a servi la requête.

```bash
cd integration/proxy
terraform init && terraform apply -auto-approve
curl -sI http://localhost:8088 | grep -i x-upstream
```

![Reverse proxy](captures/reverse-proxy.png)

## Fichiers non versionnés

Conformément à l'énoncé, `terraform.tfstate`, `.terraform/`, `*.tfvars` et `.vagrant/` sont exclus par `.gitignore`.

## Rapport

Voir [RAPPORT.md](RAPPORT.md).
