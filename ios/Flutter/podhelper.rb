# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

def flutter_install_all_ios_pods(flutter_dir)
  # Install Flutter.framework
  pod 'Flutter', :path => File.join(flutter_dir, 'Flutter')

  # Install plugins
  plugin_pods = parse_KV_file(File.join(flutter_dir, 'Flutter', 'plugin_registrant'))
  plugin_pods.each do |name, path|
    pod name, :path => path
  end
end

def parse_KV_file(file)
  unless File.exist?(file)
    return []
  end

  pods = []
  File.open(file, 'r') do |f|
    f.each_line do |line|
      next if line.start_with?('#')
      key, value = line.strip.split('=', 2)
      if key && value
        pods << [key.strip, value.strip]
      end
    end
  end
  return pods
end
