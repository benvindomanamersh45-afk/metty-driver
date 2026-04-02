# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

def flutter_install_all_ios_pods(flutter_dir)
  pod 'Flutter', :path => File.join(flutter_dir, 'Flutter')
end