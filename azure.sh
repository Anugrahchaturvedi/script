#!/bin/bash
rmtuname=devtron
tenant=aee9b2ed-7ecc-4cb2-bfed-6d0d71c0e957


echo "===== Performing az login using service principal ====="
az login --service-principal -u $1 -p $2 --tenant $tenant
echo "                        "


echo "========== Listing all VM already Present ============="
az vm list -o table
echo "                        "


echo "===== Enter a name of VM make sure it is not same as above listed VM ====="
read vm_name
echo "                        "


echo "=================== Creating VM ======================"
az vm create --name $vm_name --resource-group microk8s-dev --size Standard_D4ads_v5 --authentication-type ssh --admin-username $rmtuname --image UbuntuLTS --eviction-policy Deallocate --ssh-key-name devtron --public-ip-sku Standard --nic-delete-option Delete  --priority Spot --location eastus
echo "                        "


sleep 10


echo "======== Creating nsg rule to open all Ports ========="
az network nsg rule create --resource-group microk8s-dev --nsg-name $vm_name'NSG' --name allportallow --protocol "*" --source-port-range "*" --priority 100 --destination-address-prefix "*" --destination-port-range "*"
echo "                        "


public_IP=$(az vm show -d -g microk8s-dev --name $vm_name --query publicIps -o tsv)
echo "                        "


cat << 'EOF' > ./helper.sh
#!/bin/bash
sudo umount /mnt
sudo mkdir -p /var/snap/microk8s 
sudo mount /dev/sdb1  /var/snap/microk8s 
sudo sh -c "echo '/dev/sdb1  /var/snap/microk8s  ext4  defaults 0  0' >> /etc/fstab"
sudo snap install microk8s --classic --channel=1.22
echo "alias kubectl='microk8s kubectl '" >> ~/.bashrc
echo "alias helm='microk8s helm3 '" >> ~/.bashrc
source ~/.bashrc
sudo usermod -a -G microk8s devtron
sudo chown -f -R devtron ~/.kube
  newgrp microk8s << END
    microk8s enable dns
    microk8s enable storage
    microk8s enable helm3
  END
exit 0
EOF
chmod a+x helper.sh


echo "===== ssh into the VM ====="
scp -i devtron.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no helper.sh $rmtuname@$public_IP:/tmp/helper.sh
sleep 5
ssh -i devtron.pem -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $rmtuname@$public_IP 'cd /tmp; sh helper.sh;'
echo "                        "
echo "                        "
echo "Your VM public IP is : $public_IP"
echo "                        "
echo "                        "
echo "Command to ssh into the VM : ssh -i devtron.pem $rmtuname@$public_IP"
echo "                        "
echo "                        "
echo "Installation Complete"
