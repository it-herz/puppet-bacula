class graphite::install {

  include graphite::params

  #
  # Graphite Install

  Exec["download graphite"] -> Exec["extract graphite"] ~> Exec["install graphite"] ~> Exec["initialize db"]
  exec { "download graphite":
    command => "/usr/bin/wget -O $graphite::params::webapp_dl_loc $graphite::params::webapp_dl_url",
    cwd     => "/usr/local/src",
    creates => "/usr/local/src/$graphite::params::webapp_dl_loc";
  }

  exec { "extract graphite":
    command => "/bin/tar -xzf $graphite::params::webapp_dl_loc",
    cwd     => '/usr/local/src',
    creates => "/usr/local/src/graphite-web-${graphite::params::version}",
  }

  exec { "install graphite":
    command     => '/usr/bin/python setup.py install',
    cwd         => "/usr/local/src/graphite-web-${graphite::params::version}",
    refreshonly => true,
    require     => Package["python-django-tagging"],
  }

  exec { "initialize db":
    command     => '/usr/bin/python manage.py syncdb --noinput',
    cwd         => '/opt/graphite/webapp/graphite',
    environment => "PYTHONPATH=/opt/graphite/webapp",
    refreshonly => true,
    user        => $graphite::params::web_user,
    require     => Package["python-sqlite"],
  }

  #
  # Carbon Install

  Exec["download carbon"] -> Exec["extract carbon"] ~> Exec["install carbon"]
  exec { "download carbon":
    command => "/usr/bin/wget -O $graphite::params::carbon_dl_loc $graphite::params::carbon_dl_url",
    cwd     => "/usr/local/src",
    creates => "/usr/local/src/$graphite::params::carbon_dl_loc";
  }

  exec { "extract carbon":
    command => "/bin/tar -xzf $graphite::params::carbon_dl_loc",
    cwd     => '/usr/local/src',
    creates => "/usr/local/src/carbon-${graphite::params::version}",
  }

  exec { "install carbon":
    command     => '/usr/bin/python setup.py install',
    cwd         => "/usr/local/src/carbon-${graphite::params::version}",
    refreshonly => true,
    require     => Package["python-twisted"],
  }

  #
  # Whisper install

  Exec["download whisper"] -> Exec["extract whisper"] ~> Exec["install whisper"]
  exec { "download whisper":
    command => "/usr/bin/wget -O $graphite::params::whisper_dl_loc $graphite::params::whisper_dl_url",
    cwd     => "/usr/local/src",
    creates => "/usr/local/src/$graphite::params::whisper_dl_loc";
  }

  exec { "extract whisper":
    command => "/bin/tar -xzf $graphite::params::whisper_dl_loc",
    cwd     => '/usr/local/src',
    creates => "/usr/local/src/whisper-${graphite::params::version}",
  }

  exec { "install whisper":
    command => '/usr/bin/python setup.py install',
    cwd     => "/usr/local/src/whisper-${graphite::params::version}",
    refreshonly => true;
  }

}