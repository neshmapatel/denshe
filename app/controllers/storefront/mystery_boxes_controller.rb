module Storefront
  class MysteryBoxesController < BaseController
    before_action :load_answers, only: [ :details, :place ]

    def show
    end

    def create
      answers = normalized_answers
      if answers.nil?
        redirect_to mystery_box_path, alert: "Choose a box and answer the questions before continuing."
        return
      end

      session[:mystery_box] = answers
      redirect_to mystery_box_details_path
    end

    def details
      @checkout = Checkout.new
    end

    def place
      @checkout = Checkout.from_params(checkout_params)
      order = @checkout.place_mystery_box!(@box, @answers)
      if order
        session.delete(:mystery_box)
        session[:order_id] = order.id
        redirect_to checkout_payment_path
      else
        render :details, status: :unprocessable_entity
      end
    end

    private

    def load_answers
      @answers = session[:mystery_box]
      @box = MysteryBoxPreference.box_for(@answers.to_h["box"])
      return if @answers.present? && @box

      redirect_to mystery_box_path, alert: "Tell us about the box first."
    end

    def normalized_answers
      raw = params.require(:mystery_box).permit(:box, :recipient, :personality, :occasion, :note, pieces: [], finish: [])
      box = MysteryBoxPreference.box_for(raw[:box])
      recipient = raw[:recipient].to_s
      personality = raw[:personality].to_s
      occasion = raw[:occasion].to_s
      pieces = Array(raw[:pieces]).map(&:to_s) & MysteryBoxPreference::CATEGORY_CHOICES
      finishes = Array(raw[:finish]).map(&:to_s) & MysteryBoxPreference::FINISH_CHOICES
      return unless box
      return unless MysteryBoxPreference.recipient_types.key?(recipient)
      return unless MysteryBoxPreference.jewellery_personalities.key?(personality)
      return unless MysteryBoxPreference.occasions.key?(occasion)
      return if pieces.empty? || finishes.empty?

      {
        "box" => box[:key],
        "recipient" => recipient,
        "personality" => personality,
        "occasion" => occasion,
        "pieces" => pieces,
        "finish" => finishes,
        "note" => raw[:note].to_s.strip.first(2_000)
      }
    end

    def checkout_params
      params.require(:checkout).permit(
        :name, :phone, :email, :line1, :line2, :city, :state, :pin_code, :billing_same,
        :billing_line1, :billing_line2, :billing_city, :billing_state, :billing_pin_code
      )
    end
  end
end
