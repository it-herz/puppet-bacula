# Class: bacula::director::postgresql
#
# Deploys a postgres database server for hosting the Bacula director
# database.
#
# Sample Usage:
#
#   none
#
class bacula::director::postgresql(
  $db_name            = $bacula::director::db_name,
  $db_pw              = $bacula::director::db_pw,
  $db_user            = $bacula::director::db_user,
  $db_path            = $bacula::director::db_path,
) inherits bacula::params {

  require docker
  
  docker::run { "postgresql":
    ensure => present,
    image => "postgres:latest",
    pull_on_start => true,
    volumes => [ "${db_path}:/var/lib/postgresql/data" ],
    env => [
      "POSTGRES_PASSWORD=${db_pw}",
    ]
  }
}
