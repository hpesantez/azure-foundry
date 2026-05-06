output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "ai_hub_id" {
  value = azurerm_ai_foundry.hub.id
}

output "ai_project_id" {
  value = azurerm_ai_foundry_project.main.id
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "search_service_name" {
  value = azurerm_search_service.main.name
}
