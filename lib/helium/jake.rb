LIB = 'lib'

TEST_DIR   = File.join(PROJECT_DIR, 'test')
PUBLIC_DIR = File.join(TEST_DIR, 'public')

# If test/public exists, we generate files there. Otherwise
# we just put generated files in the test directory.
TARGET_DIR = File.directory?(PUBLIC_DIR) ? PUBLIC_DIR : TEST_DIR
LIB_DIR    = File.join(TARGET_DIR, LIB)

def list(array)
  (array || []).map { |s| s.inspect } * ', '
end

PACKAGES = ERB.new(<<-EOS, nil, '-')
JS.Packages(function() { with(this) {
<% files.each do |path, meta| %>
    file('./<%= LIB %><%= path %>')
        .provides(<%= list(meta[:provides]) %>)
        .requires(<%= list(meta[:requires]) %>)
        .uses(<%= list(meta[:uses]) %>);
<% end -%>
}});
EOS

files = {}

update = lambda do |build, package, build_type, path|
  files[path.sub(build.build_directory, '')] = package.meta if build_type == :min
end

jake_hook(:file_created, &update)
jake_hook(:file_not_changed, &update)

jake_hook :build_complete do |build|
  FileUtils.rm_rf(LIB_DIR) if File.exists?(LIB_DIR)
  
  files.each do |path, meta|
    target = File.join(LIB_DIR, path)
    FileUtils.mkdir_p(File.dirname(target))
    FileUtils.cp(File.join(build.build_directory, path), target)
  end
  
  packages = PACKAGES.result(binding)
  File.open(File.join(TARGET_DIR, 'packages.js'), 'w') { |f| f.write(packages) }
end

