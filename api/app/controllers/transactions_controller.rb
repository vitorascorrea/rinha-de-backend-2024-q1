class TransactionsController < ApplicationController
  around_action :wrap_in_transaction

  def create
    return head 422 unless valid_params?

    customer_data = get_customer_data(params[:id])

    return head 404 if customer_data.blank?

    customer_balance = customer_data[0]
    customer_balance_limit = customer_data[1]

    return head 422 if exceeds_balance_limit?(
      customer_balance,
      customer_balance_limit,
      params[:valor],
      params[:tipo]
    )

    new_customer_balance = params[:tipo] == "d" ?
      customer_balance - params[:valor] :
      customer_balance + params[:valor]

    create_transaction(params[:id], params[:valor], params[:tipo], params[:descricao])
    update_balance(params[:id], new_customer_balance) if new_customer_balance != customer_balance

    payload = {
      "limite" => customer_balance_limit,
      "saldo" => new_customer_balance,
    }

    return render json: payload, status: 200
  end

  def balance
    customer_data = get_customer_data(params[:id], with_lock: false)

    return head 404 if customer_data.blank?

    payload = {
      "saldo" => {
        "total" => customer_data[0],
        "limite" => customer_data[1],
        "data_extrato" => Time.now
      },
      "ultimas_transacoes" => get_latest_transactions(params[:id])
        .map do |t|
          {
            "valor": t[0],
            "tipo": t[1],
            "descricao": t[2],
            "realizada_em": t[3]
          }
        end
    }

    return render json: payload, status: 200
  end

  private

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      yield
    end
  end

  def valid_params?
    valor_is_valid = params[:valor].present? && params[:valor].is_a?(Integer)
    tipo_is_valid = params[:tipo].present? && ["c", "d"].include?(params[:tipo])
    descricao_is_valid = params[:descricao].present? &&
      params[:descricao].is_a?(String) &&
      params[:descricao].length <= 10

    valor_is_valid && tipo_is_valid && descricao_is_valid
  end

  def exceeds_balance_limit?(current_balance, balance_limit, amount, kind)
    return false unless kind == "d"

    current_balance - amount < balance_limit * -1
  end

  def get_customer_data(customer_id, with_lock: true)
    sql = <<~SQL
      SELECT current_balance, balance_limit
      FROM customers
      WHERE id = #{customer_id}
      #{with_lock ? "FOR UPDATE" : ""}
    SQL

    ActiveRecord::Base.connection.execute(sql)&.first
  end

  def get_latest_transactions(customer_id, limit = 10)
    sql = <<~SQL
      SELECT t.amount, t.kind, t.description, t.created_at
      FROM transactions AS t
      WHERE customer_id = #{customer_id}
      ORDER BY id DESC
      LIMIT #{limit}
    SQL

    ActiveRecord::Base.connection.execute(sql).to_a
  end

  def create_transaction(customer_id, amount, kind, description)
    # Have to sanitize the input to avoid SQL injection
    sql = <<~SQL
      INSERT INTO transactions (customer_id, amount, kind, description)
      VALUES (#{customer_id}, #{amount}, #{"'" + kind + "'"}, #{"'" + description + "'"})
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end

  def update_balance(customer_id, new_balance)
    sql = <<~SQL
      UPDATE customers
      SET current_balance = #{new_balance}
      WHERE id = #{customer_id}
    SQL

    ActiveRecord::Base.connection.execute(sql)
  end
end