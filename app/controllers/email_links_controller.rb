# frozen_string_literal: true

class EmailLinksController < ApplicationController
  skip_before_action :authenticate_user!
  def new
    redirect_to root_path if authenticate_user!
  end

  def create
    @email_link = EmailLink.generate(params[:email])

    if @email_link
      flash[:notice] = 'Email sent! Please, check your inbox.'
    else
      flash[:alert] = 'There was an error, please try again!'
    end
    redirect_to new_magic_link_path
  end

  def validate
    email_link = EmailLink.active.find_by(token: params[:token])

    if email_link.present? && email_link.user.approved?
      flash[:notice] = 'Signed in!'
      sign_in(email_link.user)
      email_link.utilized!
      redirect_to root_path
    else
      flash[:alert] = 'Invalid or expired token!'
      # should be a 401 for fail2ban etc.
      # need to make it so that this can't be bruteforced
      redirect_to new_magic_link_path
    end
  end
end
