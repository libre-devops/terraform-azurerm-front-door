module "rg" {
  source = "registry.terraform.io/libre-devops/rg/azurerm"

  rg_name  = "rg-${var.short}-${var.loc}-${terraform.workspace}-build" // rg-ldo-euw-dev-build
  location = local.location                                            // compares var.loc with the var.regions var to match a long-hand name, in this case, "euw", so "westeurope"
  tags     = local.tags

  #  lock_level = "CanNotDelete" // Do not set this value to skip lock
}

module "network" {
  source = "registry.terraform.io/libre-devops/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name     = "vnet-${var.short}-${var.loc}-${terraform.workspace}-01" // vnet-ldo-euw-dev-01
  vnet_location = module.network.vnet_location

  address_space = ["10.0.0.0/16"]
  subnet_prefixes = [
    "10.0.0.0/24",
    "10.0.1.0/24",
  ]

  subnet_names = [
    "sn1-${module.network.vnet_name}",
    "sn2-${module.network.vnet_name}",
  ]

  subnet_service_endpoints = {
    "sn1-${module.network.vnet_name}" = ["Microsoft.Storage", "Microsoft.Keyvault", "Microsoft.Sql", "Microsoft.Web", "Microsoft.AzureActiveDirectory"],
    "sn2-${module.network.vnet_name}" = ["Microsoft.Storage", "Microsoft.Keyvault", "Microsoft.Sql", "Microsoft.Web", "Microsoft.AzureActiveDirectory"]
  }

  subnet_delegation = {
    "sn1-${module.network.vnet_name}" = {
      "Microsoft.Web/serverFarms" = {
        service_name    = "Microsoft.Web/serverFarms"
        service_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

# Create a NSG with an explict deny at 4096, since this environment needs 5 NSGs, count is set to 5
module "nsg" {
  source   = "registry.terraform.io/libre-devops/nsg/azurerm"
  count    = 2
  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  nsg_name  = "nsg-${var.short}-${var.loc}-${terraform.workspace}-${format("%02d", count.index + 1)}" // nsg-ldo-euw-dev-01 - the format("%02d") applies number padding e.g 1 = 01, 2 = 02
  subnet_id = element(values(module.network.subnets_ids), count.index)
}

resource "azurerm_network_security_rule" "vnet_inbound" {
  count = 2 # can't use length() of subnet ids as not known till apply

  name                        = "AllowVnetInbound"
  priority                    = "149"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = module.rg.rg_name
  network_security_group_name = module.nsg[count.index].nsg_name
}


resource "azurerm_network_security_rule" "bastion_inbound" {
  count = 2 # can't use length() of subnet ids as not known till apply

  name                        = "AllowSSHRDPInbound"
  priority                    = "150"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["22", "3389"]
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "VirtualNetwork"
  resource_group_name         = module.rg.rg_name
  network_security_group_name = module.nsg[count.index].nsg_name
}

module "law" {
  source = "registry.terraform.io/libre-devops/log-analytics-workspace/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  create_new_workspace       = true
  law_name                   = "law-${var.short}-${var.loc}-${terraform.workspace}-01"
  law_sku                    = "PerGB2018"
  retention_in_days          = "30"
  daily_quota_gb             = "0.5"
  internet_ingestion_enabled = true
  internet_query_enabled     = true
}

// This module does not consider for CMKs and allows the users to manually set bypasses
#checkov:skip=CKV2_AZURE_1:CMKs are not considered in this module
#checkov:skip=CKV2_AZURE_18:CMKs are not considered in this module
#checkov:skip=CKV_AZURE_33:Storage logging is not configured by default in this module
#tfsec:ignore:azure-storage-queue-services-logging-enabled tfsec:ignore:azure-storage-allow-microsoft-service-bypass #tfsec:ignore:azure-storage-default-action-deny
module "sa" {
  source = "registry.terraform.io/libre-devops/storage-account/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  storage_account_name            = "st${var.short}${var.loc}${terraform.workspace}01"
  access_tier                     = "Hot"
  identity_type                   = "SystemAssigned"
  allow_nested_items_to_be_public = true

  storage_account_properties = {

    // Set this block to enable network rules
    network_rules = {
      default_action = "Allow"
    }

    blob_properties = {
      versioning_enabled       = false
      change_feed_enabled      = false
      default_service_version  = "2020-06-12"
      last_access_time_enabled = false

      deletion_retention_policies = {
        days = 10
      }

      container_delete_retention_policy = {
        days = 10
      }
    }

    routing = {
      publish_internet_endpoints  = false
      publish_microsoft_endpoints = true
      choice                      = "MicrosoftRouting"
    }
  }
}

module "plan" {
  source = "registry.terraform.io/libre-devops/service-plan/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  app_service_plan_name          = "asp-${var.short}-${var.loc}-${terraform.workspace}-01"
  add_to_app_service_environment = false

  os_type  = "Linux"
  sku_name = "P1v3"
}

#checkov:skip=CKV2_AZURE_145:TLS 1.2 is allegedly the latest supported as per hashicorp docs
module "fnc_app" {
  source = "libre-devops/linux-function-app/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  app_name        = "fnc-${var.short}-${var.loc}-${terraform.workspace}-01"
  service_plan_id = module.plan.service_plan_id

  connect_app_insights_to_law_workspace = true
  enable_app_insights                   = true
  workspace_id                          = module.law.law_id
  app_insights_name                     = "appi-${var.short}-${var.loc}-${terraform.workspace}-01"
  app_insights_type                     = "web"

  function_app_vnet_integration_enabled   = true
  function_app_vnet_integration_subnet_id = element(values(module.network.subnets_ids), 0)


  app_settings = {
    ARM_SUBSCRIPTION_ID = data.azurerm_client_config.current_creds.subscription_id
    ARM_TENANT_ID       = data.azurerm_client_config.current_creds.tenant_id
    FUNCTION_APP_NAME   = "fnc-${var.short}-${var.loc}-${terraform.workspace}-01"
    RESOURCE_GROUP_NAME = module.rg.rg_name
  }

  storage_account_name          = module.sa.sa_name
  storage_account_access_key    = module.sa.sa_primary_access_key
  storage_uses_managed_identity = true

  identity_type = "SystemAssigned"

  functions_extension_version = "~4"

  settings = {
    site_config = {
      minimum_tls_version = "1.2"
      http2_enabled       = true

      application_stack = {
        python_version = 3.9
      }
    }

    auth_settings = {
      enabled                       = false
      runtime_version               = "~1"
      unauthenticated_client_action = "AllowAnonymous"
    }
  }
}

module "front_door" {
  source = "libre-devops/front-door/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  front_door_name = "fd-${var.short}-${var.loc}-${terraform.workspace}-01"

  front_door_target_app_hostname = module.fnc_app.default_hostname
  front_door_sku_name            = "Premium_AzureFrontDoor"

  load_balancing = {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }

  create_front_door_rules = true
  front_door_rules = [
    {
      name               = "rule1"
      order              = 1
      behaviour_on_match = "continue"
      actions = {
        url_rewrite_action = {
          source_pattern          = "/source-path/(.*)"
          destination             = "/destination-path/$1"
          preserve_unmatched_path = true
        }
      }

      conditions = {
        request_method_condition = {
          operator         = "Equal"
          negate_condition = false
          match_values     = ["GET"]
        }

        url_path_condition = {
          operator         = "Equal"
          negate_condition = false
          match_values     = ["old-path/*"]
          transforms       = ["Lowercase"]
        }
      }
    },
    {
      name               = "rule2"
      order              = 2
      behaviour_on_match = "continue"
      actions = {
        url_redirect_action = {
          redirect_type        = "PermanentRedirect"
          destination_hostname = "www.example.com"
          redirect_protocol    = "Https"
          destination_path     = "/new-path"
          query_string         = "preserve"
          destination_fragment = "preserve"
        }
      }

      conditions = {
        remote_address_condition = {
          operator         = "IPMatch"
          negate_condition = false
          match_values     = ["192.0.2.0/24"]
        }

        is_device_condition = {
          operator         = "Equal"
          negate_condition = false
          match_values     = ["Mobile"]
        }
      }
    }
  ]

  create_front_door_firewall_rules = true
  front_door_firewall_rules = [
    {
      name                              = "fwrule1"
      mode                              = "Prevention"
      redirect_url                      = "https://www.example.com/blocked"
      custom_block_response_status_code = 403
      custom_block_response_body        = base64encode("This request is blocked by the firewall.")

      custom_rule = {
        name                           = "CustomRule1"
        action                         = "Block"
        enabled                        = true
        priority                       = 100
        type                           = "RateLimitRule"
        rate_limit_duration_in_minutes = 1
        rate_limit_threshold           = 10
        match_condition = {
          match_variable     = "RemoteAddr"
          match_values       = ["192.0.2.0/24"]
          operator           = "IPMatch"
          negation_condition = false
        }
      }

      managed_rule = {
        type    = "DefaultRuleSet"
        version = "1.0"
        action  = "Allow"
        exclusion = {
          match_variable = "RequestHeaderNames"
          operator       = "Contains"
          selector       = "UserAgent"
        }
      }
    }
  ]

  create_front_door_custom_domain = true
  front_door_custom_domain_options = [
    {
      resource_name          = "example-frontdoor-custom-domain"
      name                   = "libredevops-cloud"
      domain_name            = "libredevops.cloud"
      host_name              = "www.libredevops.cloud"
      link_to_default_domain = false

      tls = {
        certificate_type        = "ManagedCertificate"
        minimum_tls_version     = "TLS12"
        cdn_frontdoor_secret_id = null
      }

      soa_record = {
        email         = "admin.libredevops.cloud"
        host_name     = "ns1.libredevops.cloud"
        serial_number = "1"
        expire_time   = 1209600
        minimum_ttl   = 3600
        refresh_time  = 604800
        retry_time    = 86400
        ttl           = 3600
        tags          = { "example" = "value" }
      }

      routing_rules = [
        {
          name                   = "route1"
          enabled                = true
          forwarding_protocol    = "MatchRequest"
          https_redirect_enabled = "true"
          patterns_to_match      = ["/*"]
          supported_protocols    = ["Http", "Https"]
        },
        {
          name                   = "route2"
          enabled                = true
          forwarding_protocol    = "MatchRequest"
          https_redirect_enabled = "true"
          patterns_to_match      = ["/images/*"]
          supported_protocols    = ["Http", "Https"]
        }
      ]
    }
  ]
}
