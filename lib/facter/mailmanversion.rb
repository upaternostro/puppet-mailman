Facter.add("mailmanversion") do
  setcode do
    Facter::Util::Resolution::exec("/usr/lib/mailman/bin/version | /bin/awk '{print $4}'")
  end
end
