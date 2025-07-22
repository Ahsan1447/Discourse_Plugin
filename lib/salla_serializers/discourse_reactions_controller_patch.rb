# frozen_string_literal: true

module SallaSerializers
  module DiscourseReactionsControllerPatch
    def self.prepended(base)
      base.skip_before_action :ensure_logged_in, only: [:reactions_given]
    end

    private

    def secure_reaction_users!(reaction_users)
      # For anonymous users, return the reaction_users as-is (no filtering)
      # or apply minimal public filtering
      unless current_user
        return reaction_users
      end

      # Call the original security method for logged-in users
      super
    end

  end
end