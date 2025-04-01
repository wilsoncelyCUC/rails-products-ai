class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # This establishes a one-to-many relationship with questions
  # Allows us to:
  # - user.questions returns all questions by this user
  # - user.questions.create(attributes) to create a new question
  # - When user is deleted, their questions can be automatically deleted too (with dependent: :destroy)
  has_many :questions
end
