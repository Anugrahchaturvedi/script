# script
### To run microk8s Cluster into the VM script 
#### steps 1 - Switch to the Directory where private key(.pem) is stored
#### step 2- run the script with 2 agruements


```bash
sh azure.sh <service principal username> <service principal password>
```
###### NOTE: By default script uses ``devtron.pem`` private key to create VM, if you want some other key to use kindly make neccessary changes in the Script.
