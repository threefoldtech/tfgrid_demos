# Demos

### Run deployment of vm with gateway

1. export your mnemonic and network

```bash
export MNEMONIC="your mnemonic"
export NETWORK="you network to run on, [dev, qa, test, main]"
```

2. Run dagu server

```bash
dagu server --dags deployment
```

3. You can access dagu UI through `http://127.0.0.1:8080`
