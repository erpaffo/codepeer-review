class SessionsController < Devise::SessionsController
  before_action :authenticate_user!, except: [:new, :create]

  def create
    # Verifica manuale del reCAPTCHA
    if verify_recaptcha
      # Se il CAPTCHA è valido, prosegui con l'autenticazione
      super
    else
      # Se il CAPTCHA non è valido, mostra un messaggio di errore
      flash[:alert] = 'CAPTCHA non valido. Riprova.'
      redirect_to new_user_session_path
    end
  end

  def index
    @sessions = current_user.user_sessions
  end

  def destroy
    @session = current_user.user_sessions.find(params[:id])
    @session.destroy
    redirect_to sessions_path, notice: 'Session terminated successfully.'
  end
end
