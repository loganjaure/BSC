# frozen_string_literal: true

class Event < ApplicationRecord
  has_many :check_ins, dependent: :destroy
  has_many :members, through: :check_ins
end
