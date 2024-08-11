terraform {
  required_providers {
    grid = {
      source = "threefoldtech/grid"
    }
  }
}

provider "grid" {
}

resource "grid_scheduler" "sched" {
  requests {
    name = "node1"
    cru  = 2
    sru  = 1024 * 60 
    mru  = 1024 * 2
  }
  requests {
    name             = "gateway"
    public_config    = true
    public_ips_count = 1
  }
}

locals {
  name        = "myvm"
  node1       = grid_scheduler.sched.nodes["node1"]
  gatewaynode = grid_scheduler.sched.nodes["gateway"]
}

data "grid_gateway_domain" "domain" {
  node = local.gatewaynode
  name = "mariadbcluster"
}

resource "grid_network" "net1" {
  nodes         = [local.node1]
  ip_range      = "10.1.0.0/16"
  name          = local.name
  description   = "newer network"
  add_wg_access = true
}
resource "grid_deployment" "d1" {
  name         = local.name
  node         = local.node1
  network_name = grid_network.net1.name
  disks {
    name        = "docker"
    size        = 50
  }
  vms {
    name     = "vm1"
    flist    = "https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-tfgrid_mariadb_demo-latest.flist"
    entrypoint = "/sbin/zinit init"
    cpu      = 2
    publicip = true
    memory   = 2048
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
    }
    mounts {
      disk_name   = "docker"
      mount_point = "/var/lib/docker"
    }
    planetary = true
  }
}
resource "grid_name_proxy" "p1" {
  node            = local.gatewaynode
  name            = "mariadbcluster"
  backends        = [format("http://%s:3000", split("/", grid_deployment.d1.vms[0].computedip)[0])]
  tls_passthrough = false
}

output "fqdn" {
  value = data.grid_gateway_domain.domain.fqdn
}
output "node1_zmachine1_ip" {
  value = grid_deployment.d1.vms[0].ip
}
output "computed_public_ip" {
  value = split("/", grid_deployment.d1.vms[0].computedip)[0]
}
output "ygg_ip" {
  value = grid_deployment.d1.vms[0].planetary_ip
}
