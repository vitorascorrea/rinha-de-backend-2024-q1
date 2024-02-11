class Transaction < ApplicationRecord
  belongs_to :customer

  validates :amount, presence: true
  validates :kind, presence: true, inclusion: { in: %w[d c] }
  validates :description, presence: true
  validate :does_not_exceed_limit

  after_create :update_balance

  def does_not_exceed_limit
    return unless kind == "d"

    if customer.current_balance - amount < customer.balance_limit * -1
      errors.add(:amount, "exceeds the current balance")
    end
  end

  def update_balance
    if kind == "d"
      customer.current_balance -= amount
    else
      customer.current_balance += amount
    end

    customer.save
  end
end
