Rails.application.routes.draw do
  # RESTful routes for products (gives us CRUD actions)
  # GET /products          -> index
  # GET /products/new      -> new
  # POST /products         -> create
  # GET /products/:id      -> show
  # GET /products/:id/edit -> edit
  # PATCH /products/:id    -> update
  # DELETE /products/:id   -> destroy
  resources :products

  devise_for :users
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"

  # Limited routes for questions - only index and create actions
  # GET /questions     -> questions#index (view all questions)
  # POST /questions    -> questions#create (create new question)
  resources :questions, only: [:index, :create]

end
