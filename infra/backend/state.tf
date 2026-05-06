resource "azurerm_resource_group" "state" {
  name     = "rg-${var.project_name}-state"
  location = var.location

  tags = {
    purpose = "terraform-state"
    project = var.project_name
  }
}

resource "azurerm_storage_account" "state" {
  name                     = "st${var.project_name}tfstate"
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = azurerm_resource_group.state.tags
}

resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}
