# monitored mariadb cluster

demo deploying a full mariadb cluster (one master and 2 workers) each exposing its two metrics by mysqld-exporter and node-exporter.

the cluster is scrapped by prometheus and visualize a full node dashboard with grafana.

## images

MariaDb image:

- source: https://github.com/threefoldtech/tf-images/tree/development/tfgrid3/mariadb
- flist: https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-mariadb-latest.flist

  includes:

  - mariadb server
  - node_exporter
  - mysqld_exporter

Monitor image:

- source: https://github.com/threefoldtech/tf-images/tree/development/tfgrid3/monitor
- flist: https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-monitor-latest.flist

  includes:

  - prometheus
  - grafana

## deployment

it uses the terraform client with this script ./tf/main.tf which will deploy the flist with public ip and expose with domain name

### ports

- `3000`: to access the grafana dashboard
- `9090`: to access prometheus web ui
- the output domain name will point to grafana dashboard

## usage

to simply run the scripts, use dago.

```bash
dagu start ./dags/deploy-maria-cluster.yaml
dagu stop ./dags/deploy.yaml
```

or run the server

```bash
dagu server --dags ./dags
```
