Rails.application.routes.draw do
  root "transactions#index"
  post "/clientes/:id/transacoes", to: "transactions#create"
  get "/clientes/:id/extrato", to: "transactions#balance"
end
