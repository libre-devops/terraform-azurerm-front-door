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
      email         = soa_record.value.email
      host_name     = soa_record.value.host_name
      serial_number = soa_record.value.serial_number
      expire_time   = soa_record.value.expire_time
      minimum_ttl   = soa_record.value.minimum_ttl
      refresh_time  = soa_record.value.refresh_time
      retry_time    = soa_record.value.retry_time
      ttl           = soa_record.value.ttl
      tags          = soa_record.value.tags
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each = var.create_front_door_custom_domain == true ? {
    for idx, value in var.front_door_custom_domain_options : value.name => merge(value, { index = idx })
  } : {}

  name                     = each.value.resource_name
  cdn_frontdoor_profile_id = try(each.value.cdn_frontdoor_profile_id, azurerm_cdn_frontdoor_profile.front_door_profile.id, null)
  dns_zone_id              = try(each.value.dns_zone_id, azurerm_dns_zone.dns_zones[each.key].id, null)
  host_name                = each.value.host_name


  dynamic "tls" {
    for_each = each.value.tls != null ? [each.value.tls] : []
    content {
      certificate_type        = tls.value.certificate_type
      minimum_tls_version     = tls.value.minimum_tls_version
      cdn_frontdoor_secret_id = try(tls.value.cdn_frontdoor_secret_id, null)
    }
  }
}

locals {
  front_door_route_keys = flatten([
    for index, domain in var.front_door_custom_domain_options : [
      for rule in domain.routing_rules : {
        domain_name = domain.name
        rule_name   = rule.name
        domain      = domain
        domain_name = domain.name
        rule        = rule
      }
    ]
  ])
}

resource "azurerm_cdn_frontdoor_route" "front_door_route" {
  for_each = var.create_front_door_custom_domain == true ? {
    for k, v in local.front_door_route_keys : k => v
  } : {}

  name                          = try(each.value.rule_name, null)
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.front_door_endpoint.id != null ? azurerm_cdn_frontdoor_endpoint.front_door_endpoint.id : try(each.value.cdn_frontdoor_endpoint_id, null)
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.front_door_origin_group.id != null ? azurerm_cdn_frontdoor_origin_group.front_door_origin_group.id : try(each.value.cdn_frontdoor_origin_group_id, null)
  cdn_frontdoor_origin_ids      = tolist([azurerm_cdn_frontdoor_origin.front_door_origin.id]) != null ? tolist([azurerm_cdn_frontdoor_origin.front_door_origin.id]) : try(tolist(each.value.cdn_frontdoor_origin_ids), null)
  cdn_frontdoor_rule_set_ids    = tolist([azurerm_cdn_frontdoor_rule_set.front_door_default_ruleset.id]) != null ? tolist([azurerm_cdn_frontdoor_rule_set.front_door_default_ruleset.id]) : try(tolist(each.value.cdn_frontdoor_origin_group_ids), null)
  enabled                       = try(each.value.enabled, true)

  forwarding_protocol    = try(each.value.rule.forwarding_protocol, null)
  https_redirect_enabled = try(each.value.rule.https_redirect_enabled, null)
  patterns_to_match      = try(tolist(each.value.rule.patterns_to_match), null)
  supported_protocols    = try(tolist(each.value.rule.supported_protocols), null)

  cdn_frontdoor_custom_domain_ids = tolist([azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value.domain_name].id]) != null ? tolist([azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value.domain_name].id]) : try(tolist(each.value.rule.cdn_frontdoor_custom_domain_ids), null)
  link_to_default_domain          = try(each.value.rule.link_to_default_domain, true)

  dynamic "cache" {
    for_each = each.value.rule.cache != null ? [each.value.rule.cache] : []
    content {
      query_string_caching_behavior = try(cache.value.query_string_caching_behavior, null)
      query_strings                 = try(tolist(cache.value.query_strings), null)
      compression_enabled           = try(cache.value.compression_enabled, null)
      content_types_to_compress     = try(tolist(cache.value.content_types_to_compress), null)
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  for_each = var.create_front_door_custom_domain == true && var.associate_custom_domain == true ? {
    for k, v in local.front_door_route_keys : k => v
  } : {}

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.value.domain_name].id
  cdn_frontdoor_route_ids        = tolist([azurerm_cdn_frontdoor_route.front_door_route[each.key].id])
}


