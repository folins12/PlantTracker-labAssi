class NurseryPlantsController < ApplicationController
  protect_from_forgery with: :null_session

  def add_to_nursery
    nursery = Nursery.find_by(id_owner: current_user.id)

    if nursery.nil?
      render json: { success: false, message: "Nessun vivaio trovato per l'utente corrente." }, status: :unprocessable_entity
      return
    end

    existing_nursery_plant = NurseryPlant.find_by(nursery_id: nursery.id, plant_id: params[:plant_id])
    if existing_nursery_plant
      render json: { success: false, message: "La pianta è già presente nel vivaio." }, status: :unprocessable_entity
      return
    end

    nursery_plant = NurseryPlant.new(
      nursery_id: nursery.id,
      plant_id: params[:plant_id],
      max_disponibility: 1,
      num_reservations: 0
    )

    if nursery_plant.save
      render json: { success: true }
    else
      render json: { success: false, message: "Errore nel salvataggio della pianta nel vivaio.", errors: nursery_plant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def incdisp
    puts "...........................................................";
    nursery_plant = NurseryPlant.find_by(nursery_id: params[:nursery_id], plant_id: params[:plant_id])
    if nursery_plant
      nursery_plant.increment!(:max_disponibility)
      render json: { success: true }
    end
  end

  def decdisp
    nursery_plant = NurseryPlant.find_by(nursery_id: params[:nursery_id], plant_id: params[:plant_id])
    if nursery_plant
      if nursery_plant.max_disponibility - nursery_plant.num_reservations > 0
        nursery_plant.decrement!(:max_disponibility)
        render json: { success: true }
      else
        render json: { success: false }
      end
    end
  end

  def removenursplant
    plant = NurseryPlant.find_by(plant_id: params[:plant_id], nursery_id: params[:nursery_id])
    if plant
      if plant.num_reservations<=0
        if plant.destroy
          render json: { success: true }
        end
      else
        render json: {success: false, message: "Ci sono degli ordini in sospeso"}
      end
    else
      render json: { success: false, message: "Errore nell'eliminazione della pianta.", errors: myplant ? myplant.errors.full_messages : ["Pianta non trovata"] }, status: :unprocessable_entity
    end
  end
end
