terraform {
  required_providers {
    grid = {
      source = "threefoldtech/grid"
    }
  }
}

provider "grid" {
}

resource "random_bytes" "master_mycelium_ip_seed" {
  length = 6
}

resource "random_bytes" "worker0_mycelium_ip_seed" {
  length = 6
}

resource "random_bytes" "worker1_mycelium_ip_seed" {
  length = 6
}

resource "random_bytes" "worker2_mycelium_ip_seed" {
  length = 6
}

resource "random_bytes" "monitor_mycelium_ip_seed" {
  length = 6
}

resource "random_bytes" "master_mycelium_key" {
  length = 32
}

resource "random_bytes" "worker0_mycelium_key" {
  length = 32
}

resource "random_bytes" "worker1_mycelium_key" {
  length = 32
}

resource "random_bytes" "worker2_mycelium_key" {
  length = 32
}

resource "random_bytes" "monitor_mycelium_key" {
  length = 32
}

resource "grid_scheduler" "sched" {
  requests {
    name             = "master_node"
    cru              = 2
    sru              = 512
    mru              = 2048
    distinct         = true
    public_ips_count = 1
    public_config    = true
  }
  requests {
    name     = "worker0_node"
    cru      = 2
    sru      = 512
    mru      = 2048
    distinct = true
  }
  requests {
    name     = "worker1_node"
    cru      = 2
    sru      = 512
    mru      = 2048
    distinct = true
  }
  requests {
    name     = "worker2_node"
    cru      = 2
    sru      = 512
    mru      = 2048
    distinct = true
  }
  requests {
    name = "monitor_node"
    cru  = 1
    sru  = 1024 * 10
    mru  = 1024 * 2
    distinct = true
  }
  requests {
    name             = "gateway_node1"
    public_config    = true
    public_ips_count = 1
  }
  requests {
    name             = "gateway_node2"
    public_config    = true
    public_ips_count = 1
  }
}

locals {
  solution_type = "kubernetes/mr"
  name          = "myk8s"
}

resource "grid_network" "net1" {
  name          = local.name
  nodes         = distinct(values(grid_scheduler.sched.nodes))
  ip_range      = "10.1.0.0/16"
  description   = "kubernetes network"
  add_wg_access = true
  mycelium_keys = {
    format("%s", grid_scheduler.sched.nodes["master_node"])  = random_bytes.master_mycelium_key.hex
    format("%s", grid_scheduler.sched.nodes["worker0_node"]) = random_bytes.worker0_mycelium_key.hex
    format("%s", grid_scheduler.sched.nodes["worker1_node"]) = random_bytes.worker1_mycelium_key.hex
    format("%s", grid_scheduler.sched.nodes["worker2_node"]) = random_bytes.worker2_mycelium_key.hex
    format("%s", grid_scheduler.sched.nodes["monitor_node"]) = random_bytes.monitor_mycelium_key.hex
  }
}

resource "grid_kubernetes" "k8s1" {
  solution_type = local.solution_type
  name          = local.name
  network_name  = grid_network.net1.name
  token         = "12345678910122"
  ssh_key       = file("~/.ssh/id_rsa.pub")

  master {
    disk_size        = 2
    node             = grid_scheduler.sched.nodes["master_node"]
    name             = "mr"
    cpu              = 2
    publicip         = true
    memory           = 2048
    mycelium_ip_seed = random_bytes.master_mycelium_ip_seed.hex
  }
  workers {
    disk_size        = 2
    node             = grid_scheduler.sched.nodes["worker0_node"]
    name             = "w0"
    cpu              = 2
    memory           = 2048
    mycelium_ip_seed = random_bytes.worker0_mycelium_ip_seed.hex
  }
  workers {
    disk_size        = 2
    node             = grid_scheduler.sched.nodes["worker1_node"]
    name             = "w2"
    cpu              = 2
    memory           = 2048
    mycelium_ip_seed = random_bytes.worker1_mycelium_ip_seed.hex
  }
  workers {
    disk_size        = 2
    node             = grid_scheduler.sched.nodes["worker2_node"]
    name             = "w3"
    cpu              = 2
    memory           = 2048
    mycelium_ip_seed = random_bytes.worker2_mycelium_ip_seed.hex
  }

  provisioner "file" {
    source      = "../scripts"
    destination = "scripts"

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.master[0].computedip)[0]
      private_key = file("~/.ssh/id_rsa")
    }

  }

  provisioner "remote-exec" {
    inline = [
      "chmod +777 scripts/*",
      "./scripts/init.sh"
    ]

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.master[0].computedip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "file" {
    source      = "../scripts"
    destination = "scripts"

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.workers[0].mycelium_ip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +777 scripts/*",
      "./scripts/init.sh"
    ]

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.workers[0].mycelium_ip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }


  provisioner "file" {
    source      = "../scripts"
    destination = "scripts"

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.workers[1].mycelium_ip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +777 scripts/*",
      "./scripts/init.sh"
    ]

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.workers[1].mycelium_ip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }


  provisioner "file" {
    source      = "../scripts"
    destination = "scripts"

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.workers[2].mycelium_ip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +777 scripts/*",
      "./scripts/init.sh"
    ]

    connection {
      type    = "ssh"
      user    = "root"
      timeout = "30s"
      host    = split("/", self.workers[2].mycelium_ip)[0]
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

resource "grid_deployment" "monitor" {
  solution_type = local.solution_type
  name          = local.name
  node          = grid_scheduler.sched.nodes["monitor_node"]
  network_name  = grid_network.net1.name

  vms {
    name       = "monitor"
    flist      = "https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-monitor-latest.flist"
    entrypoint = "/sbin/zinit init"
    cpu        = 1
    memory     = 1024 * 2
    env_vars = {
      SSH_KEY = file("~/.ssh/id_rsa.pub")
      PROM_TARGETS = format("[%s]:9501,[%s]:9501,[%s]:9501,[%s]:9501",
        grid_kubernetes.k8s1.master[0].mycelium_ip,
        grid_kubernetes.k8s1.workers[0].mycelium_ip,
        grid_kubernetes.k8s1.workers[1].mycelium_ip,
        grid_kubernetes.k8s1.workers[2].mycelium_ip,
      )
    }
    mycelium_ip_seed = random_bytes.monitor_mycelium_ip_seed.hex
  }
}

resource "grid_name_proxy" "gateway1" {
  node            = grid_scheduler.sched.nodes["gateway_node1"]
  name            = "grafana"
  backends        = [format("http://[%s]:3000", grid_deployment.monitor.vms[0].mycelium_ip)]
  tls_passthrough = false
}

resource "grid_name_proxy" "gateway2" {
  node            = grid_scheduler.sched.nodes["gateway_node2"]
  name            = "prometheus"
  backends        = [format("http://[%s]:9090", grid_deployment.monitor.vms[0].mycelium_ip)]
  tls_passthrough = false
}

output "computed_master_public_ip" {
  value = grid_kubernetes.k8s1.master[0].computedip
}

output "computed_master_mycelium_ip" {
  value = grid_kubernetes.k8s1.master[0].mycelium_ip
}

output "computed_worker0_mycelium_ip" {
  value = grid_kubernetes.k8s1.workers[0].mycelium_ip
}

output "computed_worker1_mycelium_ip" {
  value = grid_kubernetes.k8s1.workers[1].mycelium_ip
}

output "computed_worker2_mycelium_ip" {
  value = grid_kubernetes.k8s1.workers[2].mycelium_ip
}

output "master_console_url" {
  value = grid_kubernetes.k8s1.master[0].console_url
}

output "grafana_hostname" {
  value = grid_name_proxy.gateway1.fqdn
}

output "prometheus_hostname" {
  value = grid_name_proxy.gateway2.fqdn
}

