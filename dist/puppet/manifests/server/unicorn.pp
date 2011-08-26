class puppet::server::unicorn {

  include nginx::server
  nginx::vhost {
    "puppetmaster_unicorn":
      port     => 8140,
      template => "puppet/nginx-unicorn.vhost.conf.erb"
  }

  unicorn::app {
    "puppetmaster":
      approot    => "/etc/puppet",
      config     => "/etc/puppet/unicorn.conf",
      require    => File["/etc/puppet/unicorn.conf"],
      initscript => "puppet/unicorn_puppetmaster",
  }

  file {
    "/etc/puppet/unicorn.conf":
      owner  => root,
      group  => root,
      mode   => 644,
      source => "puppet:///modules/puppet/unicorn.conf";
  }

  file {
    "/etc/puppet/config.ru":
      owner  => root,
      group  => root,
      mode   => 644,
      source => "puppet:///modules/puppet/config.ru";
  }

}
