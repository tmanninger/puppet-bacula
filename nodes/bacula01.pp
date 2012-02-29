node bacula01 {
  include role::server

  ssh::allowgroup  { "techops": }
  sudo::allowgroup { "techops": }

  ####
  # MySQL
  #
  $mysql_root_pw = 'y0PM46FbrF72'
  include mysql::server

  ####
  # Bacula
  #
  class { "bacula::director":
    db_user  => 'bacula',
    db_pw    => 'ijdhx8jsd2KJshd',
    password => 'lVLthzlHuSWVgmCDXQpWw8sUIeInjXmD7DS3XGA7CkHszfKWVtmimLt27D6yV4R',
    sd_pass  => 'Z86VoTNrZEmGZxJ8rK7RenUeHvyUVeWZJK7ZHnYDE9Vhery0M2fW7Q8ZesbcXHk',
  }

  bacula::director::pool {
    "PuppetLabsPool-Full":
      volret      => "2 months",
      maxvolbytes => '2000000000',
      maxvoljobs  => '10',
      maxvols     => "20",
      label       => "Full-";
    "PuppetLabsPool-Inc":
      volret      => "14 days",
      maxvolbytes => '4000000000',
      maxvoljobs  => '50',
      maxvols     => "10",
      label       => "Inc-";
  }

  bacula::jobdefs {
    "PuppetLabsOps":
      jobtype  => "Backup",
      sched    => "WeeklyCycle",
      messages => "Standard",
      priority => "10",
  }

  bacula::schedule {
    "WeeklyCycle":
      runs => [
        "Level=Full sun at 1:05",
        "Level=Incremental mon-sat at 1:05"
      ];
    "WeeklyCycleAfterBackup":
      runs => [ "Full sun-sat at 3:10" ]
  }

  ####
  # Duplicity
  #
  class { 'duplicity::params':
    droproot => "/bacula/duplicity",
  }

  include duplicity::ssh_server

  duplicity::drop { "git.puppetlabs.net":
    owner => "gitbackups"
  }

  ####
  # Gearman
  #
  apt::source {
    "wheezy.list":
      distribution => "wheezy",
  }

  apt::pin{ 'wheey_repo_pin':
    release  => 'testing',
    priority => '200',
    filename => 'testingforgearman',
    wildcard => true
  }

  class {
    "nagios::gearman":
      key           => hiera("gearman_key"),
      nagios_server => hiera("nagios_server")
  }

}

