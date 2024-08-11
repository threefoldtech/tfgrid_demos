# monitored mariadb cluster

demo deploying a full mariadb cluster exposing its metrics with mysql exporter to be scrapped by prometheus and visualize a simple dashboard with grafana.

## image

- [monitored mariadb cluster image](https://github.com/threefoldtech/tf-images/tree/development/tfgrid3/monitored_mariadb)
- [flist](https://hub.grid.tf/omarabdulaziz.3bot/omarabdul3ziz-tfgrid_mariadb_demo-latest.flist)

## deployment

it uses the terraform client with this script ./tf/main.tf which will deploy the flist with public ip and expose with domain name

### ports

- `3000`: to access the grafana dashboard
- `9090`: to access prometheus web ui
- the output domain name will point to grafana dashboard

## usage

to simply run the scripts, use dago.

```bash
dagu start ./dags/deploy.yaml
dagu stop ./dags/deploy.yaml
```

or run the server

```bash
dagu server --dags ./dags
```
