require 'spec_helper'

describe 'bacula::director' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do

      case facts[:osfamily]
      when 'Debian'
        it {
          Puppet::Util::Log.level = :debug
          Puppet::Util::Log.newdestination(:console)
          should contain_class('bacula::director')
        }
      end

    end
  end
end
