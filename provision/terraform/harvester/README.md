# Terrform for Harvester
1. Modify the secret with your kubeconfig downloaded from the support page
2. Modify variables.tf to match how you wish the nodes to looks like.
3. run terraform init & plan to initialize and check everything
4. Run ./tfapply.sh

### Layout
3 x masters: 4 Cores, 6 GB RAM, 30 GB HDD
3 x storage: 4 Cores, 6 GB RAM, 30 GB HDD, 50 GB HDD
3 x workers: 20 Cores, 16 GB RAM, 60 GB HDD
