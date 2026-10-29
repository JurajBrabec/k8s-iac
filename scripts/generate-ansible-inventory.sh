#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_file="$repo_root/ansible/inventory.generated.json"

command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

addresses="$(terraform -chdir="$repo_root/terraform/proxmox" output -json node_addresses)"

jq -e -f "$repo_root/scripts/validate-terraform-node-addresses.jq" <<<"$addresses" >/dev/null || {
  echo "Terraform output must contain lab-server and one to three workers." >&2
  exit 1
}

mkdir -p "$(dirname "$output_file")"
tmp_file="$(mktemp "${output_file}.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

jq -f "$repo_root/scripts/terraform-output-to-ansible-inventory.jq" <<<"$addresses" >"$tmp_file"

mv "$tmp_file" "$output_file"
trap - EXIT
chmod 600 "$output_file"
echo "Generated $output_file"
