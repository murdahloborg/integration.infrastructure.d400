#infrastructure data

data "azurerm_resource_group" "rg_infrastructure" {
  name = "rg-infrastructure-${var.az_subscription_name}"
}

data "azurerm_key_vault" "kv-infrastructure" {
    resource_group_name = data.azurerm_resource_group.rg_infrastructure.name
    name = "kv-infrastatic-${var.az_subscription_name}"
}

data "azurerm_key_vault_secret" "cert_int_domain" {
  name         = "multiwildcard-apiieweccocom"
  key_vault_id = data.azurerm_key_vault.kv-infrastructure.id
}

data "azurerm_dns_zone" "dns_int" {
  name                = "dev.apiiew.ecco.com"
  resource_group_name = data.azurerm_resource_group.rg_infrastructure.name
}

#int shared data
data "azurerm_resource_group" "rg_int" {
  name = "rg-integrationstatic"
}

data "azurerm_log_analytics_workspace" "law_int" {
    resource_group_name = data.azurerm_resource_group.rg_int.name
    name = "law-integrationstatic"
}

data "azurerm_virtual_network" "vnet_int" {
    resource_group_name = data.azurerm_resource_group.rg_int.name
    name = "vnet-integrationstatic"
}

data "azurerm_nat_gateway" "ngw_int" {
    resource_group_name = data.azurerm_resource_group.rg_int.name
    name = "nat-integrationstatic${var.az_subscription_name}Gateway"
}

data "azurerm_network_security_group" "nsg_int" {
    resource_group_name = data.azurerm_resource_group.rg_int.name
    name = "nsg-integrationstatic"
}

data "azurerm_container_registry" "acr_int" {
  name                = "caimagesintegrationstatic${var.az_subscription_name}"
  resource_group_name = data.azurerm_resource_group.rg_int.name
}