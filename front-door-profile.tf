resource "azurerm_cdn_frontdoor_profile" "front_door_profile" {
  name                     = var.front_door_name
  resource_group_name      = var.rg_name
  sku_name                 = var.front_door_sku_name
  response_timeout_seconds = var.front_door_response_timeout_seconds
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "front_door_endpoint" {
  name                     = var.front_door_endpoint_name == null ? "fdep-${var.front_door_name}" : try(var.front_door_endpoint_name, null)
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door_profile.id
  enabled                  = true
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "front_door_origin_group" {
  name                                                      = var.front_door_origin_group_name == null ? "fdog-${var.front_door_name}" : try(var.front_door_origin_group_name, null)
  cdn_frontdoor_profile_id                                  = azurerm_cdn_frontdoor_profile.front_door_profile.id
  session_affinity_enabled                                  = var.front_door_origin_group_session_affinity_enabled
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = var.front_door_origin_group_restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  dynamic "load_balancing" {
    for_each = try(var.load_balancing, null) != null ? [1] : []
    content {
      additional_latency_in_milliseconds = try(var.load_balancing["additional_latency_in_milliseconds"], null)
      sample_size                        = try(var.load_balancing["sample_size"], null)
      successful_samples_required        = try(var.load_balancing["successful_samples_required"], null)
    }
  }

  dynamic "health_probe" {
    for_each = try(var.health_probe, null) != null ? [1] : []
    content {
      protocol            = try(var.health_probe["protocol"], "Https", null)
      interval_in_seconds = try(var.health_probe["interval_in_seconds"], null)
      request_type        = try(var.health_probe["request_type"], "HEAD", null)
      path                = try(var.health_probe["path"], "/", null)
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "front_door_origin" {
  name                           = var.front_door_origin_name == null ? "fdor-${var.front_door_name}" : try(var.front_door_origin_name, null)
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.front_door_origin_group.id
  enabled                        = true
  host_name                      = var.front_door_target_app_hostname
  http_port                      = try(var.front_door_target_app_http_port, 80, null)
  https_port                     = try(var.front_door_target_app_https_port, 443, null)
  origin_host_header             = var.front_door_target_app_hostname
  priority                       = try(var.front_door_target_app_priority, null)
  weight                         = try(var.front_door_target_app_weight, null)
  certificate_name_check_enabled = try(var.front_door_target_app_certificate_name_check, true, null)

  dynamic "private_link" {
    for_each = try(var.private_link, null) != null ? [1] : []
    content {
      request_message        = try(var.private_link["request_message"], null)
      target_type            = try(var.private_link["target_type"], null)
      location               = try(var.private_link["location"], null)
      private_link_target_id = try(var.private_link["private_link_target_id"], null)
    }
  }
}
