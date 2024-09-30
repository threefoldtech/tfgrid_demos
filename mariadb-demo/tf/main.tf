terraform {
  required_providers {
    grid = {
      source = "threefoldtech/grid"
    }
  }
}

resource "grid_scheduler" "sched" {
  requests {
    name = "maria_master_node"
    cru  = 1
    sru  = 1024 * 50
    mru  = 1024 * 1
  }
  requests {
    name = "maria_workers_node"
    cru  = 1
    sru  = 1024 * 10
    mru  = 1024 * 2
  }
  requests {
    name = "monitor_node"
    cru  = 1
    sru  = 1024 * 10
    mru  = 1024 * 2
  }
  requests {
    name             = "gateway_node"
    public_config    = true
    public_ips_count = 1
  }
}

locals {
  maria_master_node = grid_scheduler.sched.nodes["maria_master_node"]
  maria_workers_node = grid_scheduler.sched.nodes["maria_workers_node"]
  monitor_node       = grid_scheduler.sched.nodes["monitor_node"]
  gateway_node       = grid_scheduler.sched.nodes["gateway_node"]
}

resource "grid_network" "net" {
  name          = "neonet"
  ip_range      = "10.1.0.0/16"
  nodes         = [local.maria_master_node, local.maria_workers_node, local.monitor_node]
  add_wg_access = true
}

resource "grid_deployment" "master" {
  name         = "maria_master"
  node         = local.maria_master_node
  network_name = grid_network.net.name
  vms {
    name       = "master"
    flist      = "https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-mariadb-latest.flist"
    entrypoint = "/sbin/zinit init"
    cpu        = 1
    memory     = 1024 * 1
    planetary  = true
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
      MYSQL_ROOT_PASSWORD : "rootpassword"
      MYSQL_DATABASE : "mydb"
      MYSQL_USER : "mysql"
      MYSQL_PASSWORD : "password"
    }
  }
}

resource "grid_deployment" "workers" {
  name         = "maria_workers"
  node         = local.maria_workers_node
  network_name = grid_network.net.name
  vms {
    name       = "worker1"
    flist      = "https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-mariadb-latest.flist"
    entrypoint = "/sbin/zinit init"
    cpu        = 1
    memory     = 1024 * 1
    planetary  = true
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
      MYSQL_ROOT_PASSWORD : "rootpassword"
      MYSQL_REPLICATION_MODE : "slave"
      MYSQL_MASTER_HOST : grid_deployment.master.vms[0].planetary_ip
      MYSQL_MASTER_USER : "mysql"
      MYSQL_MASTER_PASSWORD : "password"
      MYSQL_DATABASE : "mydb"
    }
  }
  vms {
    name       = "worker2"
    flist      = "https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-mariadb-latest.flist"
    entrypoint = "/sbin/zinit init"
    cpu        = 1
    memory     = 1024 * 1
    planetary  = true
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
      MYSQL_ROOT_PASSWORD : "rootpassword"
      MYSQL_REPLICATION_MODE : "slave"
      MYSQL_MASTER_HOST : grid_deployment.master.vms[0].planetary_ip
      MYSQL_MASTER_USER : "mysql"
      MYSQL_MASTER_PASSWORD : "password"
      MYSQL_DATABASE : "mydb"
    }
  }
}

resource "grid_deployment" "monitor" {
  name         = "monitor"
  node         = local.monitor_node
  network_name = grid_network.net.name
  vms {
    name       = "monitor"
    flist      = "https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-monitor-latest.flist"
    entrypoint = "/sbin/zinit init"
    cpu        = 1
    memory     = 1024 * 2
    planetary   = true
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
      PROM_TARGETS = format("[%s]:9501,[%s]:9500,[%s]:9501,[%s]:9500,[%s]:9501,[%s]:9500",
        grid_deployment.master.vms[0].planetary_ip,
        grid_deployment.master.vms[0].planetary_ip,
        grid_deployment.workers.vms[0].planetary_ip,
        grid_deployment.workers.vms[0].planetary_ip,
        grid_deployment.workers.vms[1].planetary_ip,
        grid_deployment.workers.vms[1].planetary_ip
      )
    }
  }
}

resource "grid_name_proxy" "gateway" {
  node            = local.gateway_node
  name            = "mariadbcluster2"
  backends        = [format("http://[%s]:3000", grid_deployment.monitor.vms[0].planetary_ip)]
  tls_passthrough = false
}

output "hostname" {
  value = grid_name_proxy.gateway.fqdn
}

output "monitor_ip" {
  value = grid_deployment.monitor.vms[0].planetary_ip
}
