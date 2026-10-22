terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}   # démon Docker local de la VM

# Image du CV construite à partir du Dockerfile (nginx + HTML/CSS)
resource "docker_image" "cv" {
  name = var.image_name
  build {
    context = var.cv_build_context
  }
  keep_locally = true
}

resource "docker_container" "cv" {
  name    = "cv-onepage"
  image   = docker_image.cv.image_id
  restart = "unless-stopped"
  ports {
    internal = 80
    external = var.external_port
  }
}

output "cv_url" {
  value = "http://localhost:${var.external_port}"
}
