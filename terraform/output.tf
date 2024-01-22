output "student_fortigate" {
  value = {
    mgmt_url  = "https://${module.office_forti_nis.fgt_eips_map["az1.fgt1.port1.public"]}:8443"
    fgt_user = "admin"
    fgt_pass = "${module.office_forti.fgt_peer_az_ids["az1.fgt1"]}"
  }
}

output "student_vm" {
  value = module.office_forti_vm.vm
}