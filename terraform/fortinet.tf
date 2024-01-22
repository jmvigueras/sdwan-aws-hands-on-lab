#------------------------------------------------------------------------------
# Create FGT cluster EU
# - VPC
# - FGT NI and SG
# - FGT instance  jmvigueras/ftnt-modules/aws/
#------------------------------------------------------------------------------
# Create VPC for hub EU
module "office_forti_vpc" {
  source  = "jmvigueras/ftnt-modules/aws//modules/vpc"
  version = "0.0.3"

  prefix     = "${local.prefix}-${local.tags["Owner"]}-${random_string.random.result}"
  admin_cidr = local.admin_cidr
  region     = local.region
  azs        = local.office_forti_azs

  cidr = local.user_vpc_cidr

  public_subnet_names  = local.fgt_vpc_public_subnet_names
  private_subnet_names = local.fgt_vpc_private_subnet_names

  tags = local.tags
}
# Create FGT NIs
module "office_forti_nis" {
  source  = "jmvigueras/ftnt-modules/aws//modules/fgt_ni_sg"
  version = "0.0.3"

  prefix             = "${local.prefix}-${local.tags["Owner"]}-${random_string.random.result}"
  azs                = local.office_forti_azs
  vpc_id             = module.office_forti_vpc.vpc_id
  subnet_list        = module.office_forti_vpc.subnet_list
  fgt_subnet_tags    = local.fgt_subnet_tags
  fgt_number_peer_az = 1

  tags = local.tags
}
# Create FGT config peer each FGT
module "office_forti_config" {
  for_each = { for k, v in module.office_forti_nis.fgt_ports_config : k => v }

  source  = "jmvigueras/ftnt-modules/aws//modules/fgt_config"
  version = "0.0.3"

  admin_cidr     = local.admin_cidr
  admin_port     = local.admin_port
  rsa_public_key = trimspace(tls_private_key.ssh.public_key_openssh)
  api_key        = local.externalid_token

  ports_config = each.value
  fgt_id       = each.key
  ha_members   = module.office_forti_nis.fgt_ports_config

  config_spoke = true
  spoke        = local.office_forti_spoke
  hubs         = local.hubs

  config_fw_policy = false
  config_extra     = data.template_file.office_forti_config_extra[each.key].rendered

  config_faz = local.faz_fqdn != "" ? true : false
  faz_ip     = local.faz_fqdn
  faz_sn     = local.faz_sn

  static_route_cidrs = [local.office_forti_spoke["cidr"]]
}
# Data template extra-config fgt (Create new VIP to lab server and policies to allow traffic)
data "template_file" "office_forti_config_extra" {
  for_each = { for k, v in module.office_forti_nis.fgt_ports_config : k => v }

  template = file("./templates/fgt_config_student.tpl")
  vars = {
    external_ip   = element([for port in each.value : port["ip"] if port["tag"] == "public"], 0)
    mapped_ip     = cidrhost(module.office_forti_vpc.subnet_cidrs["az1"]["bastion"], 10)
    external_port = "80"
    mapped_port   = "80"
    public_port   = element([for port in each.value : port["port"] if port["tag"] == "public"], 0)
    private_port  = element([for port in each.value : port["port"] if port["tag"] == "private"], 0)
    suffix        = "80"
    lab_server_ip = local.lab_server_ip
    tag_student   = local.tag_student
  }
}
# Create FGT for hub EU
module "office_forti" {
  source  = "jmvigueras/ftnt-modules/aws//modules/fgt"
  version = "0.0.3"

  prefix        = "${local.prefix}-${local.tags["Owner"]}-${random_string.random.result}"
  region        = local.region
  instance_type = local.instance_type
  keypair       = local.keypair_name

  license_type = local.license_type
  fgt_build    = local.fgt_build

  fgt_ni_list = module.office_forti_nis.fgt_ni_list
  fgt_config  = { for k, v in module.office_forti_config : k => v.fgt_config }

  tags = local.tags
}
# Update private RT route RFC1918 cidrs to FGT NI and Core Network
module "office_forti_vpc_routes" {
  source  = "jmvigueras/ftnt-modules/aws//modules/vpc_routes"
  version = "0.0.3"

  ni_id     = module.office_forti_nis.fgt_ids_map["az1.fgt1"]["port2.private"]
  ni_rt_ids = local.office_forti_ni_rt_ids
}
# Crate test VM in bastion subnet
module "office_forti_vm" {
  source  = "jmvigueras/ftnt-modules/aws//modules/vm"
  version = "0.0.3"

  prefix          = "${local.prefix}-${local.tags["Owner"]}-${random_string.random.result}"
  keypair         = local.keypair_name
  subnet_id       = module.office_forti_vpc.subnet_ids["az1"]["bastion"]
  subnet_cidr     = module.office_forti_vpc.subnet_cidrs["az1"]["bastion"]
  security_groups = [module.office_forti_vpc.sg_ids["default"]]

  tags = local.tags
}