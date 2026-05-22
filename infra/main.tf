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

# 2. Create Azure AD app/service principal
data "azuread_client_config" "current" {}

resource "azuread_application" "keda-example" {
  display_name = "keda-example"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "keda-example" {
  client_id                    = azuread_application.keda-example.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "keda-example" {
  service_principal_id = azuread_service_principal.keda-example.id
  end_date             = "2099-12-31T23:59:59Z"
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

# 5. Allow the Service Principal to manage the Service Bus Namespace
resource "azurerm_role_assignment" "service_principal_role_assignment" {
  scope                = azurerm_servicebus_namespace.sb_namespace.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = azuread_service_principal.keda-example.object_id
}

# Utility to generate a unique string for the Service Bus namespace name
resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

# Outputs to verify details after creation
output "service_principal_client_id" {
  value       = azuread_service_principal.keda-example.client_id
  description = "The Client ID of the Service Principal."
}

output "service_principal_password" {
  value       = azuread_service_principal_password.keda-example.value
  description = "The password for the Service Principal."
  sensitive   = true
}

output "current_tenant_id" {
  value = data.azuread_client_config.current.tenant_id
}

output "service_bus_namespace_name" {
  value       = azurerm_servicebus_namespace.sb_namespace.name
  description = "The name of the Service Bus Namespace."
}

output "service_bus_queue_name" {
  value       = azurerm_servicebus_queue.sb_queue.name
  description = "The name of the Service Bus Queue."
}