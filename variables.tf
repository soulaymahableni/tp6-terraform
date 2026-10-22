variable "external_port" {
  description = "Port externe du conteneur CV One Page sur la VM"
  type        = number
  default     = 8001
}

variable "cv_build_context" {
  description = "Dossier contenant le Dockerfile du CV"
  type        = string
  default     = "/opt/cv-app/cv"
}

variable "image_name" {
  description = "Nom de l'image du CV (remplacer par <user>/cv-onepage:1.0 pour utiliser Docker Hub)"
  type        = string
  default     = "cv-onepage:1.0"
}
