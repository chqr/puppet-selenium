# == Class: selendroid
#
# A class obtain an installation of selendroid and register it as a service.
#
# === Parameters
#
# [*java_home*] the location of the java jdk to use
# [*android_home*] the location of the android sdk
# [*keystore*] the location of a keystore to use for selendroid. See
#   [Launching Selendroid](http://selendroid.io/setup.html#launchingSelendroid)
# [*service_name*] the service name selendroid should run as
# [*service_ensure*] the ensure value of the selendroid service
# [*service_enable*] if the selendroid service should be enabled
# [*user*] the user selendroid should run as
# [*group*] the group selendroid should run as
# [*manage_user*] if the selendroid user should be managed
# [*manage_group*] if the selendroid group should be managed
# [*nexus*] The nexus server to obtain selendroid from
# [*repo*] the nexus repository to obtain the selendroid server from
# [*version*] the version of selendroid to deploy. Defaults to LATEST
# [*reverse_tether*] If reverse tethering should be enabled by default
# [*reverse_tether_netmask*] The default netmask to be used when reverse 
#   tethering
# [*reverse_tether_dns_server*] The default dns server to be used when
#   reverse tethering
# [*reverse_tether_dns_backup*] The default backup dns server to be used when
#   reverse tethering
#
# === Authors
#
# Christopher Johnson - cjohn@ceh.ac.uk
#
class selendroid (
  $java_home,
  $android_home,
  $keystore                  = '/home/selendroid/debug.keystore',
  $service_name              = 'selendroid',
  $service_ensure            = true,
  $service_enable            = true,
  $user                      = 'selendroid',
  $group                     = 'selendroid',
  $manage_user               = true,
  $manage_group              = true,
  $nexus                     = undef,
  $repo                      = undef,
  $version                   = undef,
  $reverse_tether            = true,
  $reverse_tether_netmask    = '255.255.255.0',
  $reverse_tether_dns_server = '8.8.8.8',
  $reverse_tether_dns_backup = '8.8.4.4'
) {
  include nexus

  $adb_location = "${android_home}/platform-tools/adb"
  $wrapper_script = '/opt/selendroid/startup.sh'
  $installed_path = '/opt/selendroid/selendroid-server.jar'
  $udev_device_rules_location = '/etc/udev/rules.d/51-selendroid.rules'
  $udev_reverse_tether_rules_location = '/etc/udev/rules.d/81-selendroid.rules'

  if $manage_user {
    user { $user :
      ensure     => present,
      gid        => $group,
      managehome => true,
    }
  }

  if $manage_group {
    group { $group :
      ensure => present,
    }
  }

  file { '/opt/selendroid' :
    ensure => directory,
    owner  => $user,
    group  => $group,
  }

  nexus::artifact { $installed_path :
    nexus      => $nexus,
    group      => 'io.selendroid',
    artifact   => 'selendroid-standalone',
    extension  => 'jar',
    classifier => 'with-dependencies',
    version    => $version,
    repo       => $repo,
  }

  file { $wrapper_script :
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('selendroid/startup.erb'),
    notify  => Service[$service_name],
  }

  file { "/etc/init.d/${service_name}" :
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('selendroid/init-selendroid.erb'),
    notify  => Service[$service_name],
  }

  service { $service_name :
    ensure  => $service_ensure,
    enable  => $service_enable,
    require => User[$user],
  }

  concat { $udev_device_rules_location :
    owner => root,
    group => root,
    mode  => '0644',
  }

  concat { $udev_reverse_tether_rules_location :
    owner => root,
    group => root,
    mode  => '0644',
  }
}