variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID to deploy environment into."
}

variable "region" {
  type    = string
  default = "centralus"
  description = "Azure region to deploy resources."
}
variable "cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Network range for created virtual network."
}