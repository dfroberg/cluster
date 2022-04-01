helm repo update && helm template crowdsec/crowdsec > test.yaml && kubectl apply -f test.yaml --dry-run=client
