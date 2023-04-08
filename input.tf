variable "identity_ids" {
  description = "Specifies a list of user managed identity ids to be assigned to the VM."
  type        = list(string)
  default     = []
}

variable "identity_type" {
  description = "The Managed Service Identity Type of this Virtual Machine."
  type        = string
  default     = ""
}

variable "front_door_origin_group_session_affinity_enabled" {
  description = "Whether session affinity is enabled in the origin group, defaults to true"
  type        = bool
  default     = true
}

variable "front_door_target_app_hostname" {
  description = "The host name of the application to sit behind the front door"
  type        = string
}

variable "front_door_target_app_http_port" {
  description = "The default http port for the target app"
  type        = number
  default     = 80
}

variable "front_door_target_app_https_port" {
  description = "The default https port for the target app"
  type        = number
  default     = 443
}


variable "front_door_target_app_priority" {
  description = "The priority for the target app"
  type        = number
  default     = 1
}

variable "create_front_door_rules" {
  description = "Whether front door rules should be made and added to the default ruleset"
  type        = bool
  default     = false
}

variable "create_front_door_firewall_rules" {
  description = "Whether you want to create firewall rules or not"
  type        = bool
  default     = true
}

variable "front_door_firewall_rules" {
  description = "The object which front door firewall rules must conform to"
  type = list(object({
    name                              = string
    mode                              = string
    redirect_url                      = string
    custom_block_response_status_code = number
    custom_block_response_body        = string

    custom_rule = optional(object({
      name     = optional(string)
      action   = optional(string)
      enabled  = optional(bool, true)
      priority = optional(number)
      type     = optional(string)
      match_condition = optional(object({
        match_variable     = string
        match_values       = list(string)
        operator           = string
        selector           = optional(string)
        negation_condition = optional(string)
        transforms         = optional(list(string), [])
      }))
      rate_limit_duration_in_minutes = optional(number)
      rate_limit_threshold           = optional(number)
    }))

    managed_rule = optional(object({
      type    = optional(string)
      version = optional(string, "2.1")
      action  = optional(string)
      override = object({
        rule_group_name = string
        exclusion = optional(object({
          match_variable = string
          operator       = string
          selector       = string
        }))
        rule = object({
          rule_id = string
          action  = string
          enabled = optional(bool, false)
          exclusion = optional(object({
            match_variable = string
            operator       = string
            selector       = string
          }))
        })
      })
      exclusion = optional(object({
        match_variable = string
        operator       = string
        selector       = string
      }))
    }))
  }))
}

variable "create_front_door_custom_domain" {
  description = "Whether a custom domain should be made or not"
  type = bool
  default = false
}

variable "front_door_rules" {
  description = "The object which front door routing rules must conform to"
  type = list(object({
    name               = string
    order              = number
    behaviour_on_match = string
    actions = optional(object({

      url_rewrite_action = optional(object({
        source_pattern          = optional(string)
        destination             = optional(string)
        preserve_unmatched_path = optional(bool)
      }))

      url_redirect_action = optional(object({
        redirect_type        = optional(string)
        destination_hostname = optional(string)
        redirect_protocol    = optional(string)
        destination_path     = optional(string)
        query_string         = optional(string)
        destination_fragment = optional(string)
      }))

      request_header_action = optional(object({
        header_action = optional(string)
        header_name   = optional(string)
        value         = optional(string)
      }))

      response_header_action = optional(object({
        header_action = optional(string)
        header_name   = optional(string)
        value         = optional(string)
      }))

      route_configuration_override_action = optional(object({
        cdn_frontdoor_origin_group_id = optional(string)
        forwarding_protocol           = optional(string)
        query_string_caching_behavior = optional(string)
        query_string_parameters       = optional(list(string))
        compression_enabled           = optional(bool)
        cache_behavior                = optional(string)
        cache_duration                = optional(string)
      }))
    }))

    conditions = optional(object({

      ssl_protocol_condition = optional(object({
        match_values     = optional(string, "TLSv1.2")
        operator         = optional(string)
        negate_condition = optional(bool)
      }))

      host_name_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(string)
      }))

      server_port_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      client_port_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      socket_address_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      remote_address_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      request_method_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      query_string_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      post_args_condition = optional(object({
        post_args_name   = optional(string, "POST")
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      request_uri_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      request_header_condition = optional(object({
        header_name      = optional(string)
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      request_body_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      request_scheme_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      url_path_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      url_file_extension_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      url_filename_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      http_version_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

      cookies_condition = optional(object({
        cookie_name      = optional(string)
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
        transforms       = optional(list(string))
      }))

      is_device_condition = optional(object({
        operator         = optional(string)
        negate_condition = optional(bool)
        match_values     = optional(list(string))
      }))

    }))
  }))
}

variable "front_door_default_rule_name" {
  description = "The name of the default rule"
  type        = string
  default     = null
}

variable "front_door_default_ruleset_name" {
  description = "The name of the default ruleset"
  type        = string
  default     = null
}

variable "front_door_target_app_weight" {
  description = "The weight for the target app"
  type        = number
  default     = 500
}

variable "front_door_route_name" {
  type        = string
  description = "The resource name of the front door route"
  default     = null
}

variable "cache" {
  description = "The cache block in the custom route"
  type        = any
  default     = null
}

variable "private_link" {
  description = "The private link block of the origin"
  type        = any
  default     = null
}

variable "front_door_target_app_certificate_name_check" {
  description = "Whether cert validation should happen on the app"
  type        = bool
  default     = true
}


variable "front_door_origin_name" {
  description = "The name of the front door origin resource (not the resource target"
  type        = string
  default     = null
}

variable "health_probe" {
  description = "The health probe block"
  type        = any
  default     = null
}

variable "front_door_origin_group_restore_traffic_time_to_healed_or_new_endpoint_in_minutes" {
  description = "ifies the amount of time which should elapse before shifting traffic to another endpoint when a healthy endpoint becomes unhealthy or a new endpoint is added."
  type        = number
  default     = 10
}

variable "front_door_custom_domain_options" {
  description = "The object which the DNS and custom domain resource conform to"
  default = []
  type = object({
    resource_name = string
    name = string
    domain_name = string
    host_name = string

    tls = object({
      certificate_type = optional(string)
      minimum_tls_version = optional(string, "TLS12")
      cdn_frontdoor_secret_id = optional(string)
    })

    soa_record = optional(object({
      email = optional(string)
      host_name = optional(string)
      serial_number = optional(string)
      expire_time = optional(number)
      minimum_ttl = optional(number)
      refresh_time = optional(number)
      retry_time = optional(number)
      ttl = optional(number)
      tags = optional(map(string))
    }))
  })
}


variable "front_door_endpoint_name" {
  description = "The name of the front door endpoint name"
  type        = string
  default     = null
}

variable "load_balancing" {
  description = "The load balanacing block of front door origin group"
  type        = any
  default     = null
}

variable "front_door_origin_group_name" {
  description = "The name of the front door origin group"
  type        = string
  default     = null
}

variable "front_door_name" {
  description = "The name of the front door resource"
  type        = string
}

variable "front_door_response_timeout_seconds" {
  description = "The response timeout in seconds of the front door resource"
  type        = number
  default     = 120
}

variable "front_door_sku_name" {
  description = "The name of the front door sku"
  type        = string
  default     = "Standard_AzureFrontDoor"
}

variable "location" {
  description = "The location for this resource to be put in"
  type        = string
}

variable "rg_name" {
  description = "The name of the resource group, this module does not create a resource group, it is expecting the value of a resource group already exists"
  type        = string
  validation {
    condition     = length(var.rg_name) > 1 && length(var.rg_name) <= 24
    error_message = "Resource group name is not valid."
  }
}

variable "tags" {
  type        = map(string)
  description = "A map of the tags to use on the resources that are deployed with this module."

  default = {
    source = "terraform"
  }
}
