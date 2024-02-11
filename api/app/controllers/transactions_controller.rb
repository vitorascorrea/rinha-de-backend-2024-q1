class TransactionsController < ApplicationController
  def index
    render json: { message: Customer.all }
  end

  def create
    transaction = Transaction.new(transaction_params)
    if transaction.save
      render json: transaction, status: :created
    else
      render json: transaction.errors, status: :unprocessable_entity
    end
  end

  private

  def transaction_params
    params.require(:transaction).permit(:valor, :tipo, :descricao)
  end
end