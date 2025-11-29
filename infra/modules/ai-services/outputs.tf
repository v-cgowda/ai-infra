# AI Services Module Outputs

output "form_recognizer_service" {
  description = "Azure Form Recognizer service information"
  value = length(azurerm_cognitive_account.form_recognizer) > 0 ? {
    id       = azurerm_cognitive_account.form_recognizer[0].id
    name     = azurerm_cognitive_account.form_recognizer[0].name
    endpoint = azurerm_cognitive_account.form_recognizer[0].endpoint
    key      = azurerm_cognitive_account.form_recognizer[0].primary_access_key
  } : null
  sensitive = true
}

output "computer_vision_service" {
  description = "Azure Computer Vision service information"
  value = length(azurerm_cognitive_account.computer_vision) > 0 ? {
    id       = azurerm_cognitive_account.computer_vision[0].id
    name     = azurerm_cognitive_account.computer_vision[0].name
    endpoint = azurerm_cognitive_account.computer_vision[0].endpoint
    key      = azurerm_cognitive_account.computer_vision[0].primary_access_key
  } : null
  sensitive = true
}
