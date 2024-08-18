terraform {
  required_providers {
    grid = {
      source = "threefoldtech/grid"
    }
  }
}
provider "grid" {
}

locals {
  deployment_name = "terraform_mycelium"
  vm_name         = "terraform_vm"
}


resource "random_bytes" "mycelium_ip_seed" {
  length = 6
}

resource "random_bytes" "mycelium_key" {
  length = 32
}

resource "grid_scheduler" "sched" {
  requests {
    name             = "node1"
    cru              = 3
    sru              = 1024
    mru              = 2048
    public_config    = true
    public_ips_count = 1
  }
}

resource "grid_network" "net1" {
  name     = local.deployment_name
  nodes    = [grid_scheduler.sched.nodes["node1"]]
  ip_range = "10.1.0.0/16"
  mycelium_keys = {
    format("%s", grid_scheduler.sched.nodes["node1"]) = random_bytes.mycelium_key.hex
  }
  description = "network with mycelium"
}

resource "grid_deployment" "d1" {
  name         = local.deployment_name
  node         = grid_scheduler.sched.nodes["node1"]
  network_name = grid_network.net1.name
  vms {
    name       = local.vm_name
    flist      = "https://hub.grid.tf/tf-official-apps/threefoldtech-ubuntu-22.04.flist"
    entrypoint = "/sbin/zinit init"
    cpu        = 2
    memory     = 2048
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
    }
    mycelium_ip_seed = random_bytes.mycelium_ip_seed.hex
  }
}

data "grid_gateway_domain" "domain" {
  node = grid_scheduler.sched.nodes["node1"]
  name = "terraform_gw"
}

resource "grid_name_proxy" "p1" {
  node            = grid_scheduler.sched.nodes["node1"]
  name            = data.grid_gateway_domain.domain.name
  backends        = [format("http://[%s]:9000", grid_deployment.d1.vms[0].mycelium_ip)]
  tls_passthrough = false
}

output "fqdn" {
  value = data.grid_gateway_domain.domain.fqdn
}

output "vm_private_ip" {
  value = grid_deployment.d1.vms[0].ip
}

output "vm_mycelium_ip" {
  value = grid_deployment.d1.vms[0].mycelium_ip
}
