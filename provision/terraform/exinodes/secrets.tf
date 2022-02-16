data "sops_file" "secrets" {
  source_file = "secret.sops.yaml"
}