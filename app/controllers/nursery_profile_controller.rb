class NurseryProfileController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:profile, :update_profile]
  before_action :set_nursery, only: [:profile, :update_profile]

  def satisfy_order
    plant_id = params[:plant_id]
    user_email = params[:email]

    reservations = Reservation.where(nursery_plant_id: plant_id, user_email: user_email)

    if reservations.any?
      num_reservations_to_remove = reservations.count

      nursery_plant = NurseryPlant.find_by(id: plant_id)
      if nursery_plant
        nursery_plant.decrement!(:num_reservations, num_reservations_to_remove)
      end

      reservations.destroy_all

      render json: { success: true }
    else
      render json: { success: false, message: 'Prenotazioni non trovate' }
    end
  end

  def profile
    load_nursery_data
  end

  def update_profile
    if params[:nursery_user]
      if profile_update_valid?
        if @user.otp_required_for_login
          # Genera OTP e invia via email
          otp_code = @user.generate_otp
          UserMailer.otp_email(@user, otp_code, 'profilo').deliver_now
  
          # Memorizza i parametri dell'utente nella sessione
          session[:pending_user_params] = user_params.to_h
          session[:otp_user_id] = @user.id
          session[:otp_for] = 'profilo'
          
          redirect_to login_verify_otp_path and return
        else
          @user.update(user_params)
          flash[:notice] = "Profilo aggiornato con successo!"
          redirect_to nursery_profile_path and return
        end
      else
        load_nursery_data
        flash.now[:alert] = "Errore nell'aggiornamento del profilo. Verifica i dati inseriti."
        render :profile and return
      end
    end
  
    if params[:nursery] && valid_address_updpro?
      if nursery_update_valid?
        @nursery.update(nursery_params)
        flash[:notice] ||= "Profilo aggiornato con successo."
        redirect_to nursery_profile_path and return
      else
        load_nursery_data
        flash.now[:alert] = "Errore nell'aggiornamento del vivaio. Verifica i dati inseriti."
        render :profile and return
      end
    end
  
    flash.now[:alert2] = @user.errors.full_messages.join(', ')
    render :profile unless performed?
  end

  def verify_otp
    @user = User.find_by(id: session[:otp_user_id])
    Rails.logger.debug "User trovato: #{@user.inspect}"
    
    unless @user
      flash[:alert] = "Utente non trovato. Per favore, riprova."
      redirect_to new_user_registration_path and return
    end
    
    if request.post?
      otp_attempt = params[:otp_attempt].strip
      Rails.logger.debug "OTP Attempt: #{otp_attempt}"
    
      if @user.verify_otp(otp_attempt)
        Rails.logger.debug "OTP Verified Successfully"
        if session[:pending_user_params]
          Rails.logger.debug "Parametri utente pendenti: #{session[:pending_user_params]}"
          @user.update(session[:pending_user_params])
          clear_temporary_session_data
          flash[:notice] = "Profilo aggiornato con successo!"
          redirect_to user_profile_path
        else
          clear_temporary_session_data
          flash[:alert] = "Nessuna modifica da applicare."
          redirect_to user_profile_path
        end
      else
        Rails.logger.debug "OTP Verification Failed"
        flash.now[:alert] = "Codice OTP non valido o scaduto. Richiedine un altro per provare ad accedere."
        render :verify_otp
      end
    elsif request.get?
      if params[:resend_otp] == "true"
        Rails.logger.debug "Resending OTP"
        @user.invalidate_otp
        otp_code = @user.generate_otp
        UserMailer.otp_email(@user, otp_code, 'profilo').deliver_now
        flash[:notice] = "Un nuovo codice OTP è stato inviato."
      end
      render :verify_otp
    end
  end
  
  

  def valid_address_updpro?
    results = geo(params[:nursery][:address])
    if results.present? && results.first.coordinates.present?
      true
    else
      @user.errors.add(:address, 'indirizzo errato!')
      false
    end
  end

  def geo(address)
    Geocoder.search(address)
  end

  private

  def load_nursery_data
    return unless current_user

    nursery_ids = Nursery.where(id_owner: current_user.id).pluck(:id)
    nursery_plant_ids = NurseryPlant.where(nursery_id: nursery_ids).pluck(:id)

    @myplants = Plant.joins(:nursery_plants)
                     .where(nursery_plants: { id: nursery_plant_ids })
                     .select('plants.id, plants.name, nursery_plants.id as nursery_plant_id, nursery_plants.max_disponibility as disp, nursery_plants.num_reservations as res,
                              typology, light, size, irrigation, use, climate, description')

    @reservations = Reservation.joins(:nursery_plant)
                               .where(nursery_plants: { id: nursery_plant_ids })
                               .pluck(:user_email, :nursery_plant_id)
                               .group_by { |email, id| id }
  end

  def set_user
    @user = current_user
  end

  def set_nursery
    @nursery = Nursery.find_by(id_owner: current_user.id) if current_user
  end

  def nursery_params
    params.require(:nursery).permit(:name, :address, :number, :email, :open_time, :close_time, :description)
  end

  def user_params
    params.require(:nursery_user).permit(:password, :password_confirmation, :current_password)
  end

  def profile_update_valid?
    return true unless params[:nursery_user]

    if params[:nursery_user][:password].blank? && params[:nursery_user][:password_confirmation].blank?
      if params[:nursery_user][:current_password].present?
        unless @user.authenticate(params[:nursery_user][:current_password])
          @user.errors.add(:current_password, 'Password errata!')
          return false
        end
      end
      return true
    end

    if params[:nursery_user][:current_password].blank?
      @user.errors.add(:current_password, 'La password attuale è richiesta.')
      return false
    end

    unless @user.authenticate(params[:nursery_user][:current_password])
      @user.errors.add(:current_password, 'Password errata!')
      return false
    end

    if params[:nursery_user][:password] == params[:nursery_user][:current_password]
      @user.errors.add(:password, 'La nuova password non può essere uguale alla precedente')
      return false
    end

    unless valid_password?(params[:nursery_user][:password])
      @user.errors.add(:password, 'La nuova password non rispetta i requisiti:
      - almeno una maiuscola;
      - almeno una minuscola;
      - almeno un numero;
      - almeno un carattere speciale.')
      return false
    end

    unless params[:nursery_user][:password] == params[:nursery_user][:password_confirmation]
      @user.errors.add(:password_confirmation, 'La password confermata deve essere uguale a quella nuova precedentemente inserita')
      return false
    end

    true
  end

  def nursery_update_valid?
    number = params[:nursery][:number].to_s.strip
    unless number.length == 10 && number.match?(/\A\d{10}\z/)
      @nursery.errors.add(:number, 'Il numero di telefono deve essere composto esattamente da 10 cifre.')
      return false
    end

    if @nursery.open_time >= @nursery.close_time
      @nursery.errors.add(:base, 'La fascia oraria inserita non è valida.')
      return false
    end

    if @nursery.description.blank?
      @nursery.errors.add(:description, 'La descrizione non può essere vuota.')
      return false
    end

    true
  end

  def valid_password?(password)
    password.length >= 8 && password.match(/[A-Z]/) && password.match(/[a-z]/) && password.match(/[0-9]/) && password.match(/[\W_]/)
  end

  def clear_temporary_session_data
    session.delete(:pending_user_params)
    session.delete(:otp_user_id)
    session.delete(:otp_for)
  end
  
end
