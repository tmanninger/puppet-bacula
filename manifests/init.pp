# Class: bacula
#
# This class installs and configures the Bacula Backup tool
#
# Parameters:
#
#
# Actions:
#   Installs the bacula-common package
#
# Requires:
#
# Sample Usage:
#
class bacula (
    $port           = '9102',
    $file_retention = "45 days",
    $job_retention  = "6 months",
    $autoprune      = "yes",
    $monitor        = true,
    $director,
    $password
  ){

  include bacula::params
  if $monitor == true { include bacula::nagios }


  $bacula_director = $director
  $bacula_password = $password

  package { 'bacula-common':
    ensure => present,
  }

  package { $bacula::params::bacula_client_packages:
    ensure => present,
  }

  service { $bacula::params::bacula_client_services:
    ensure  => running,
    enable  => true,
    require => Package[$bacula::params::bacula_client_packages],
  }

  file { '/etc/bacula/bacula-fd.conf':
    require => Package[$bacula::params::bacula_client_packages],
    content => template('bacula/bacula-fd.conf.erb'),
    notify  => Service[$bacula::params::bacula_client_services],
  }

  file { '/var/lib/bacula':
    ensure  => directory,
    require => Package[$bacula::params::bacula_client_packages],
  }

# using seperate configuration for client and job now
# zeslie:  @@concat::fragment {
# zeslie:    "bacula-client-$hostname":
# zeslie:      target  => '/etc/bacula/bacula-dir.conf',
# zeslie:      content => template("bacula/bacula-dir-client.erb"),
# zeslie:      tag     => "bacula-$director";
# zeslie:  }

  @@concat::fragment {
    "bacula-client-$hostname":
      target  => '/etc/bacula/conf.d/client.conf',
      content => template("bacula/client.conf.erb"),
      tag     => "bacula-$director";
  }

  @@concat::fragment {
    "bacula-job-$hostname":
      target  => '/etc/bacula/conf.d/job.conf',
      content => template("bacula/job.conf.erb"),
      tag     => "bacula-$director";
  }


  # realize the firewall rules exported from the director
  if defined (Class["firewall"]) {
    firewall {
      '0175-INPUT allow tcp 9102':
        proto  => 'tcp',
        dport  => '9102',
        source => "$director",
        jump   => 'ACCEPT',
    }
  }

}
