# This module is currently non-operational
# Definition: cobbler::node_multi_int
#
# This class installs a node into the cobbler system.  Cobbler needs to be included
# in a toplevel node definition for this to be useful.
#
# Parameters:
# - $mgt_mac Mac address of the eth0 interface
# - $profile Cobbler profile to assign
# - $mgt_ip IP address to assign to eth0
# - $domain Domain name to add to the resource name
# - $static = "1", 1 means the interface is static as apposed to manual or DHCP
# - $preseed Cobbler/Ubuntu preseed/kickstart file for the node
# - $power_address = "" Power management address for the node
# - $power_type = "" 		Power management type (impitools, ucs, etc.)
# - $power_user = ""    Power management username
# - $power_password = ""  Power management password
# - $power_id = ""     Power management port-id/name
# - $boot_disk = '/dev/sda'  Default Root disk name
# - $add_hosts_entry = true, Create a cobbler local hosts entry (also useful for DNS)
# - $extra_host_aliases = [] Any additional aliases to add to the host entry
#
# Example:
#cobbler::node_multi_int { "my_node_name_here":
# mgt_mac => "A4:4D:15:13:41:DB",
# profile => "precise-x86_64-auto",
# mgt_ip => "10.10.10.10",
# pub_ip => "1.1.1.1",
# pub_int => "eth1",
# pub_subnet => "255.255.255.0",
# domain => "mydomain.com",
# preseed => "/etc/cobbler/preseeds/your-preseed",
# power_address => "192.168.10.10",
# power_type => "ipmitool",
# power_user => "your_admin_name",
# power_password => "your_admin_password",
# }
#
define cobbler::node_multi_int(
	$pub_ip,
	$pub_int = "eth1",
	$pub_subnet = "255.255.255.0",
	$mgt_mac,
        $pub_mac,
 	$mgt_int = "eth0",
	$profile,
	$mgt_ip,
	$static = "1",
	$domain,
	$preseed,
	$power_address = "",
	$power_type = "",
	$power_user = "",
	$power_password = "",
	$power_id = "",
	$boot_disk = '/dev/sda',
	$add_hosts_entry = true,
	$log_host = '',
	$extra_host_aliases = [])
{
	exec { "cobbler-add-node-${name}":
		command => "if cobbler system list | grep ${name};
                    then
                        action=edit;
                        extra_opts='';
                    else
                        action=add;
                        extra_opts=--netboot-enabled=true;
                    fi;
		    extra_kargs='';
		    if [ ! -z \"${log_host}\" ] ; then extra_kargs='log_host=${log_host} BOOT_DEBUG=2' ; fi ;
                    cobbler system \\\${action} --name='${name}' --interface='${mgt_int}'  --mac-address='${mgt_mac}' --profile='${profile}' --ip-address='${mgt_ip}' --dns-name='${name}.${domain}' --hostname='${name}.${domain}' --kickstart='${preseed}' --kopts='netcfg/disable_autoconfig=true netcfg/dhcp_failed=true netcfg/dhcp_options=\"'\"'\"'Configure network manually'\"'\"'\" netcfg/get_nameservers=${cobbler::node_dns} netcfg/get_ipaddress=${mgt_ip} netcfg/get_netmask=${cobbler::node_netmask} netcfg/get_gateway=${cobbler::node_gateway} netcfg/confirm_static=true partman-auto/disk=${boot_disk} '\"\\\${extra_kargs}\" --power-user=${power_user} --power-address=${power_address} --power-pass=${power_password} --power-id=${power_id} --power-type=${power_type} \\\${extra_opts}",
		provider => shell,
		path => "/usr/bin:/bin",
		require => Package[cobbler],
		notify => Exec["cobbler-sync"],
		before => Exec["restart-cobbler"]
	}

        exec { "cobbler-add-pub-int-${name}":
                command => "if cobbler system list | grep ${name};
                    then
                        action=edit;
                        extra_opts='';
                    else
                        action=add;
                        extra_opts=--netboot-enabled=true;
                    fi;
                    extra_kargs='';
                    if [ ! -z \"${log_host}\" ] ; then extra_kargs='log_host=${log_host} BOOT_DEBUG=2' ; fi ;
                    cobbler system \\\${action} --name='${name}' --interface='${pub_int}' --static='${static}' --ip-address='${pub_ip}' --subnet='${pub_subnet}'",
                provider => shell,
                path => '/usr/bin:/bin',
                require => Package[cobbler],
                notify => Exec['cobbler-sync'],
                before => Exec['restart-cobbler']
        }
      
    if ( $add_hosts_entry ) {
        host { "${name}.${domain}":
            ip => "${mgt_ip}",
            host_aliases => flatten(["${name}", $extra_host_aliases])
        }
    }
}
