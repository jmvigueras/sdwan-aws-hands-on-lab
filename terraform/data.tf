locals {
  ## Generate locals needed at modules ## 
  ## (NOT CHANGE) ##

  prefix       = "aws2024hol"
  keypair_name = aws_key_pair.keypair.key_name

  tags = {
    Owner   = local.user_id
    Project = local.prefix
  }

  #-----------------------------------------------------------------------------------------------------
  # SDWAN config (NOT CHANGE)
  #-----------------------------------------------------------------------------------------------------
  office_forti_spoke = {
    "id"      = local.tags["Owner"]
    "cidr"    = local.user_vpc_cidr
    "bgp_asn" = "65000"
  }

  # VPN HUB variables
  id                = "EMEA"
  hub_bgp_asn       = "65010"
  hub_cidr          = "10.10.0.0/16"
  hub_vpn_cidr      = "172.16.100.0/24" // VPN DialUp spokes cidr
  hub_vpn_ddns      = "eu-hub-vpn"
  route53_zone_name = "fortidemoscloud.com"
  hub_vpn_fqdn      = "${local.hub_vpn_ddns}.${local.route53_zone_name}"

  # Define SDWAN HUB EMEA CLOUD
  hubs = [
    {
      id            = local.id
      bgp_asn       = local.hub_bgp_asn
      external_fqdn = local.hub_vpn_fqdn
      hub_ip        = cidrhost(cidrsubnet(local.hub_vpn_cidr, 0, 0), 1)
      site_ip       = ""
      hck_ip        = cidrhost(cidrsubnet(local.hub_vpn_cidr, 0, 0), 1)
      vpn_psk       = local.externalid_token
      cidr          = local.hub_cidr
      sdwan_port    = "public"
    }
  ]

  #-----------------------------------------------------------------------------------------------------
  # FGT VPC and instance generic variables (NOT CHANGE)
  #-----------------------------------------------------------------------------------------------------
  admin_port    = "8443"
  admin_cidr    = "0.0.0.0/0"
  instance_type = "c6i.large"
  fgt_build     = "build1575"
  license_type  = "payg"
  faz_fqdn      = "faz.${local.route53_zone_name}"
  faz_sn        = ""

  # fgt_subnet_tags -> add tags to FGT subnets (port1, port2, public, private ...)
  fgt_subnet_tags = {
    "port1.public"  = "net-public"
    "port2.private" = "net-private"
  }

  # List of subnet names to create
  fgt_vpc_public_subnet_names  = [local.fgt_subnet_tags["port1.public"], "bastion"]
  fgt_vpc_private_subnet_names = [local.fgt_subnet_tags["port2.private"], "tgw"]

  # List of subnet names to add a route to FGT NI
  ni_rt_subnet_names = ["bastion", "tgw"]

  # Create map of RT IDs
  office_forti_ni_rt_ids = {
    for pair in setproduct(local.ni_rt_subnet_names, [for i, az in local.office_forti_azs : "az${i + 1}"]) :
    "${pair[0]}-${pair[1]}" => module.office_forti_vpc.rt_ids[pair[1]][pair[0]]
  }
  # Select primary AZ
  office_forti_azs = [data.aws_availability_zones.available.names[0]]

  lab_server_ip = "10.10.100.10"
  tag_student   = "please-use-owner-id"
}

#-----------------------------------------------------------------------------------------------------
# DATA (NOT CHANGE)
#-----------------------------------------------------------------------------------------------------
# Region AZs
data "aws_availability_zones" "available" {
  state = "available"
}