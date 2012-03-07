# A facter fact to determine the root home directory.
# This varies on PE supported platforms and may be
# reconfigured by the end user.

module Facter::Util::RootHome
  class << self
  def get_root_home
    # This doesn't work on Darwin...
    if Facter.value('operatingsystem') == 'Darwin'
      root_ent = Facter::Util::Resolution.exec("dscl . -read /Users/root NFSHomeDirectory")
      root_ent.split(":")[1].strip
    else
      root_ent = Facter::Util::Resolution.exec("getent passwd root")
      # The home directory is the sixth element in the passwd entry
      root_ent.split(":")[5]
    end
  end
  end
end

Facter.add(:root_home) do
  setcode { Facter::Util::RootHome.get_root_home }
end