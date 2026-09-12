# frozen_string_literal: true

class Member < ApplicationRecord
  has_many :check_ins, dependent: :destroy
  has_many :events, through: :check_ins
end
