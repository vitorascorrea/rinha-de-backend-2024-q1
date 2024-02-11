class TransactionsController < ApplicationController
  def index
    render json: { message: Customer.all }
  end

  def create
    return render json: { message: "Invalid params" }, status: 422 unless valid_params?

    customer = Customer.find(params[:id])

    unless customer
      render json: { message: "Customer not found" }, status: 404
      return
    end

    payload = nil
    transaction = nil

    customer.with_lock do
      transaction = Transaction.new(
        customer: customer,
        amount: params[:valor],
        kind: params[:tipo],
        description: params[:descricao]
      )

      if transaction.save
        payload = {
          "limite" => customer.balance_limit,
          "saldo" => customer.current_balance,
        }
      end
    end

    if payload.present?
      render json: payload, status: 200
    else
      render json: transaction&.errors, status: 422
    end
  end

  def balance
    customer = Customer.find(params[:id])

    unless customer
      render json: { message: "Customer not found" }, status: 404
      return
    end

    payload = {
      "saldo" => {
        "total" => customer.current_balance,
        "limite" => customer.balance_limit,
        "data_extrato" => Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L%z")
      },
      "ultimas_transacoes" => Transaction
        .where(customer: customer)
        .last(10)
        .reverse
        .map do |t|
          {
            "valor": t.amount,
            "tipo": t.kind,
            "descricao": t.description,
            "realizada_em": t.created_at.strftime("%Y-%m-%dT%H:%M:%S.%L%z")
          }
        end
    }

    render json: payload, status: 200
  end

  private

  def valid_params?
    valor_is_valid = params[:valor].present? && params[:valor].is_a?(Integer)
    tipo_is_valid = params[:tipo].present? && ["c", "d"].include?(params[:tipo])
    descricao_is_valid = params[:descricao].present? &&
      params[:descricao].is_a?(String) &&
      params[:descricao].length <= 10

    valor_is_valid && tipo_is_valid && descricao_is_valid
  end
end