# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 1. Create the Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "keda_experiments-rg"
  location = "East US"
}

# 2. Create the User Assigned Managed Identity (UAMI)
resource "azurerm_user_assigned_identity" "uami" {
  name                = "keda-experiments-uami"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# 3. Create the Service Bus Namespace
resource "azurerm_servicebus_namespace" "sb_namespace" {
  name                = "keda-experiments-${random_string.unique.result}" # Must be globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard" # Options: Basic, Standard, Premium
}

# 4. Create a Service Bus Queue inside the Namespace
resource "azurerm_servicebus_queue" "sb_queue" {
  name         = "orders-queue"
  namespace_id = azurerm_servicebus_namespace.sb_namespace.id
}

# Utility to generate a unique string for the Service Bus namespace name
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

# Outputs to verify details after creation
output "uami_client_id" {
  value       = azurerm_user_assigned_identity.uami.client_id
  description = "The Client ID of the Managed Identity."
}

output "service_bus_endpoint" {
  value       = azurerm_servicebus_namespace.sb_namespace.endpoint
  description = "The primary endpoint of the Service Bus Namespace."
}