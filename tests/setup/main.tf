resource "random_pet" "cluster_name" {
  length = 2
}

output "cluster_name" {
  value = random_pet.cluster_name.id
}
