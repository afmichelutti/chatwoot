class SuperAdmin::SettingsController < SuperAdmin::ApplicationController
  def show; end

  # [NO-OP] Desabilitado na versão customizada
  def refresh
    redirect_to super_admin_settings_path
  end
end
