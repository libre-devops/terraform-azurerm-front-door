output "front_door_id" {
  description = "The ID of the Azure Front Door resource"
  value       = azurerm_cdn_frontdoor_profile.front_door_profile.id
}

output "front_door_resource_guid" {
  description = "The resource guid of the Azure Front Door resource"
  value       = azurerm_cdn_frontdoor_profile.front_door_profile.resource_guid
}

output "front_door_resource_rg_name" {
  description = "The resource_group name of the Azure Front Door resource"
  value       = azurerm_cdn_frontdoor_profile.front_door_profile.resource_group_name
}

output "front_door_endpoint_id" {
  description = "The id of the frontdoor endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.front_door_endpoint.id
}

output "front_door_endpoint_hostname" {
  description = "The hostname of the frontdoor endpoint"
  value       = azurerm_cdn_frontdoor_endpoint.front_door_endpoint.host_name
}

output "front_door_origin_group_id" {
  description = "The id of the origin group"
  value       = azurerm_cdn_frontdoor_origin_group.front_door_origin_group.id
}

output "front_door_origin_group_name" {
  description = "The name of the origin group"
  value       = azurerm_cdn_frontdoor_origin_group.front_door_origin_group.name
}

output "front_door_origin_id" {
  description = "The id of the front door origin"
  value       = azurerm_cdn_frontdoor_origin.front_door_origin.id
}

output "front_door_origin_name" {
  description = "The name of the front door origin"
  value       = azurerm_cdn_frontdoor_origin.front_door_origin.name
}

output "front_door_origin_private_link" {
  description = "The private link block of the front door origin if used"
  value       = azurerm_cdn_frontdoor_origin.front_door_origin.private_link
}


output "front_door_default_ruleset_id" {
  description = "The id of the default ruleset"
  value       = azurerm_cdn_frontdoor_rule_set.front_door_default_ruleset.id
}

output "front_door_default_ruleset_name" {
  description = "The name of the default ruleset"
  value       = azurerm_cdn_frontdoor_rule_set.front_door_default_ruleset.name
}
