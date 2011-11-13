# Ensures that a gpg-agent instance is running for a specific user
#
# == Parameters
#
#
# == Examples
#
# gpg::agent { "git":
#   ensure => present,
# }
#
define gpg::agent ($ensure='present', $outfile = 'UNSET', $options = []) {


  $gpg_agent_info = $outfile ? {
    'UNSET' => "--write-env-file /home/${name}/.gpg-agent-info",
    undef   => "",
    default => "--write-env-file $outfile",
  }

  $command = inline_template("gpg-agent --allow-preset-passphrase --write-env-file ${gpg_agent_info} --daemon <%= options.join(' ') %>")

  case $ensure { 
    present: {
      exec { $command:
        user    => $name,
        path    => "/usr/bin:/bin:/usr/sbin:/sbin",
        unless  => "ps -U ${name} -o args | grep -v grep | grep gpg-agent",
      }
    }
    absent: {
      exec { "kill gpg-agent":
        user    => $name,
        path    => "/usr/bin:/bin:/usr/sbin:/sbin",
        command => "ps -U ${name} -o pid,args | grep -v grep | grep gpg-agent | awk '{print $1}' | xargs kill",
        onlyif  => "ps -U ${name} -o args | grep -v grep | grep gpg-agent",
      }
    }
    default: {
      fail("Undefined ensure parameter \"${ensure}\" for gpg::agent")
    }
  }
}