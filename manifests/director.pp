# Class: bacula::director
#
# This class installs and configures the Bacula Backup Director
#
# Parameters:
# * db_user: the database user
# * db_pw: the database user's password
# * db_name: the database name
# * password: password to connect to the director
#
# Sample Usage:
#
#   class { 'bacula::director':
#     storage => 'mystorage.example.com'
#   }
#
class bacula::director (
  $docker_dns          = $::ipaddress,
  $port                = '9101',
  $listen_address      = $::ipaddress,
  $db_user             = 'postgres',
  $db_pw               = 'postgres',
  $db_host             = $bacula::params::db_host,
  $db_port             = $bacula::params::db_port,
  $db_name             = $bacula::params::bacula_user,
  $db_type             = $bacula::params::db_type,
  $db_path             = $bacula::params::db_path,
  $storage_path        = $bacula::params::storage_path,
  $password            = 'secret',
  $max_concurrent_jobs = '20',
  $services            = $bacula::params::bacula_director_services,
  $homedir             = $bacula::params::homedir,
  $rundir              = $bacula::params::rundir,
  $conf_dir            = $bacula::params::conf_dir,
  $director            = $bacula::params::director, # fqdn, # director here is not params::director
  $director_address    = $bacula::params::director_address,
  $storage             = $bacula::params::storage,
  $group               = $bacula::params::bacula_group,
  $job_tag             = $bacula::params::job_tag,
) inherits bacula::params {

  include bacula::common
  include bacula::client
  include bacula::ssl
  include bacula::director::defaults
  include bacula::director::postgresql
  include bacula::virtual
  
  require docker

  docker::run { "bacula":
    ensure    => present,
    image     => "itherz/bacula",
    volumes   => [ "/etc/bacula:/etc/bacula", "${storage_path}:/bacula" ],
    ports => [ '9101:9101', '9103:9103' ],
    links => [ 'postgresql:postgresql' ],
    env => [
      "DB_HOST=$bacula::params::db_host",
      "DB_PORT=$bacula::params::db_port",
      "DB_USER=${db_user}",
      "DB_NAME=${db_name}",
      "DB_PASSWORD=${db_pw}",
      "SERVICE_9101_TAGS=director",
      "SERVICE_9103_TAGS=storage",
      "SERVICE_9101_NAME=bacula",
      "SERVICE_9103_NAME=bacula",
      "SERVICE_9101_CHECK_TCP=true",
      "SERVICE_9103_CHECK_TCP=true"
    ],
    dns => [ $docker_dns ],
    require   => Docker::Run[postgresql],
    subscribe => File[$bacula::ssl::ssl_files],
  }

  file { "${conf_dir}/conf.d":
    ensure => directory,
  }

  file { "${conf_dir}/bconsole.conf":
    owner   => 'root',
    group   => $group,
    mode    => '0640',
    content => template('bacula/bconsole.conf.erb');
  }

  concat::fragment { 'bacula-director-header':
    order   => '00',
    target  => "${conf_dir}/bacula-dir.conf",
    content => template('bacula/bacula-dir-header.erb')
  }

  concat::fragment { 'bacula-director-tail':
    order   => '99999',
    target  => "${conf_dir}/bacula-dir.conf",
    content => template('bacula/bacula-dir-tail.erb')
  }

  bacula::messages { 'Standard-dir':
    console => 'all, !skipped, !saved',
    append  => '"/var/log/bacula/log" = all, !skipped',
    catalog => 'all',
  }

  bacula::messages { 'Daemon':
    mname   => 'Daemon',
    console => 'all, !skipped, !saved',
    append  => '"/var/log/bacula/log" = all, !skipped',
  }

  Bacula::Director::Pool <<||>> { conf_dir => $conf_dir }
  Bacula::Director::Storage <<| tag == "bacula-${storage}" |>> { conf_dir => $conf_dir }
  Bacula::Director::Client <<| tag == "bacula-${director}" |>> { conf_dir => $conf_dir }

  if !empty($job_tag) {
    Bacula::Fileset <<| tag == $job_tag |>> { conf_dir => $conf_dir }
    Bacula::Director::Job <<| tag == $job_tag |>> { conf_dir => $conf_dir }
  } else {
    Bacula::Fileset <<||>> { conf_dir => $conf_dir }
    Bacula::Director::Job <<||>> { conf_dir => $conf_dir }
  }


  Concat::Fragment <<| tag == "bacula-${director}" |>>

  concat { "${conf_dir}/bacula-dir.conf": 
    notify => Docker::Run["bacula"]
  }

  $sub_confs = [
    "${conf_dir}/conf.d/schedule.conf",
    "${conf_dir}/conf.d/storage.conf",
    "${conf_dir}/conf.d/pools.conf",
    "${conf_dir}/conf.d/job.conf",
    "${conf_dir}/conf.d/jobdefs.conf",
    "${conf_dir}/conf.d/client.conf",
    "${conf_dir}/conf.d/fileset.conf",
  ]

  concat { $sub_confs: 
    notify => Docker::Run["bacula"]
  }

  bacula::fileset { 'Common':
    files => ['/etc'],
  }

#  bacula::job { 'RestoreFiles':
#    jobtype  => 'Restore',
#    fileset  => false,
#    jobdef   => false,
#    messages => 'Standard',
#  }
}
