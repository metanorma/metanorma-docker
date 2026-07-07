# frozen_string_literal: true

# Guard: fail the Windows image build if any gem pulls in the `openssl` gem.
#
# The openssl gem's native extension links the wrong C runtime for RubyInstaller's
# UCRT Ruby and breaks every HTTPS request with Errno::ENOTSOCK. Ruby's built-in
# openssl works, so the gem must stay out of the dependency tree. If a dependency
# reintroduces a runtime `openssl` dependency, fail here naming the culprit instead
# of shipping an image that dies at runtime.
# See https://github.com/metanorma/metanorma-docker/pull/236

LOCKFILE = "Gemfile.lock"

abort "openssl-guard: #{LOCKFILE} not found — run after `bundle install`." unless File.exist?(LOCKFILE)

current_gem = nil
culprits = []

File.foreach(LOCKFILE) do |line|
  if (m = line.match(/^    ([a-z0-9_.\-]+) \(/))   # a gem spec header in the GEM section
    current_gem = m[1]
  elsif line.match?(/^      openssl[ (]/)          # ...whose dependency list includes openssl
    culprits << current_gem
  end
end

culprits = culprits.compact.uniq - ["openssl"]

unless culprits.empty?
  warn "openssl-guard: FATAL — the `openssl` gem is pulled into the image by: #{culprits.join(", ")}."
  warn "openssl-guard: it breaks Windows HTTPS with Errno::ENOTSOCK on RubyInstaller Ruby."
  warn "openssl-guard: remove the runtime `openssl` dependency from that gem and release a new version."
  warn "openssl-guard: see https://github.com/metanorma/metanorma-docker/pull/236"
  exit 1
end

puts "openssl-guard: OK — no gem depends on the openssl gem."
