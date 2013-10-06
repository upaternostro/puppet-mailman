Facter.add("apacheversion") do
  setcode do
    Facter::Util::Resolution::exec("httpd -v | awk '/Server version/ {split($3,a,\"/\"); print a[2]}'")
  end
end
