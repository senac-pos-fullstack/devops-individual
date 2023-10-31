# Define a provider para a Azure
provider "azurerm" {
  features {}
}

# Define um recurso de grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = "my-resource-group"
  location = "East US"
}

# Define uma rede virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/22"]
}

# Cria uma subnet para os servidores
resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}


### --- APP --- ###

# Cria um endereço IP público para o servidor de aplicação
resource "azurerm_public_ip" "app-publicip" {
  name                = "app-publicip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Cria um servidor de aplicação
resource "azurerm_linux_virtual_machine" "app" {
  name                  = "app-server"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.app.id]
  size                  = "Standard_B1ms"  

  os_disk {
    name              = "app-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") 
  }
}

# Cria uma rede de interface para o servidor de aplicação
resource "azurerm_network_interface" "app" {
  name                = "app-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "app-interno"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app-publicip.id
  }
}

### --- MONGODB --- ###

# Cria um endereço IP público para o servidor mongodb
resource "azurerm_public_ip" "mongo-publicip" {
  name                = "mongo-publicip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Cria um servidor de mongodb
resource "azurerm_linux_virtual_machine" "mongo" {
  name                  = "mongo-server"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.mongo.id]
  size                  = "Standard_B1ms"  

  os_disk {
    name              = "mongo-osdisk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_username = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") 
  }
}

# Cria uma rede de interface para o servidor de mongodb
resource "azurerm_network_interface" "mongo" {
  name                = "mongo-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "mongo-interno"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mongo-publicip.id
  }
}