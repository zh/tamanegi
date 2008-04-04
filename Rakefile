require 'fileutils'

namespace :ditz do
  desc "Generate ditz bugs html pages"
  task :html do
    if FileTest.exists?(File.join(File.dirname(__FILE__),"public","bugs"))
       FileUtils.rm_r(File.join(File.dirname(__FILE__),"public","bugs"))
    end
    system("ditz html")
    FileUtils.mv(File.join(File.dirname(__FILE__),"html"),
              File.join(File.dirname(__FILE__),"public","bugs"))
  end
end
