variables {
  dns_zone      = "angelanampa.dev"
  app_subdomain = "peaceapp"
}

run "dominios_del_producto" {
  command = plan

  assert {
    condition     = output.frontend_domain == "peaceapp.angelanampa.dev"
    error_message = "El front debe vivir en peaceapp.<zona>"
  }
  assert {
    condition     = output.api_domain == "api.peaceapp.angelanampa.dev"
    error_message = "La API debe vivir en api.peaceapp.<zona>"
  }
}

run "registros_apuntan_al_ingress" {
  command = plan

  variables {
    ingress_ip = "20.1.2.3"
  }

  assert {
    condition     = alltrue([for r in output.dns_records : r.value == "20.1.2.3"]) && length(output.dns_records) == 2
    error_message = "Los dos registros A deben apuntar a la IP del ingress."
  }
}
