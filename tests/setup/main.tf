terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
  }
}



resource "random_pet" "cluster_name" {
  length = 2
}

output "cluster_name" {
  value = random_pet.cluster_name.id
}
