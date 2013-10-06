Facter.add("mailmanversion") do
  setcode do
    Facter::Util::Resolution::exec("/usr/lib/mailman/bin/version | awk '{print $4}'")
  end
end
