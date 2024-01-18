resource "azurerm_dns_cname_record" "dns_int_cname_producer" {
  name                = "ca-producer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  zone_name           = data.azurerm_dns_zone.dns_int.name
  resource_group_name = data.azurerm_dns_zone.dns_int.resource_group_name
  ttl                 = 300
  record              = "anewapp.${jsondecode(azapi_resource.cae_env.output).properties.defaultDomain}"
}


resource "azurerm_dns_txt_record" "dns_int_txt_producer" {
  name                = "asuid.ca-producer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  zone_name           = data.azurerm_dns_zone.dns_int.name
  resource_group_name = data.azurerm_dns_zone.dns_int.resource_group_name
  ttl                 = 300

  record {
    value = jsondecode(azapi_resource.cae_env.output).properties.customDomainConfiguration.customDomainVerificationId
  }
}

resource "azapi_resource" "containerapp_producer" {
  type      = "Microsoft.App/containerApps@2023-05-01"
  name      = "ca-producer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
  parent_id = azurerm_resource_group.rg_env.id
  location  = azurerm_resource_group.rg_env.location
  count     = var.producer_image != "" ? 1 : 0
 
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.cae_env.id
      configuration = {
        ingress = {
          external : true,
          targetPort : 8080

          customDomains = [
            {
              bindingType = "SniEnabled"
              certificateId = azurerm_container_app_environment_certificate.ca_certificate_domain_env.id
              name = "ca-producer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}.${data.azurerm_dns_zone.dns_int.name}"
            }
          ]
        }
        registries: [
            {
                server: data.azurerm_container_registry.acr_int.login_server
                username: data.azurerm_container_registry.acr_int.admin_username
                passwordSecretRef: "acr-pwdref-ca-consumer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
                identity: ""
            }
        ]
        secrets : [
          {
            name = "acr-pwdref-ca-consumer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
            # Todo: Use Managed Identity connection to ACR
            value = data.azurerm_container_registry.acr_int.admin_password
          }
        ]
      }
      template = {
        containers = [
          {
            image = var.producer_image
            name  = "ca-producer-${var.az_env_name}-${var.az_subscription_name}-${var.az_env_sufix}"
            env : [
              {
                name  = "ASPNETCORE_ENVIRONMENT"
                value = title(var.az_subscription_name)
              }
            ]
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    } 
  })
  depends_on = [
    azapi_resource.cae_env, azurerm_dns_cname_record.dns_int_cname_producer, azurerm_dns_txt_record.dns_int_txt_producer
  ]
}