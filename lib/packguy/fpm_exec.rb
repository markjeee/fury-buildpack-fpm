class Packguy
  class FpmExec
    def self.fpm_exec_path
      ENV['FPM_EXEC_PATH'] || Packguy.config[:fpm_exec_path] || 'fpm'
    end
  end
end
