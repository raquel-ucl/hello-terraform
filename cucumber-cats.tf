# Configure Azure provider
provider "azurerm" {
  subscription_id = "${var.azure_subscription_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
  tenant_id       = "${var.azure_tenant_id}"
}

variable "resourcesname" {
  default = "helloterraform"
}

# create a resource group if it doesn't exist
resource "azurerm_resource_group" "helloterraform" {
    name = "helloterraform4"
    location = "ukwest"
}

# create virtual network
resource "azurerm_virtual_network" "helloterraformnetwork" {
    name = "tfvn"
    address_space = ["10.0.0.0/16"]
    location = "ukwest"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
}

# create subnet
resource "azurerm_subnet" "helloterraformsubnet" {
    name = "tfsub"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    virtual_network_name = "${azurerm_virtual_network.helloterraformnetwork.name}"
    address_prefix = "10.0.2.0/24"
    #network_security_group_id = "${azurerm_network_security_group.helloterraformnsg.id}"
}

#resource "azurerm_network_security_group" "helloterraformnsg" {
#  name                = "securityGroup"
#  location            = "ukwest"
#  resource_group_name = "${azurerm_resource_group.helloterraform.name}"

#  security_rule {
#    name                       = "HTTP5000"
#    priority                   = 1010
#    direction                  = "Inbound"
#    access                     = "Allow"
#    protocol                   = "Tcp"
#    source_port_range          = "*"
#    destination_port_range     = "5000"
#    source_address_prefix      = "*"
#    destination_address_prefix = "*"
#  }
#
#  tags {
#    environment = "staging"
#  }
#}

# create public IPs
resource "azurerm_public_ip" "helloterraformips" {
    name = "terraformtestip"
    location = "ukwest"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    public_ip_address_allocation = "dynamic"
    domain_name_label = "helloterraform4"

    tags {
        environment = "TerraformDemo"
    }
}

# create network interface
resource "azurerm_network_interface" "helloterraformnic" {
    name = "tfni"
    location = "ukwest"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"

    ip_configuration {
        name = "testconfiguration1"
        subnet_id = "${azurerm_subnet.helloterraformsubnet.id}"
        private_ip_address_allocation = "static"
        private_ip_address = "10.0.2.5"
        public_ip_address_id = "${azurerm_public_ip.helloterraformips.id}"
    }
}

# create storage account
resource "azurerm_storage_account" "helloterraformstorage" {
    name = "terraformstorage12"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    location = "ukwest"
    account_type = "Standard_LRS"

    tags {
        environment = "staging"
    }
}

# create storage container
resource "azurerm_storage_container" "helloterraformstoragestoragecontainer" {
    name = "vhd"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    storage_account_name = "${azurerm_storage_account.helloterraformstorage.name}"
    container_access_type = "private"
    depends_on = ["azurerm_storage_account.helloterraformstorage"]
}



# create virtual machine
resource "azurerm_virtual_machine" "helloterraformvm" {
    name = "terraformvm"
    location = "ukwest"
    resource_group_name = "${azurerm_resource_group.helloterraform.name}"
    network_interface_ids = ["${azurerm_network_interface.helloterraformnic.id}"]
    vm_size = "Standard_A0"

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }

    storage_os_disk {
        name = "myosdisk2"
        vhd_uri = "${azurerm_storage_account.helloterraformstorage.primary_blob_endpoint}${azurerm_storage_container.helloterraformstoragestoragecontainer.name}/myosdisk2.vhd"
        caching = "ReadWrite"
        create_option = "FromImage"
    }

    os_profile {
        computer_name = "hostname"
        admin_username = "testadmin"
        admin_password = "Password1234"
    }

    os_profile_linux_config {
      disable_password_authentication = false
      ssh_keys = [{
        path     = "/home/testadmin/.ssh/authorized_keys"
        key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIjSk9W1iu8Nq01i0Ng/U4L+nFPHpU44czXqnY8I9+szOo8ZpbvaoC52hVFQRCmsGTiPhLJYzhUR90DGyXDC9+1tpybHrDO4VvabuLnae/8I2QkGbbrDPm3iNFgmx01N4odUwAn7bi5S49e0fSqnzJkNDNUXf+wtIpvgxxXM6rMBr3nWR/OYHvo1/ZGaFbtS9wKvQHn7fP8OmiJnCnfGCJfT2UylyRAjKb5D9PnrRSgsrWBbUGrwq7svuG+tNtRI+w97f//evKubyUGBNeaOSbtlhu7pPWDtvyCcYAWaRcAusdS4C9KClX/y/gvg4Zyrlh3/jSwLsY1gpZlHHWFjjSKpQz25FvGNJbGkYaVSzfHDUN3VSJZgJO5oX8W0tsYbDuKSBSADSP/D3BjJD11RhUXv0DSB9mhdXbemyVdS9QkBdBhJLxzQ8AVYwiXmTJRP99Y5AS0+UQJqO40u/aWkevUziWDfUj1uB+vylQDmg7qDDcG6ZDMX7EAcmRLhII+U/rc0QVRPQqYB+HC1fWKqyans/D0wgMvmfvjz0aohg97wbvQoldeZHbi/7wLHFFKtlDGiEJYPDR4iOHQQ4kG5ZRv5CYMI88km9rE9Ode2KqIKFRRgFfTJFzE52EpHMBcWcggK0Ua6+vaZ8SfKPg76JFnOluCIGQz+Z3BVDWR89yTQ== r.alegre@ucl.ac.uk"
      }]
    }

#    provisioner "local-exec" {
#        command = "git clone https://github.com/UCL-CloudLabs/Docker-sample.git"
#    }

    connection {
        # host = "${azurerm_public_ip.helloterraformips}"
        host = "helloterraform4.ukwest.cloudapp.azure.com"
        #host = "/subscriptions/962877a6-abbd-4d1f-93e2-3d8094dc6682/resourceGroups/terraformtest/providers/Microsoft.Network/publicIPAddresses/terraformtestip"
        user = "testadmin"
      #  password = "Password1234"
        type = "ssh"
        private_key = "${file("~/.ssh/id_rsa_unencrypt")}"
       timeout = "1m"
        agent = true
    }

    provisioner "remote-exec" {
        inline = [
          "sudo apt-get install docker.io -y",
          "git clone https://github.com/UCL-CloudLabs/Docker-sample.git",
          "cd Docker-sample",
          "sudo docker build -t hello-flask .",
          "sudo docker run -p 5000:5000 hello-flask"
        ]


    }

    tags {
        environment = "staging"
    }
}
