resource "azurerm_dns_zone" "dns_zones" {
  for_each = var.create_front_door_custom_domain == true ? {
    for idx, value in var.front_door_custom_domain_options : value.name => merge(value, { index = idx })
  } : {}
  name                = each.value.domain_name
  resource_group_name = azurerm_cdn_frontdoor_profile.front_door_profile.resource_group_name
  tags                = try(var.tags, null)

  dynamic "soa_record" {
    for_each = each.value.soa_record != null ? [each.value.soa_record] : []
    content {
      email        = soa_record.value.email
      host_name    = soa_record.value.host_name
      serial_number = soa_record.value.serial_number
      expire_time  = soa_record.value.expire_time
      minimum_ttl  = soa_record.value.minimum_ttl
      refresh_time = soa_record.value.refresh_time
      retry_time   = soa_record.value.retry_time
      ttl          = soa_record.value.ttl
      tags         = soa_record.value.tags
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = var.create_front_door_custom_domain == true ? {
    for idx, value in var.front_door_firewall_rules : value.name => merge(value, { index = idx })
  } : {}

  name                     = each.value.resource_name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.front_door_profile.id
  dns_zone_id              = azurerm_dns_zone.dns_zones[each.key].id
  host_name                = each.value.host_name


  dynamic "tls" {
    for_each = each.value.tls != null ? [each.value.tls] : []
    content {
      certificate_type = tls.value.certificate_type
      minimum_tls_version = tls.value.minimum_tls_version
      cdn_frontdoor_secret_id = try(tls.value.cdn_frontdoor_secret_id, null)
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "front_door_route" {
    for_each = var.create_front_door_custom_domain == true ? {
    for idx, value in var.front_door_custom_domain_options : value.name => merge(value, { index = idx })
  } : {}
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.front_door_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.front_door_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.front_door_origin.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.front_door_default_ruleset.id]
  enabled                       = true

  forwarding_protocol    = each.value.forwarding_protocol
  https_redirect_enabled = each.value.https_redirect_enabled
  patterns_to_match      = each.value.patterns_to_match
  supported_protocols    = each.value.supported_protocols

  cdn_frontdoor_custom_domain_ids = tolist(azurerm_cdn_frontdoor_custom_domain.custom_domain.id)
  link_to_default_domain          = false

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  for_each = var.create_front_door_custom_domain == true ? {
    for idx, value in var.front_door_firewall_rules : value.name => merge(value, { index = idx })
  } : {}
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain.id
  cdn_frontdoor_route_ids        = []
}
