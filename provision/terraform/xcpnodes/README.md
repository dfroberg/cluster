# Terrform for XCP-NG 
1. Modify the secret with your XOA credentials
2. Modify main.tf and update the URL to point to your XOA
3. Modify variables.tf to match how you wish the nodes to looks like.
4. Run ./tfapply.sh

### Known Limitations
XCP-NG has a limit of MAX 3 MIGRATION operations at a time, which causes issues with terraform which has a default task concurrency of 10, 
I've set the concurrency to 1-2 just to avoid any and all such limits, takes a bit longer, just modify tfapply.sh to set it higher if you're in a hurry.

### Layout
3 x masters: 4 Cores, 6 GB RAM, 30 GB HDD
3 x storage: 4 Cores, 6 GB RAM, 30 GB HDD, 50 GB HDD
3 x workers: 20 Cores, 16 GB RAM, 60 GB HDD
