variable "subscription_id" {
  description = "Azure subscription ID for the state backend"
  type        = string
}

variable "location" {
  description = "Azure region for the state backend resources"
  type        = string
  default     = "eastus2"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "foundry"
}
