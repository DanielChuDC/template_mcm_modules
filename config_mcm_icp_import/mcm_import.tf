resource "null_resource" "mkdir-mcm-scripts" {
  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${length(var.vm_os_private_key) > 0 ? base64decode(var.vm_os_private_key) : ""}"
    host = "${var.import_launch_node_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"          
  }
    provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /var/lib/registry/mcm_scripts",
      "sudo chown $(whoami) /var/lib/registry/mcm_scripts"
    ]
  }
}

resource "null_resource" "import_icp" {
  depends_on = ["null_resource.mkdir-mcm-scripts"]
  connection {
    type = "ssh"
    user = "${var.vm_os_user}"
    password =  "${var.vm_os_password}"
    private_key = "${length(var.vm_os_private_key) > 0 ? base64decode(var.vm_os_private_key) : ""}"
    host = "${var.import_launch_node_ip}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_host_key    = "${var.bastion_host_key}"
    bastion_password    = "${var.bastion_password}"          
  }
  
  provisioner "file" {
    source = "${path.module}/scripts/mcm_import_prereq.sh"
    destination = "/var/lib/registry/mcm_scripts/mcm_import_prereq.sh"
  }

  provisioner "file" {
    source = "${path.module}/scripts/mcm_import.sh"
    destination = "/var/lib/registry/mcm_scripts/mcm_import.sh"
  }
  
  provisioner "file" {
    source = "${path.module}/scripts/mcm_cleanup.sh"
    destination = "/var/lib/registry/mcm_scripts/mcm_cleanup.sh"
  }      

  provisioner "remote-exec" {
    inline = [    
      "chmod 755 /var/lib/registry/mcm_scripts/mcm_import_prereq.sh",
      "echo /var/lib/registry/mcm_scripts/mcm_import_prereq.sh -c ${var.cluster_name} -p ${var.icp_management_port} -h ${var.cluster_server_host}",
      "bash -c '/var/lib/registry/mcm_scripts/mcm_import_prereq.sh -c ${var.cluster_name} -p ${var.icp_management_port} -h ${var.cluster_server_host} -kc ${var.cluster_config} -kk  ${var.cluster_certificate_authority}'",

      "chmod 755 /var/lib/registry/mcm_scripts/mcm_import.sh",
      "echo /var/lib/registry/mcm_scripts/mcm_import.sh -rh ${var.cluster_docker_registry_server_name} -rp ${var.cluster_docker_registry_server_port} -ri ${var.cluster_docker_registry_server_ip} -cm ${var.cluster_name} -pa ${var.icp_dir} -hs ${var.mcm_controller_server_name} -ht ${var.mcm_controller_management_port} -hu ${var.mcm_controller_admin_user} -mch ${var.man_cluster_on_hub} -u ${var.admin_user} -v ${var.icp_inception_image} -kc ${var.cluster_config} -kk ${var.cluster_certificate_authority}",
      "bash -c '/var/lib/registry/mcm_scripts/mcm_import.sh -ri ${var.cluster_docker_registry_server_ip} -rca ${var.cluster_docker_registry_server_ca_crt} -rh ${var.cluster_docker_registry_server_name} -rp ${var.cluster_docker_registry_server_port} -cm ${var.cluster_name} -pa ${var.icp_dir} -hs ${var.mcm_controller_server_name} -ht ${var.mcm_controller_management_port} -hp ${var.mcm_controller_admin_user_password} -hu ${var.mcm_controller_admin_user} -mch ${var.man_cluster_on_hub} -u ${var.admin_user} -pw ${var.admin_user_password} -v ${var.icp_inception_image} -kc ${var.cluster_config} -kk ${var.cluster_certificate_authority}'"
      
      #"echo /var/lib/registry/mcm_scripts/mcm_import.sh -rh ${var.cluster_docker_registry_server_name} -rp ${var.cluster_docker_registry_server_port} -ri ${var.cluster_docker_registry_server_ip} -cm ${var.cluster_name} -pa ${var.icp_dir} -hs ${var.mcm_controller_server_name} -ht ${var.mcm_controller_management_port} -hu ${var.mcm_controller_admin_user} -mch ${var.man_cluster_on_hub} -u ${var.admin_user} -v ${var.icp_inception_image} -mcc ${var.managed_cluster_cloud} -mcv ${var.managed_cluster_kube_vendor} -mce ${var.managed_cluster_environment} -mcr ${var.managed_cluster_region} -mcd ${var.managed_cluster_datacenter} -mco ${var.managed_cluster_owner} -kc ${var.cluster_config} -kk ${var.cluster_certificate_authority}",
      #"bash -c '/var/lib/registry/mcm_scripts/mcm_import.sh -ri ${var.cluster_docker_registry_server_ip} -rca ${var.cluster_docker_registry_server_ca_crt} -rh ${var.cluster_docker_registry_server_name} -rp ${var.cluster_docker_registry_server_port} -cm ${var.cluster_name} -pa ${var.icp_dir} -hs ${var.mcm_controller_server_name} -ht ${var.mcm_controller_management_port} -hp ${var.mcm_controller_admin_user_password} -hu ${var.mcm_controller_admin_user} -mch ${var.man_cluster_on_hub} -u ${var.admin_user} -pw ${var.admin_user_password} -v ${var.icp_inception_image} -mcc ${var.managed_cluster_cloud} -mcv ${var.managed_cluster_kube_vendor} -mce ${var.managed_cluster_environment} -mcr ${var.managed_cluster_region} -mcd ${var.managed_cluster_datacenter} -mco ${var.managed_cluster_owner} -kc ${var.cluster_config} -kk ${var.cluster_certificate_authority}'"
    ]
  }
  
  provisioner "remote-exec" {
    when = "destroy"
    inline = [  
      "chmod 755 /var/lib/registry/mcm_scripts/mcm_cleanup.sh",
      "echo /var/lib/registry/mcm_scripts/mcm_cleanup.sh -cm ${var.cluster_name} -hs ${var.mcm_controller_server_name} -ht ${var.mcm_controller_management_port} -hu ${var.mcm_controller_admin_user} -mch ${var.man_cluster_on_hub} -u ${var.admin_user}",
      "bash -c '/var/lib/registry/mcm_scripts/mcm_cleanup.sh -cm ${var.cluster_name} -hs ${var.mcm_controller_server_name} -ht ${var.mcm_controller_management_port} -hp ${var.mcm_controller_admin_user_password} -hu ${var.mcm_controller_admin_user} -mch ${var.man_cluster_on_hub} -u ${var.admin_user} -pw ${var.admin_user_password} -kc ${var.cluster_config} -kk ${var.cluster_certificate_authority}'"
    ]
  }
}

resource "camc_scriptpackage" "get_cluster_import_yaml" {
 	depends_on = ["null_resource.import_icp"]	
  	program = ["sudo", "cat", "/var/lib/registry/mcm_scripts/cluster-import.yaml", "|", "base64", "-w0"]
  	on_create = true
  	remote_host = "${var.import_launch_node_ip}"
  	remote_user = "${var.vm_os_user}"
  	remote_password = "${var.vm_os_password}"
  	remote_key = "${length(var.vm_os_private_key) > 0 ? base64decode(var.vm_os_private_key) : ""}"
    bastion_host        = "${var.bastion_host}"
    bastion_user        = "${var.bastion_user}"
    bastion_private_key = "${length(var.bastion_private_key) > 0 ? base64decode(var.bastion_private_key) : var.bastion_private_key}"
    bastion_port        = "${var.bastion_port}"
    bastion_password    = "${var.bastion_password}"            	
}

