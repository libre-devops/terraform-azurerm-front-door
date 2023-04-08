resource "azurerm_cdn_frontdoor_firewall_policy" "default_firewall_policy" {
  for_each = var.create_front_door_firewall_rules == true ? {
    for idx, value in var.front_door_firewall_rules : value.name => merge(value, { index = idx })
  } : {}

  name                              = each.key
  resource_group_name               = azurerm_cdn_frontdoor_profile.front_door_profile.resource_group_name
  sku_name                          = azurerm_cdn_frontdoor_profile.front_door_profile.sku_name
  enabled                           = true
  tags                              = var.tags
  mode                              = each.value.mode
  redirect_url                      = each.value.redirect_url
  custom_block_response_status_code = each.value.custom_block_response_status_code
  custom_block_response_body        = each.value.custom_block_response_body

  dynamic "custom_rule" {
    for_each = each.value.custom_rule != null ? [each.value.custom_rule] : []
    content {
      name                           = custom_rule.value.name
      action                         = custom_rule.value.action
      enabled                        = custom_rule.value.enabled
      priority                       = custom_rule.value.priority
      type                           = custom_rule.value.type
      rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
      rate_limit_threshold           = custom_rule.value.rate_limit_threshold

      dynamic "match_condition" {
        for_each = custom_rule.value.match_condition != null ? [custom_rule.value.match_condition] : []
        content {
          match_variable     = match_condition.value.match_variable
          match_values       = match_condition.value.match_values
          operator           = match_condition.value.operator
          selector           = match_condition.value.selector
          negation_condition = match_condition.value.negation_condition
          transforms         = match_condition.value.transforms
        }
      }
    }
  }

  dynamic "managed_rule" {
    for_each = each.value.managed_rule != null ? [each.value.managed_rule] : []
    content {
      type    = managed_rule.value.type
      version = managed_rule.value.version
      action  = managed_rule.value.action

      dynamic "override" {
        for_each = managed_rule.value.override != null ? [managed_rule.value.override] : []
        content {
          rule_group_name = override.value.rule_group_name

          dynamic "exclusion" {
            for_each = override.value.exclusion != null ? [override.value.exclusion] : []
            content {
              match_variable = exclusion.value.match_variable
              operator       = exclusion.value.operator
              selector       = exclusion.value.selector
            }
          }

          dynamic "rule" {
            for_each = override.value.rule != null ? [override.value.rule] : []
            content {
              rule_id = rule.value.rule_id
              action  = rule.value.action
              enabled = rule.value.enabled

              dynamic "exclusion" {
                for_each = rule.value.exclusion != null ? [rule.value.exclusion] : []
                content {
                  match_variable = exclusion.value.match_variable
                  operator       = exclusion.value.operator
                  selector       = exclusion.value.selector
                }
              }
            }
          }
        }
      }

      dynamic "exclusion" {
        for_each = managed_rule.value.exclusion != null ? [managed_rule.value.exclusion] : []
        content {
          match_variable = exclusion.value.match_variable
          operator       = exclusion.value.operator
          selector       = exclusion.value.selector
        }
      }
    }
  }
}

